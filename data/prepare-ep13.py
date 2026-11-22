#!/usr/bin/env python3
# 第 13 集数据准备：流式生成百万级点位 CSV（纯标准库，--count 可调）
# 用法：python3 data/prepare-ep13.py --count 1000000
# 产物：data/generated/ep13/trackpoints.csv（列: id,lng,lat,cat,ts）
import argparse, csv, os, random

CATS = ["出租车", "公交", "骑行", "步行"]
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=1_000_000)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()
    random.seed(args.seed)
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "generated", "ep13")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "trackpoints.csv")
    rng = random.Random(args.seed)
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["id", "lng", "lat", "cat", "ts"])
        wlng = 0.0
        wlat = 0.0
        for i in range(args.count):
            wlng += rng.random() * 0.0004
            wlat += rng.random() * 0.0003
            lng = 116.2 + (wlng % 0.4)
            lat = 39.7 + (wlat % 0.3)
            cat = CATS[rng.randrange(len(CATS))]
            day = rng.randrange(1, 366)
            hh = rng.randrange(0, 24)
            mi = rng.randrange(0, 60)
            ts = "2025-%02d-%02d %02d:%02d:00" % (((day // 30) % 12) + 1, day % 30 + 1, hh, mi)
            w.writerow([i, f"{lng:.6f}", f"{lat:.6f}", cat, ts])
    size = os.path.getsize(out)
    print("OK", out, size, "bytes,", args.count, "rows")

if __name__ == "__main__":
    main()
