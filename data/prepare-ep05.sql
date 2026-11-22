-- 第 05 集数据准备：合成路网表 + GiST 索引 + 参数化视图
-- 运行方式（在仓库根目录）：
--   docker compose -f docker/docker-compose.cn.yml exec -T postgis psql -U gis -d gis < data/prepare-ep05.sql
--   （官方版 compose 去掉 -f 参数；-T 关闭伪终端才能走 stdin 重定向）
-- 真实路网数据导入（ogr2ogr）见教案 episodes/ep05-postgis.md

BEGIN;

DROP VIEW IF EXISTS roads_gaosu;
DROP TABLE IF EXISTS roads;

CREATE TABLE roads (
    id       bigserial PRIMARY KEY,
    geom     geometry(LineString, 4326) NOT NULL,
    name     text   NOT NULL,
    kind     text   NOT NULL,              -- 高速/主干道/次干道/支路
    adcode   char(6) NOT NULL,             -- 区县代码，参数化视图的过滤字段（110101~110116）
    length_m double precision              -- 米（geography 计算）
);

-- 网格路网：150x150 格网 + 随机抖动，约 4.5 万段；
-- 按 0.5 度分格生成 16 个"区县"，adcode 从 110101 连续编到 110116
INSERT INTO roads (geom, name, kind, adcode, length_m)
WITH pts AS (
    SELECT i, j,
           ST_SetSRID(ST_MakePoint(
               115.5 + (117.5 - 115.5) * i / 150.0 + (random() - 0.5) * 0.003,
               39.5  + (41.5  - 39.5)  * j / 150.0 + (random() - 0.5) * 0.003), 4326) AS p
    FROM generate_series(0, 150) AS i, generate_series(0, 150) AS j
),
seg AS (
    SELECT a.p AS p1, b.p AS p2                       -- 横向段
    FROM pts a JOIN pts b ON b.i = a.i + 1 AND b.j = a.j
    UNION ALL
    SELECT a.p AS p1, b.p AS p2                       -- 纵向段
    FROM pts a JOIN pts b ON b.i = a.i AND b.j = a.j + 1
)
SELECT
    ST_MakeLine(p1, p2),
    '网格路-' || row_number() OVER (),
    (ARRAY['高速', '主干道', '次干道', '支路'])[1 + (random() * 3)::int],
    ((110101
      + least(3, greatest(0, floor((ST_X(p1) - 115.5) / 0.5)::int)) * 4
      + least(3, greatest(0, floor((ST_Y(p1) - 39.5)  / 0.5)::int))
     )::text)::char(6),
    ST_Length(ST_MakeLine(p1, p2)::geography)
FROM seg;

-- GiST 空间索引：GeoServer 每次按 bbox 取数都靠它（演示"没索引多慢"见教案）
CREATE INDEX roads_geom_idx ON roads USING GIST (geom);
CREATE INDEX roads_adcode_idx ON roads (adcode);   -- 参数化视图过滤字段也加个普通索引
ANALYZE roads;

-- 普通视图：演示"数据库里已有的视图直接当表发布"（无参数，最简单的联动方式）
CREATE VIEW roads_gaosu AS
SELECT id, geom, name, kind, adcode, length_m
FROM roads
WHERE kind = '高速';

-- 参数化视图（GeoServer SQL View + viewparams）不在这里建：
-- 它是发布时填在 GeoServer 界面里的 SQL 文本，%adcode% 由 GeoServer 替换成前端传参。
-- 直接建进数据库的 "%adcode%" 视图只会字面匹配占位符、查出 0 行（见教案踩坑点）。
-- 发布用的 SQL 见 episodes/ep05-postgis.md 第 6 步。

COMMIT;

-- 验证（教案命令清单里也会跑）：
--   SELECT count(*) FROM roads;                         -- 约 45300
--   SELECT DISTINCT adcode FROM roads ORDER BY 1;       -- 110101 ~ 110116
--   SELECT count(*) FROM roads WHERE adcode = '110105'; -- 单区约 2800 段
--   SELECT count(*) FROM roads_gaosu;                   -- 高速视图非空
