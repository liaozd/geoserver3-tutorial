#!/usr/bin/env bash
# 第 06 集数据准备：生成 GeoJSON 样例 → 拆成 JSON Lines → mongoimport 进 compose 的 mongo 容器 → 建 2dsphere 索引
# 用法（仓库根目录执行）：
#   bash data/prepare-ep06.sh data    # 只生成 + 导入，故意不建索引——教案「找不到图层」翻车演示用
#   bash data/prepare-ep06.sh index   # 给 geometry 字段建 2dsphere 索引（建完 GeoServer 才能发现集合）
#   bash data/prepare-ep06.sh         # data + index 一步到位
# 依赖：python3（本机生成数据）+ compose 里的 mongo 容器已启动
# 官方版 compose：COMPOSE_FILE=docker/docker-compose.yml bash data/prepare-ep06.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
DEST="$HERE/generated/ep06"
mkdir -p "$DEST"
COMPOSE=(docker compose -f "${COMPOSE_FILE:-$ROOT/docker/docker-compose.cn.yml}")

do_data() {
  echo "== 生成样例数据（poi 点位 + wangge 网格面）=="
  python3 - "$DEST" <<'PY'
import json, os, random, sys

dest = sys.argv[1]
random.seed(42)

# poi：150 个北京样例点位（字段名 ASCII、值中文，与 ep03 同一约定）
CATS = ["餐饮", "医院", "学校", "商场", "地铁站"]
DISTRICTS = [("东城", "110101"), ("西城", "110102"), ("朝阳", "110105"), ("丰台", "110106"), ("海淀", "110108")]
poi = []
for i in range(150):
    dist, adcode = DISTRICTS[i % len(DISTRICTS)]
    cat = CATS[i % len(CATS)]
    poi.append({
        "type": "Feature",
        "properties": {
            "name": f"{dist}{cat}{i:03d}",
            "category": cat,
            "adcode": adcode,
            "visits": random.randint(50, 5000),
        },
        "geometry": {
            "type": "Point",
            "coordinates": [round(random.uniform(116.20, 116.60), 6),
                            round(random.uniform(39.70, 40.00), 6)],
        },
    })

# wangge：5x5 网格面，覆盖同一范围（演示 Polygon；pop 字段留给第 07 集分级设色）
MIN_LON, MAX_LON, MIN_LAT, MAX_LAT = 116.20, 116.60, 39.70, 40.00
wangge = []
for r in range(5):
    for c in range(5):
        x0 = round(MIN_LON + c * (MAX_LON - MIN_LON) / 5, 6)
        x1 = round(MIN_LON + (c + 1) * (MAX_LON - MIN_LON) / 5, 6)
        y0 = round(MIN_LAT + r * (MAX_LAT - MIN_LAT) / 5, 6)
        y1 = round(MIN_LAT + (r + 1) * (MAX_LAT - MIN_LAT) / 5, 6)
        ring = [[x0, y0], [x1, y0], [x1, y1], [x0, y1], [x0, y0]]
        wangge.append({
            "type": "Feature",
            "properties": {"cell_id": f"R{r + 1}C{c + 1}", "pop": random.randint(10, 200)},
            "geometry": {"type": "Polygon", "coordinates": [ring]},
        })

def write(name, feats):
    fc = {"type": "FeatureCollection", "name": name, "features": feats}
    with open(os.path.join(dest, name + ".geojson"), "w", encoding="utf-8") as f:
        json.dump(fc, f, ensure_ascii=False, indent=2)
    # 关键一步：去掉 FeatureCollection 外壳，一行一个 Feature（JSON Lines）。
    # mongoimport 按行导入为独立文档，文档必须有顶层 geometry 字段，
    # 否则建不了 2dsphere 索引，GeoServer 也会忽略整个集合。
    with open(os.path.join(dest, name + ".jsonl"), "w", encoding="utf-8") as f:
        for ft in feats:
            f.write(json.dumps(ft, ensure_ascii=False) + "\n")
    print(f"  {name}: {len(feats)} 个要素 → {name}.geojson / {name}.jsonl")

write("poi", poi)
write("wangge", wangge)
PY

  echo "== mongoimport 导入（--drop 幂等重跑；--file - 表示从 stdin 读 JSON Lines）=="
  for coll in poi wangge; do
    "${COMPOSE[@]}" exec -T mongo mongoimport --drop --db gis --collection "$coll" \
      --file - < "$DEST/$coll.jsonl"
  done
  "${COMPOSE[@]}" exec -T mongo mongosh gis --quiet --eval '
    for (const c of ["poi", "wangge"]) {
      print("  " + c + ": " + db[c].countDocuments({}) + " docs（索引: " +
        (db[c].getIndexes().map(i => i.name).join(", ") || "无") + "）");
    }'
}

do_index() {
  echo "== 建 2dsphere 索引（没有它 GeoServer 直接忽略集合，本集核心坑）=="
  "${COMPOSE[@]}" exec -T mongo mongosh gis --quiet --eval '
    for (const c of ["poi", "wangge"]) {
      db[c].createIndex({ geometry: "2dsphere" });
      print("  " + c + " 索引: " + db[c].getIndexes().map(i => i.name).join(", "));
    }'
}

case "${1:-all}" in
  data)  do_data ;;
  index) do_index ;;
  all)   do_data; do_index ;;
  *) echo "用法: bash data/prepare-ep06.sh [data|index]" >&2; exit 1 ;;
esac

echo "完成。后续步骤见 episodes/ep06-mongodb.md："
echo "  1) Store 列表出现 MongoDB 选项（扩展已装好）"
echo "  2) 新建 Store：data_store=mongodb://mongo:27017/gis"
echo "     schema_store=file:///opt/geoserver_data/mongodb_schema"
echo "     （kartoza 镜像改为 file:///opt/geoserver/data_dir/mongodb_schema）"
