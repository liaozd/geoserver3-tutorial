"""URL 总表：三个 app 各挂自己的前缀。"""
from django.urls import include, path

urlpatterns = [
    path("ogc/", include("proxy.urls")),
    path("publish/", include("publisher.urls")),
    path("analytics/", include("analytics.urls")),
]
