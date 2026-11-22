"""第 15 集：ClickHouse 网格聚合转 GeoJSON（HTTP 接口 8123，无需专用驱动）。"""
import os

import requests
from django.http import JsonResponse

CK_HTTP = os.environ.get("CLICKHOUSE_HTTP", "http://localhost:8123")


def grid(request):
    """bbox + zoom 网格聚合。返回格网面 GeoJSON，属性带 count。"""
    minx = float(request.GET.get("minx", "116.2"))
    maxx = float(request.GET.get("maxx", "116.6"))
    miny = float(request.GET.get("miny", "39.7"))
    maxy = float(request.GET.get("maxy", "40.0"))
    zoom = int(request.GET.get("zoom", "10"))
    g = 360.0 / (2 ** zoom * 16)
    q = (
        "SELECT floor(lng / {g}) * {g} AS x, floor(lat / {g}) * {g} AS y, count() AS c "
        "FROM trackpoints "
        "WHERE lng BETWEEN {minx} AND {maxx} AND lat BETWEEN {miny} AND {maxy} "
        "GROUP BY x, y ORDER BY c DESC FORMAT JSON"
    ).format(g=g, minx=minx, maxx=maxx, miny=miny, maxy=maxy)
    r = requests.get(CK_HTTP + "/", params={"query": q}, timeout=30)
    rows = r.json().get("data", [])
    feats = []
    for row in rows:
        x, y, c = row["x"], row["y"], row["c"]
        feats.append({
            "type": "Feature",
            "properties": {"count": c},
            "geometry": {"type": "Polygon", "coordinates": [[
                [x, y], [x + g, y], [x + g, y + g], [x, y + g], [x, y],
            ]]},
        })
    return JsonResponse({"type": "FeatureCollection", "features": feats})
