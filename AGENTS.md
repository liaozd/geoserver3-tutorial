# AGENTS.md — geoserver3-tutorial

## 项目用途

这是一个 16 集 GeoServer 3 视频课程的教学资料仓库（面向中文观众；主题：数据集成——前后端对接、栅格数据、PostgreSQL/PostGIS、MongoDB、ClickHouse 级大数据、生产运维）。仓库目前处于**大纲阶段**：尚无代码；演示代码和数据将逐集添加。仓库**没有构建系统、包管理器或测试套件**——只有 markdown 规划文档和未来的自包含演示项目。不要凭空发明构建/lint/测试命令。

## 事实来源

- [OUTLINE.md](OUTLINE.md) 是课程内容的唯一事实来源：技术栈基线、16 集课程规划、短视频选题、数据准备清单、目标目录结构。**在任何内容或代码工作之前先阅读它。**
- 添加代码/演示时，遵循 OUTLINE.md 中的目录规划（仅在某一集产出时才创建对应目录）：

```
docker/                  # docker-compose + 服务配置（第 01 集，全课程复用）
data/                    # 演示数据——大文件通过 LFS 或下载脚本提供，不直接提交
styles/                  # SLD 样式文件（第 07 集）
backend/                 # Django 项目（第 11-12、15 集）
frontend/
  openlayers/            # 第 08 集
  maplibre/              # 第 09 集
  amap/                  # 第 10 集（高德）
episodes/                # 每集脚本、命令清单、踩坑点笔记
```

## 技术栈基线（固定；如需变更必须先更新 OUTLINE.md）

- GeoServer **3.0.x**，通过 Docker 部署；要求 **JDK 17 + Tomcat 11**。
- 矢量数据库：PostgreSQL 16 + PostGIS 3（主要数据源）。
- MongoDB 6+，通过官方 MongoDB Data Store 扩展。
- ClickHouse：**不存在 GeoServer 直连插件**——必须采用架构拆分：ClickHouse 聚合 → Django 查询 → GeoJSON 输出到前端，或回写 PostGIS 供 GeoServer 发布。
- 后端：Django + requests（OGC 代理、REST API 自动化发布）。
- 前端：OpenLayers / MapLibre GL / AMap（高德）JS API。使用 **MapLibre，绝不用 Mapbox GL v2+**（需要 token）。
- 数据工具：QGIS、ogr2ogr、mongoimport。

## GeoServer 3 与 2.x 的差异点（所有演示和脚本都必须体现）

- 最低要求 JDK 17 / Tomcat 11；2.x 时代的安装步骤不再适用。
- H2 datastore 已移除——演示/示例数据使用 **GeoPackage**。
- 多个 2.x 核心模块现在是扩展；扩展版本必须与 GeoServer 版本**完全一致**。
- `gs-duckdb` 扩展：可直接从 `.duckdb` 文件发布 Parquet/GeoParquet。
- MongoDB store 已收录进官方 Extensions（不再是社区插件）。

## OpenSpec 工作流

`openspec/` 使用 spec 驱动模式（`openspec/config.yaml`）。OpenSpec 技能（`openspec-propose`、`openspec-apply-change`、`openspec-verify-change`、`openspec-archive-change` 等）已安装在工作区本地的 `.zcode/skills/` 下（其他工具镜像在 `.devin/`、`.qoder/`）。非平凡的变更请使用 OpenSpec 工作流；这些技能目录已被 **gitignore**——已提交的文档中绝不要引用它们。

## 约定

- 撰写的内容（课程脚本、`episodes/` 笔记、演示注释/README）使用**中文**；术语与 OUTLINE.md 保持一致（如"踩坑点"）。
- `.gitignore` 排除了压缩包格式（`*.zip`、`*.tar.gz`、`*.jar` 等）以及 `.devin/`、`.zcode/`、`.qoder/`。演示数据必须通过下载脚本或 LFS 提供，绝不提交压缩包。
- 仅使用 `main` 分支；每次提交限定在单集/单功能范围内。
