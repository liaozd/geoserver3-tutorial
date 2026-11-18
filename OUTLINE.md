# GeoServer 3 教学视频大纲

> 主题：数据对接与使用 —— 前后端对接、配置、栅格数据、PostgreSQL、MongoDB、大数据场景。
> 形式：16 集系统课，每集 3-30 分钟弹性时长，每集一个可跑通的 demo；踩坑点可拆成 3 分钟短视频。

## 技术栈基线

| 组件 | 选型 | 说明 |
|---|---|---|
| GeoServer | 3.0.x（2026-06 发布） | 要求 JDK 17 + Tomcat 11；教学用 Docker 部署 |
| 矢量数据库 | PostgreSQL 16 + PostGIS 3 | 官方原生支持，主线数据源 |
| 文档数据库 | MongoDB 6+ | 官方 Extensions 提供 MongoDB Data Store |
| 分析数据库 | ClickHouse | 无 GeoServer 直连插件，走「聚合分析 + Django」架构模式 |
| 后端 | Django + requests | 代理 OGC 服务、REST API 自动化发布 |
| 前端 | OpenLayers / MapLibre GL / 高德地图 JS API | 三个库各一集；Mapbox GL v2+ 需 token，教学用免费分支 MapLibre |
| 辅助工具 | QGIS、ogr2ogr、mongoimport | 数据准备与样式导出 |

### GeoServer 3 与 2.x 的关键差异（录制前必读）

- JDK 17 起步，Tomcat 需 11.0；老教程的安装步骤不能照搬。
- H2 数据源已移除，示例数据演示改用 GeoPackage。
- 部分核心模块降级为扩展，装扩展时注意版本与 GeoServer 完全一致。
- 新增 DuckDB 数据源扩展（gs-duckdb），支持 Parquet/GeoParquet 直连。
- MongoDB 数据存储已进入官方 Extensions 文档（不再是纯社区模块）。

---

## 第一部分：基础（2 集）

### 01 • GeoServer 3 是什么 + Docker 安装（8-10 min）

- 知识点：GeoServer 在 WebGIS 架构中的位置（数据 → 服务 → 前端）；OGC 标准是什么。
- Demo：`docker compose up` 一键起 GeoServer 3 + PostGIS；登录管理界面；Layer Preview 看到第一张图。
- 坑点：JDK 17 / Tomcat 11 新要求；默认账号密码首次登录后要改。
- 产出：可复用的 `docker-compose.yml`（贯穿全课程）。

### 02 • 核心概念一张图（10 min）

- 知识点：Workspace / Store / Layer / LayerGroup / Style 五层结构；WMS（出图）、WFS（出数据）、WMTS（出瓦片）、WCS（出栅格值）四大服务分工。
- Demo：用官方示例数据逐层点开管理界面对应概念；同一个图层分别发 WMS/WFS 请求看返回差异。
- 产出：一张概念图（后续每集片头复用）。

---

## 第二部分：对接数据（5 集）

### 03 • 矢量文件发布：Shapefile / GeoJSON / GeoPackage（10 min）

- 知识点：三种格式特点与适用场景；文件型 Store 的目录管理；字符编码（中文属性乱码）。
- Demo：三种文件各发布一个图层并预览；演示 DBF 编码设置解决中文乱码。
- 坑点：Shapefile 中文编码；GeoJSON 发布默认 WGS84。

### 04 • 栅格入门：GeoTIFF + DEM 渲染 + WCS（12 min）

- 知识点：CoverageStore 与 Coverage；栅格 SLD（RasterSymbolizer 伪彩色、ChannelSelection）；WCS GetCoverage 取原始高程值。
- Demo：发布一幅 DEM GeoTIFF → 配伪彩色样式 → WCS 请求取某点高程。
- 坑点：坐标系声明（SRS）与数据实际 CRS 不一致；大文件未建 overviews 导致预览慢（为 14 集埋伏笔）。

### 05 • PostgreSQL/PostGIS 对接（15-20 min）

- 知识点：PostGIS 安装与空间字段；ogr2ogr / QGIS 导入 shp；GiST 空间索引；发布流程（计算边界）；SQL Views 参数化视图。
- Demo：导入一份路网数据 → 建索引 → 发布 → 创建带参数的 SQL View（如按区域代码过滤）→ 前端传参出图。
- 坑点：不建索引发布后查询慢；SQL View 必须声明几何列类型和 SRID；主键暴露（Expose primary keys）与 WFS-T 的关系。

### 06 • MongoDB 对接（12-15 min）

- 知识点：MongoDB Data Store 扩展安装；GeoJSON 几何存储格式；`2dsphere` 索引。
- Demo：mongoimport 导入 GeoJSON（去头尾只留 features 的处理）→ 建 2dsphere 索引 → 装扩展 → 新建 MongoDB Store → 发布出图。
- 坑点（本集核心卖点）：**不建 2dsphere 索引就找不到图层**；mongoimport 的 `--jsonArray` 与文件头尾处理；扩展版本必须与 GeoServer 一致。

### 07 • 样式：SLD 基础 + QGIS 工作流（12 min）

- 知识点：SLD 结构（Rule / Filter / Symbolizer）；按属性分级设色；QGIS 配样式导出 SLD；样式与图层绑定、默认样式。
- Demo：手写一个简单 SLD → 用 QGIS 做一份分级设色专题图导出 SLD 上传 → 对比效果。
- 坑点：QGIS 导出的 SLD 含厂商扩展，部分符号不兼容需手工清理；中文字体标注乱码。

---

## 第三部分：前端对接（3 集）

### 08 • OpenLayers 对接（15-20 min）

- 知识点：TileWMS / WMTS 图层加载；WFS 读 GeoJSON 矢量渲染；CQL_FILTER 动态过滤；GetFeatureInfo 点击查询。
- Demo：一个可交互网页地图——底图 + 业务图层、下拉框按属性过滤、点击弹窗显示属性。
- 坑点：CORS（为 11 集埋伏笔）；WFS 轴序（EPSG:4326 经纬度顺序）；GetFeatureInfo 的 info_format 选 application/json。

### 09 • MapLibre GL 对接（12-15 min）

- 知识点：Vector Tiles 扩展安装；MVT（application/vnd.mapbox-vector-tile）输出；MapLibre 加载 GeoServer 矢量切片 + 前端动态样式。
- Demo：同一份 PostGIS 数据发矢量切片 → MapLibre 渲染 → 前端运行时改颜色/过滤（对比 SLD 服务端渲染的差异）。
- 坑点：Mapbox GL v2+ 需 token，用 MapLibre 免费替代；切片网格集（gridset）与前端 zoom 对应关系。

### 10 • 高德地图叠加 + GCJ-02 坐标偏移（15 min）

- 知识点：高德 JS API 加载自定义 WMS/WMTS 图层；WGS84 vs GCJ-02（火星坐标）偏移原理；两种解法——前端坐标纠偏 / 数据侧预转换。
- Demo：高德底图上叠 GeoServer 业务图层，先展示「偏了」的翻车现场，再分别用两种方案修正。
- 坑点（国内观众刚需，差异化卖点）：偏移量随位置变化不是固定值；纠偏算法的适用边界；合规提示（公开地图底图用高德/天地图）。

---

## 第四部分：后端对接（2 集，Django）

### 11 • Django 代理 OGC 服务（15 min）

- 知识点：为什么需要后端代理（CORS、鉴权收敛、隐藏内网 GeoServer）；requests 转发 WMS/WFS；流式转发图片响应。
- Demo：Django 视图代理 GetMap / GetFeatureInfo / WFS GetFeature，前端改走 Django 接口，跨域问题消失。
- 坑点：转发时保留 query string 与 Content-Type；图片响应别用 JSON 包装；超时与错误透传。

### 12 • Django + REST API 自动化发布（20 min）

- 知识点：GeoServer REST API 结构（workspaces / datastores / featuretypes / coveragestores / styles）；程序化发布全流程。
- Demo：一个上传接口——接收 shp/GeoTIFF → REST 建 Workspace/Store → 发布图层 → 绑定样式 → 返回预览 URL，全程不碰管理界面。
- 坑点：REST 认证与 CSRF；上传路径与 GeoServer 容器内路径映射（挂载卷）；重复发布的幂等处理。

---

## 第五部分：大数据与生产化（4 集）

### 13 • 百万级矢量性能优化（20 min）

- 知识点：GiST 索引与 CLUSTER；分区表；预综合（Pregeneralized Features，按缩放级别预简化）；矢量切片 + GeoWebCache 缓存。
- Demo：百万级点位/路网数据，优化前后 WMS 出图耗时对比（秒表实测）；同一数据走矢量切片后前端流畅缩放。
- 坑点：预综合需要额外广义化表；缓存失效时机（数据更新后 truncate）。

### 14 • 海量栅格：ImageMosaic + COG + S3（20 min）

- 知识点：ImageMosaic 多幅拼接与时间维度；granule 索引存 PostGIS；COG（Cloud Optimized GeoTIFF）原理；S3 GeoTIFF 扩展直读对象存储。
- Demo：多幅影像建 ImageMosaic（按时间过滤）→ 转 COG → 放 MinIO/S3 直读发布，对比本地文件方案。
- 坑点：mosaic 索引表结构；COG 的 overviews 必须内置；S3 扩展的 endpoint/region 配置。

### 15 • 亿级点位：ClickHouse 聚合 + 地图可视化（25-30 min）

- 知识点：**GeoServer 没有 ClickHouse 直连插件（官方扩展与社区模块均无，已核实）**，正确姿势是架构分工——ClickHouse 做 OLAP 聚合（网格聚合/热力统计），Django 查询聚合结果生成 GeoJSON 给前端渲染，或写回 PostGIS 由 GeoServer 发布。
- Demo：亿级（或千万级模拟）点位入 ClickHouse → Django 接口按 bbox + 缩放级别做网格聚合 → OpenLayers 热力/格网渲染；对比「全量走 WFS」的翻车现场。
- 加餐：DuckDB / GeoParquet 数据源（GS3 新特性）作为轻量分析替代，一个 .duckdb 文件直接发布。
- 坑点：聚合粒度随 zoom 变化；ClickHouse 空间函数（H3/S2）选型；别试图让 GeoServer 直连 ClickHouse。

### 16 • 生产化：缓存、安全、运维（20 min）

- 知识点：GeoWebCache seeding 预生成与磁盘配额；用户/角色/图层级权限；CORS 全局配置；反向代理（Nginx）与 HTTPS；日志级别与排错。
- Demo：给课程环境加权限（只读用户 vs 管理员）→ seeding 预热 → Nginx 反代上线 → 演示一次日志排错。
- 坑点：反代后 GetCapabilities 里的 URL 要配 Proxy Base URL；权限规则顺序；seeding 并发打爆数据库。

---

## 短视频拆条选题（3 分钟单条）

1. GeoServer 3 必须 JDK 17？老教程为什么跑不起来
2. MongoDB 发布图层找不到？一个索引的事
3. 高德底图上叠自己的数据为什么偏了 500 米
4. 前端跨域报错？Django 代理 30 行解决
5. 百万点位地图卡成 PPT？三个优化手段
6. 一个 .duckdb 文件直接发布地图服务（GS3 新特性）
7. QGIS 配好的样式一键搬进 GeoServer
8. 上传文件自动出地图：REST API 一条龙

## 数据准备清单（录制前统一备齐）

| 数据 | 用途 | 建议来源 |
|---|---|---|
| 行政区/路网 shp（含中文属性） | 03/05/08 集 | OpenStreetMap 提取或全国基础地理数据 |
| DEM GeoTIFF（一幅，~100MB） | 04 集 | SRTM / ASTER GDEM |
| 多幅带时间影像 | 14 集 | Sentinel-2 裁剪若干景 |
| GeoJSON 点位/面 | 06 集 | OSM 导出转 GeoJSON |
| 百万级点位 | 13 集 | OSM POI 或脚本生成 |
| 千万~亿级点位（带时间戳） | 15 集 | 脚本模拟出租车/信令轨迹 |
| QGIS 工程 | 07 集 | 基于上述路网做分级设色 |

## 录制顺序建议

按集号顺序即可，依赖链：01-02 环境 → 03-07 数据与服务 → 08-10 前端 → 11-12 后端 → 13-16 进阶。
其中 09 集依赖 13 集的矢量切片概念，可先录 13 的切片部分或在 09 里做 3 分钟前置铺垫。

## 仓库目录规划（随录制逐步填充）

```
geoserver3-tutorial/
├── OUTLINE.md              # 本大纲
├── docker/                 # docker-compose 与各服务配置（01 集产出）
├── data/                   # 演示数据（大文件走 LFS 或下载脚本）
├── styles/                 # SLD 文件（07 集产出）
├── backend/                # Django 工程（11-12、15 集产出）
├── frontend/
│   ├── openlayers/         # 08 集
│   ├── maplibre/           # 09 集
│   └── amap/               # 10 集
└── episodes/               # 每集脚本、命令清单、踩坑记录
```