# 第 08 集 OpenLayers demo

WMS 瓦片 + CQL 服务端过滤 + GetFeatureInfo 点击查询 + WFS GeoJSON 渲染。

## 运行

cd frontend/openlayers
python3 -m http.server 8001
# 打开 http://localhost:8001/
# 前置：GeoServer 8080 已启动，ep05:roads 与 ep06:poi 已发布（第 05/06 集）

## 演示点

- 下拉框按类别过滤：CQL_FILTER 服务端过滤（网络面板看 WMS 请求参数）
- 点击道路要素：左下角弹窗显示属性（GetFeatureInfo, INFO_FORMAT=application/json）
- WFS 渲染 50 个 POI 点：真要素 + 前端样式
- 勾选「走 Django 代理」：请求改走 http://localhost:8000/ogc/（第 11 集）
