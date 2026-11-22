"""代理路由：/ogc/<workspace>/<service>"""
from django.urls import re_path
from . import views

urlpatterns = [
    re_path(r"^ogc/(?P<ws>[^/]+)/(?P<svc>(?:wms|ows|wcs|wmts))$", views.ogc),
]
