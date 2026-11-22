#!/usr/bin/env python3
# 第 04 集数据准备：合成一幅 DEM GeoTIFF（约 20MB，Float32，EPSG:4326，含 overviews）
# 依赖：python3 + GDAL（pip install gdal 或系统包）；没装的话见文件末尾 Docker 替代方案。
# 用法：python3 data/make-dem-ep04.py
# 想要真实地形：地理空间数据云（gscloud.cn，国内源，免费注册）下载 ASTER GDEM 30m，
# 用 QGIS 或 gdal_translate 裁剪一幅北京周边即可，发布流程完全一样。
import os
import shutil

import numpy as np
from osgeo import gdal, osr

gdal.UseExceptions()

HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, "generated", "ep04")
GS_DATA = os.path.join(HERE, "..", "docker", "geoserver_data", "ep04")
os.makedirs(DEST, exist_ok=True)
os.makedirs(GS_DATA, exist_ok=True)

WIDTH, HEIGHT = 2400, 2000
MINX, MINY, MAXX, MAXY = 115.5, 39.5, 117.5, 41.5  # 北京周边范围

xx, yy = np.meshgrid(np.linspace(0, 1, WIDTH), np.linspace(0, 1, HEIGHT))
dem = (
    800
    + 600 * np.sin(xx * 9) * np.cos(yy * 7)
    + 300 * np.sin(xx * 23 + 1.7) * np.sin(yy * 19)
    + 150 * np.cos(yy * 41)
)
# 沿纬度方向切一条"河谷"，伪彩色渲染时层次更明显
dem -= 400 * np.exp(-((yy - 0.45) ** 2) / 0.004)
rng = np.random.default_rng(42)
dem += rng.normal(0, 25, (HEIGHT, WIDTH))
# 西北角一块 NoData，演示 nodata 处理
dem[0:150, 0:180] = -9999
dem = np.clip(dem, -9999, 2200).astype("float32")

out = os.path.join(DEST, "dem_beijing.tif")
driver = gdal.GetDriverByName("GTiff")
ds = driver.Create(
    out, WIDTH, HEIGHT, 1, gdal.GDT_Float32,
    options=["TILED=YES", "COMPRESS=DEFLATE", "BIGTIFF=IF_SAFER"],
)
ds.SetGeoTransform([MINX, (MAXX - MINX) / WIDTH, 0, MAXY, 0, -(MAXY - MINY) / HEIGHT])
srs = osr.SpatialReference()
srs.ImportFromEPSG(4326)
ds.SetProjection(srs.ExportToWkt())
band = ds.GetRasterBand(1)
band.SetNoDataValue(-9999)
band.SetDescription("elevation")
band.WriteArray(dem)
# overviews（金字塔）：预览/小比例尺出图速度的关键，缺了就是踩坑点之一
ds.BuildOverviews("AVERAGE", [2, 4, 8, 16])
ds = None

shutil.copy(out, os.path.join(GS_DATA, "dem_beijing.tif"))
print(f"完成：{out}（已同步拷贝到 {GS_DATA}）")
print("GeoServer 内建 CoverageStore 时相对路径：file:ep04/dem_beijing.tif")

# 没装 GDAL 的替代方案（osgeo/gdal 在 Docker Hub 上，可走国内镜像站）：
#   docker pull docker.1ms.run/osgeo/gdal:alpine-normal-latest
#   docker run --rm -v "$PWD/data:/d" docker.1ms.run/osgeo/gdal:alpine-normal-latest \
#     sh -c 'apk add --no-cache py3-numpy && pip install --break-system-packages numpy 2>/dev/null; \
#            python3 /d/make-dem-ep04.py'
# （容器内路径与宿主机不同，脚本里 HERE 取的是 /d，产物会落在 data/generated/ep04/）
