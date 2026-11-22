"""第 11/12/15 集教学后端：Django + requests，无 DRF、无数据库。"""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "teaching-only")
DEBUG = os.environ.get("DJANGO_DEBUG", "0") == "1"
ALLOWED_HOSTS = ["*"]
INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "proxy",
    "publisher",
    "analytics",
]
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
]
ROOT_URLCONF = "tutorial_backend.urls"
WSGI_APPLICATION = "tutorial_backend.wsgi.application"
# 教学后端不落库；第 15 集数据在 ClickHouse
DATABASES = {}
USE_TZ = True

# GeoServer 连接：运行前 set -a; source docker/.env; set +a
GS_URL = os.environ.get("GS_URL", "http://localhost:8080/geoserver")
GS_USER = os.environ.get("GEOSERVER_ADMIN_USER", "admin")
GS_PASSWORD = os.environ.get("GEOSERVER_ADMIN_PASSWORD", "")
# 第 12 集：上传落盘（宿主机路径），容器内以相对数据目录路径引用
UPLOAD_DIR = BASE_DIR.parent / "docker" / "geoserver_data" / "ep12_uploads"
GS_DATA_PREFIX = "ep12_uploads"
