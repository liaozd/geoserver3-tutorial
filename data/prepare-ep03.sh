#!/usr/bin/env bash
# 第 03 集数据准备：生成含中文属性的矢量样例（GeoJSON / GeoPackage / 两种编码的 Shapefile）
# 依赖：GDAL（ogr2ogr）。没装的话见文末 Docker 替代方案。
# 用法：bash data/prepare-ep03.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HERE/generated/ep03"
GS_DATA="$(cd "$HERE/../docker" && pwd)/geoserver_data/ep03"
mkdir -p "$DEST" "$GS_DATA"

# 1. 源数据：北京市社区卫生服务站样例点位（字段名用 ASCII，中文放字段值，避免 DBF 头编码问题）
cat > "$DEST/shequ.geojson" <<'EOF'
{
  "type": "FeatureCollection",
  "name": "shequ",
  "features": [
    { "type": "Feature", "properties": { "name": "通州区社区卫生服务中心", "code": "110112001", "level": "甲级", "addr": "通州区新华大街 1 号" }, "geometry": { "type": "Point", "coordinates": [116.6586, 39.9024] } },
    { "type": "Feature", "properties": { "name": "朝阳区三里屯服务站", "code": "110105002", "level": "乙级", "addr": "朝阳区三里屯路 19 号" }, "geometry": { "type": "Point", "coordinates": [116.4540, 39.9370] } },
    { "type": "Feature", "properties": { "name": "海淀区中关村服务站", "code": "110108003", "level": "甲级", "addr": "海淀区中关村南大街 5 号" }, "geometry": { "type": "Point", "coordinates": [116.3200, 39.9580] } },
    { "type": "Feature", "properties": { "name": "西城区月坛服务站", "code": "110102004", "level": "丙级", "addr": "西城区月坛北街 3 号" }, "geometry": { "type": "Point", "coordinates": [116.3490, 39.9220] } },
    { "type": "Feature", "properties": { "name": "大兴区黄村服务站", "code": "110115005", "level": "乙级", "addr": "大兴区黄村西大街 8 号" }, "geometry": { "type": "Point", "coordinates": [116.3410, 39.7270] } }
  ]
}
EOF

# 2. GeoJSON → GeoPackage（GS3 推荐的文件格式，替代已移除的 H2）
ogr2ogr -f GPKG "$DEST/shequ.gpkg" "$DEST/shequ.geojson" -nln shequ

# 3. GeoJSON → Shapefile（UTF-8 编码版）
ogr2ogr -f "ESRI Shapefile" "$DEST/shequ_utf8.shp" "$DEST/shequ.geojson" -lco ENCODING=UTF-8

# 4. GeoJSON → Shapefile（GBK 编码版）
#    ogr2ogr 会同时生成 .cpg 边车文件（内容 "GBK"）——GeoServer 在 charset 留空时会自动读它
ogr2ogr -f "ESRI Shapefile" "$DEST/shequ_gbk.shp" "$DEST/shequ.geojson" -lco ENCODING=GBK

# 5. 再复制一份删掉 .cpg 的 GBK shp：模拟国内存量数据（通常没有 .cpg），
#    GeoServer 识别不出编码，中文必乱码——教案里的乱码翻车演示用的是这份
mkdir -p "$DEST/shequ_gbk_nocpg"
cp "$DEST"/shequ_gbk.* "$DEST/shequ_gbk_nocpg/"
rm -f "$DEST/shequ_gbk_nocpg/shequ_gbk.cpg"

# 6. 拷进 GeoServer 数据目录（数据目录已挂载到宿主机，拷进去容器即可见）
cp "$DEST"/shequ.gpkg "$DEST"/shequ_utf8.* "$DEST"/shequ_gbk.* "$GS_DATA"/
mkdir -p "$GS_DATA/shequ_gbk_nocpg"
cp "$DEST"/shequ_gbk_nocpg/* "$GS_DATA/shequ_gbk_nocpg/"

echo "完成："
echo "  样例数据: $DEST"
echo "  已拷入 GeoServer 数据目录: $GS_DATA"
echo "  GeoServer 内相对路径（建 Store 时用）:"
echo "    file:ep03/shequ_gbk.shp            （GBK + .cpg，charset 留空可自动识别）"
echo "    file:ep03/shequ_gbk_nocpg/shequ_gbk.shp （GBK 无 .cpg，乱码演示用）"

# 没装 GDAL 的替代方案（osgeo/gdal 在 Docker Hub 上，可走国内镜像站）：
#   docker pull docker.1ms.run/osgeo/gdal:alpine-normal-latest
#   docker run --rm -v "$PWD/data/generated/ep03:/d" docker.1ms.run/osgeo/gdal:alpine-normal-latest \
#     sh -c 'ogr2ogr -f GPKG /d/shequ.gpkg /d/shequ.geojson -nln shequ && \
#            ogr2ogr -f "ESRI Shapefile" /d/shequ_utf8.shp /d/shequ.geojson -lco ENCODING=UTF-8 && \
#            ogr2ogr -f "ESRI Shapefile" /d/shequ_gbk.shp /d/shequ.geojson -lco ENCODING=GBK && \
#            mkdir -p /d/shequ_gbk_nocpg && cp /d/shequ_gbk.* /d/shequ_gbk_nocpg/ && \
#            rm -f /d/shequ_gbk_nocpg/shequ_gbk.cpg'
