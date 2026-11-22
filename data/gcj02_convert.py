#!/usr/bin/env python3
# 第 10 集数据侧预转换：GeoJSON WGS84 -> GCJ-02
# 用法：python3 data/gcj02_convert.py in.geojson out_gcj.geojson
# 纯标准库；点/线/面及 Multi 变体逐点转换；高德底图配转换后数据则无需前端纠偏
import json, math, sys

PI = math.pi
A = 6378245.0
EE = 0.00669342162296594323

def out_of_china(lng, lat):
    return lng < 72.004 or lng > 137.8347 or lat < 0.8293 or lat > 55.8271

def trans_lat(x, y):
    r = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    r += (20.0*math.sin(6.0*x*PI) + 20.0*math.sin(2.0*x*PI)) * 2.0/3.0
    r += (20.0*math.sin(y*PI) + 40.0*math.sin(y/3.0*PI)) * 2.0/3.0
    r += (160.0*math.sin(y/12.0*PI) + 320.0*math.sin(y*PI/30.0)) * 2.0/3.0
    return r
def trans_lng(x, y):
    r = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    r += (20.0*math.sin(6.0*x*PI) + 20.0*math.sin(2.0*x*PI)) * 2.0/3.0
    r += (20.0*math.sin(x*PI) + 40.0*math.sin(x/3.0*PI)) * 2.0/3.0
    r += (150.0*math.sin(x/12.0*PI) + 300.0*math.sin(x/30.0*PI)) * 2.0/3.0
    return r

def wgs2gcj(lng, lat):
    if out_of_china(lng, lat):
        return (lng, lat)
    dlat = trans_lat(lng - 105.0, lat - 35.0)
    dlng = trans_lng(lng - 105.0, lat - 35.0)
    radlat = lat / 180.0 * PI
    magic = 1 - EE * math.sin(radlat) ** 2
    sqrtmagic = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((A * (1 - EE)) / (magic * sqrtmagic) * PI)
    dlng = (dlng * 180.0) / (A / sqrtmagic * math.cos(radlat) * PI)
    return (lng + dlng, lat + dlat)
def conv_coords(coords):
    if isinstance(coords[0], (int, float)):
        g = wgs2gcj(coords[0], coords[1])
        return [round(g[0], 6), round(g[1], 6)]
    return [conv_coords(c) for c in coords]

def convert(obj):
    if isinstance(obj, dict) and "type" in obj and obj["type"] == "FeatureCollection":
        obj["features"] = [convert(f) for f in obj["features"]]
        return obj
    geom = obj.get("geometry", obj)
    geom["coordinates"] = conv_coords(geom.get("coordinates"))
    return obj

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python3 data/gcj02_convert.py in.geojson out_gcj.geojson")
        sys.exit(1)
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
    out = convert(data)
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)
    print("OK ->", sys.argv[2])
