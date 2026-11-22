# geoserver3-tutorial

> GeoServer 3 教学课程的配套代码库：教学环境、演示数据脚本、SLD 样式、Django 后端与免构建前端 demo。配套课程将另行发布。

**English:** Companion code repository for a GeoServer 3 course — Docker teaching stack, demo-data scripts, SLD styles, a Django backend and no-build frontend demos.

## 仓库结构

| 目录 | 内容 |
|---|---|
| [docker/](docker/) | 教学环境：官方 / 国内源两套 compose、GeoServer 扩展离线下载脚本、Nginx 配置、中文字体目录 |
| [data/](data/) | 演示数据脚本：路网 / POI / DEM 合成、百万与千万级点位生成、ImageMosaic 配置模板、GCJ-02 坐标转换 |
| [styles/](styles/) | SLD 样式：DEM 伪彩色、山体阴影、POI 分类设色、网格人口分级设色 |
| [backend/](backend/) | Django 教学后端：OGC 代理（proxy）、REST 自动发布（publisher）、ClickHouse 聚合接口（analytics） |
| [frontend/](frontend/) | 免构建前端 demo（CDN 引入）：OpenLayers、MapLibre、高德叠加与 GCJ-02 纠偏 |

## 快速开始

前置：本机装 Docker（无需 Java，镜像内置 JDK 17 + Tomcat 11）。

cd docker
cp .env.example .env          # 设置 GeoServer 与 PostGIS 密码
docker compose up -d          # 国内网络可用同目录的 docker-compose.cn.yml

# 服务就绪后：
#   GeoServer 管理界面  http://localhost:8080/geoserver
#   PostGIS             127.0.0.1:5432（仅本机）
#   按需启用其他服务（--profile minio / clickhouse / prod），详见 compose 注释

## 组件用法

- **docker/**：官方镜像版与国内源版 compose 二选一；`download-extensions.sh` 支持断点续传预下载官方镜像扩展；`nginx/nginx.conf` 供反向代理场景使用
- **data/**：脚本均可用 `python3 脚本名 --help` 查看；DEM 合成需要本机 GDAL（gdal_translate）；生成物落在 `data/generated/`（已 gitignore）
- **styles/**：SLD 可经 GeoServer 管理界面 Styles 页上传，或走 REST API
- **backend/**：

  cd backend
  pip install -r requirements.txt
  set -a; source ../docker/.env; set +a
  python3 manage.py runserver 8000

  三个模块：`/ogc/<workspace>/<service>`（OGC 反向代理）、`/publish/publish/`（上传 shp.zip / GeoTIFF 自动发布）、`/analytics/grid/`（ClickHouse 网格聚合出 GeoJSON）
- **frontend/**：各目录 `python3 -m http.server` 起静态服务即可打开；高德 demo 需在 `index.html` 填入你自己的高德开放平台 key

## 说明

- `docker/geoserver_data/` 与 `data/generated/` 为运行时数据，已 gitignore，脚本可随时重建
- 中文字体（SLD 中文标注用）请自行下载放入 `docker/fonts/`，字体文件不入库
- 演示数据均为脚本合成，不含真实用户数据

## License

[Apache-2.0](LICENSE)
