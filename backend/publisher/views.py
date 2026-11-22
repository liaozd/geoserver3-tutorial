"""第 12 集：REST 自动化发布——上传即发布，全程不碰管理界面。"""
import re
import shutil
import zipfile
import requests
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt


def _gs(path):
    return settings.GS_URL + "/rest" + path


def _auth():
    return (settings.GS_USER, settings.GS_PASSWORD)


def _ensure_workspace(ws):
    # 幂等：GET 404 才 POST（重复发布不报错，本集坑点之一）
    r = requests.get(_gs(f"/workspaces/{ws}.json"), auth=_auth(), timeout=15)
    if r.status_code == 404:
        requests.post(_gs("/workspaces.json"),
                      json={"workspace": {"name": ws}}, auth=_auth(), timeout=15)


@csrf_exempt
def publish(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST multipart: file, ws, layer, srs, style"}, status=400)
    f = request.FILES.get("file")
    if f is None:
        return JsonResponse({"error": "file is required"}, status=400)
    ws = request.POST.get("ws", "ep12")
    layer = request.POST.get("layer") or re.sub(r"\.\w+$", "", f.name)
    layer = re.sub(r"\W+", "_", layer)
    srs = request.POST.get("srs", "EPSG:4326")
    style = request.POST.get("style") or None

    dest = settings.UPLOAD_DIR / layer
    dest.mkdir(parents=True, exist_ok=True)
    ext = f.name.lower()

    tif = ext.endswith(".tif") or ext.endswith(".tiff")
    with open(dest / f.name, "wb") as out:
        for chunk in f.chunks():
            out.write(chunk)
    if ext.endswith(".zip"):
        with zipfile.ZipFile(dest / f.name) as z:
            z.extractall(dest)
    _ensure_workspace(ws)
    shp = dest / (layer + ".shp")
    if tif:
        # 外部 GeoTIFF：coveragestore 指向容器内相对路径（挂载卷映射，本集坑点）
        requests.post(_gs(f"/workspaces/{ws}/coveragestores"),
                      json={"coverageStore": {"name": layer, "type": "GeoTIFF", "enabled": True}},
                      auth=_auth(), timeout=15)
        requests.put(_gs(f"/workspaces/{ws}/coveragestores/{layer}/coverages"),
                     json={"coverage": {"name": layer, "title": layer,
                          "enabled": True, "srs": srs}},
                     auth=_auth(), timeout=30)
    elif shp.exists():
        # 外部 shapefile：datastore 的 url 参数指向容器内相对路径
        requests.post(_gs(f"/workspaces/{ws}/datastores"),
                      json={"dataStore": {"name": layer, "connectionParameters": {
                            "entry": [{"@key": "url", "$": "file:" + settings.GS_DATA_PREFIX + "/" + layer + "/" + layer + ".shp"}]}}},
                      auth=_auth(), timeout=15)
        requests.post(_gs(f"/workspaces/{ws}/datastores/{layer}/featuretypes.json"),
                      json={"featureType": {"name": layer, "nativeName": layer,
                            "srs": srs}}, auth=_auth(), timeout=30)
    else:
        return JsonResponse({"error": "need .zip(shapefile) or .tif"}, status=400)

    if style:
        # 绑样式：PUT layers/<ws>:<layer> 改 defaultStyle（第 07 集 REST 上传过的样式名）
        requests.put(_gs(f"/layers/{ws}:{layer}.json"),
                     json={"layer": {"defaultStyle": {"name": style, "workspace": ws}}},
                     auth=_auth(), timeout=15)
    preview = f"{settings.GS_URL}/{ws}/wms?service=WMS&version=1.1.0&request=GetMap&layers={ws}:{layer}&bbox=116,39.7,117,40.1&width=600&height=450&srs=EPSG:4326&format=image/png"
    return JsonResponse({"ok": True, "layer": ws + ":" + layer, "preview": preview})
