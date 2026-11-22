#!/usr/bin/env python3
# 第 14 集数据准备：合成 4 幅带时间戳的影像 granule，原始 GeoTIFF 与 COG 各一份
# 用法：python3 data/prepare-ep14.py
# 依赖：gdal_translate（本机 GDAL）
# 产物：
#   data/generated/ep14/original/dem_<时间戳>.tif   原始无 overviews（对比组）
#   data/generated/ep14/cog/dem_<时间戳>.tif        COG 含内建 overviews（实验组）
#   docker/geoserver_data/ep14/mosaic/dem_<时间戳>.tif  mosaic 粒度（COG 拷贝）
import os, random, shutil, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
GEN = os.path.join(HERE, "generated", "ep14")
GS = os.path.join(HERE, "..", "docker", "geoserver_data", "ep14", "mosaic")
QUARTERS = ["20250301T000000Z", "20250601T000000Z", "20250901T000000Z", "20251201T000000Z"]

def build_ascii(path, seed, quarter_index):
    rng = random.Random(seed)
    W, H = 400, 320
    lines = ["NCOLS 400", "NROWS 320", "XLLCORNER 115.5", "YLLCORNER 39.5",
             "CELLSIZE 0.0025", "NODATA_value -9999"]
    for r in range(H):
        vals = []
        for c in range(W):
            vals.append(str(100 + rng.randrange(900) + quarter_index * 50))
        lines.append(" ".join(vals))
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

def main():
    for d in (GEN, os.path.join(GEN, "original"), os.path.join(GEN, "cog"), GS):
        os.makedirs(d, exist_ok=True)
    for i, q in enumerate(QUARTERS):
        asc = os.path.join(GEN, "dem_%s.asc" % q)
        build_ascii(asc, seed=1000 + i, quarter_index=i)
        raw = os.path.join(GEN, "original", "dem_%s.tif" % q)
        cog = os.path.join(GEN, "cog", "dem_%s.tif" % q)
        subprocess.run(["gdal_translate", "-q", "-of", "GTiff", "-co", "COMPRESS=DEFLATE", asc, raw], check=True)
        subprocess.run(["gdal_translate", "-q", "-of", "COG", "-co", "COMPRESS=DEFLATE", asc, cog], check=True)
        os.remove(asc)
        shutil.copy2(cog, os.path.join(GS, "dem_%s.tif" % q))
        print("granule", q, "ok")
    print("done ->", GEN)

if __name__ == "__main__":
    main()
