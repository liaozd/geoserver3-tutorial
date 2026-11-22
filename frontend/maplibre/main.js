// 第 09 集：MapLibre GL 加载 GeoServer 矢量切片（MVT）
// 数据：ep05:roads（线）+ ep06:wangge（面），WMS GetMap 直出 MVT
// 运行：cd frontend/maplibre && python3 -m http.server 8002，打开 http://localhost:8002/

const GS = 'http://localhost:8080/geoserver';

// MVT 瓦片模板：{bbox-epsg3857} 由 MapLibre 按当前视野替换
function mvtUrl(layer, ws) {
  return GS + '/' + ws + '/wms?service=WMS&version=1.1.0&request=GetMap'
    + '&layers=' + ws + ':' + layer
    + '&bbox={bbox-epsg3857}&width=256&height=256&srs=EPSG:3857'
    + '&format=application/vnd.mapbox-vector-tile';
}

const map = new maplibregl.Map({
  container: 'map',
  style: {
    version: 8,
    sources: {
      osm: { type: 'raster', tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'], tileSize: 256, attribution: '(c) OpenStreetMap contributors' },
      gs_roads: { type: 'vector', tiles: [mvtUrl('roads', 'ep05')], tileSize: 256 },
      gs_wangge: { type: 'vector', tiles: [mvtUrl('wangge', 'ep06')], tileSize: 256 },
    },
    layers: [
      { id: 'osm', type: 'raster', source: 'osm' },
      { id: 'wangge-fill', type: 'fill', source: 'gs_wangge', 'source-layer': 'wangge', paint: { 'fill-color': '#f7fbff', 'fill-opacity': 0.6 } },
      { id: 'wangge-line', type: 'line', source: 'gs_wangge', 'source-layer': 'wangge', paint: { 'line-color': '#9ecae1' } },
      { id: 'roads-line', type: 'line', source: 'gs_roads', 'source-layer': 'roads', paint: { 'line-color': '#f59e0b', 'line-width': 2 } },
    ],
  },
  center: [116.397, 39.909],
  zoom: 10,
});

// 对比 SLD 服务端渲染：这里样式全在前端，改色/过滤不发请求
document.getElementById('recolor').onclick = () => {
  map.setPaintProperty('roads-line', 'line-color', '#10b981');
  map.setPaintProperty('wangge-fill', 'fill-color', '#fee2e2');
  document.getElementById('status').textContent = '已改色（无网络请求）';
};

document.getElementById('filter').onclick = () => {
  map.setFilter('wangge-fill', ['>', ['get', 'pop'], 120]);
  map.setFilter('wangge-line', ['>', ['get', 'pop'], 120]);
  document.getElementById('status').textContent = '已过滤 pop>120（无网络请求）';
};

document.getElementById('reset').onclick = () => {
  map.setPaintProperty('roads-line', 'line-color', '#f59e0b');
  map.setPaintProperty('wangge-fill', 'fill-color', '#f7fbff');
  map.setFilter('wangge-fill', null);
  map.setFilter('wangge-line', null);
  document.getElementById('status').textContent = '已复位';
};
