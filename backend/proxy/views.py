"""第 11 集：OGC 代理——前端同源请求，CORS 与内网暴露一起消失。"""
import requests
from django.conf import settings
from django.http import StreamingHttpResponse
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
def ogc(request, ws, svc):
    # 原样转发 query string；别用 request.GET.urlencode()，会二次编码破坏 CQL 中文 [预判]
    qs = request.META.get("QUERY_STRING", "")
    url = f"{settings.GS_URL}/{ws}/{svc}?{qs}"
    upstream = requests.get(url, auth=(settings.GS_USER, settings.GS_PASSWORD),
                            stream=True, timeout=30)
    resp = StreamingHttpResponse(upstream.iter_content(chunk_size=8192),
                                 status=upstream.status_code)
    # Content-Type 原样透传：图片就是 image/*，千万别用 JSON 包装（本集坑点）
    resp["Content-Type"] = upstream.headers.get("Content-Type", "application/octet-stream")
    return resp
