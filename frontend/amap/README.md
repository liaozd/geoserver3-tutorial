# 第 10 集 高德叠加 demo

高德底图 + GeoServer WMS 逐瓦片叠加，含 GCJ-02 纠偏开关。

## 运行

1. 把 index.html 里 YOUR_AMAP_KEY 换成你在高德开放平台申请的 Web 端(JS API) key
2. cd frontend/amap && python3 -m http.server 8003
3. 打开 http://localhost:8003/
# 前置：ep05:roads 已发布；先看偏移现场，再勾「GCJ-02 纠偏」对比

## 原理一句话

高德瓦片按 GCJ-02 编号，GeoServer 数据是 WGS84；纠偏 = 把每个瓦片的 GCJ-02
边界转回 WGS84 再发 GetMap 请求（逐瓦片近似，误差 1-2 米级 [预判]）。
