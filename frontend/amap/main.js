// 第 10 集：高德底图 + WMS 叠加 + GCJ-02 纠偏演示
// 运行：cd frontend/amap && python3 -m http.server 8003，打开 http://localhost:8003/
// 前置：把 index.html 里 YOUR_AMAP_KEY 换成你在高德开放平台申请的 Web 端(JS API) key

const GS = 'http://localhost:8080/geoserver';
let corrected = false;

// GCJ-02 偏移算法（公开通用实现；偏移量随位置变化，非固定值）
const PI = Math.PI, A = 6378245.0, EE = 0.00669342162296594323;
function outOfChina(lng, lat) { return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271; }
function transformLat(x, y) {
  let r = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x));
  r += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0;
  r += (20.0 * Math.sin(y * PI) + 40.0 * Math.sin(y / 3.0 * PI)) * 2.0 / 3.0;
  r += (160.0 * Math.sin(y / 12.0 * PI) + 320.0 * Math.sin(y * PI / 30.0)) * 2.0 / 3.0;
  return r;
}
function transformLng(x, y) {
  let r = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x));
  r += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0;
  r += (20.0 * Math.sin(x * PI) + 40.0 * Math.sin(x / 3.0 * PI)) * 2.0 / 3.0;
  r += (150.0 * Math.sin(x / 12.0 * PI) + 300.0 * Math.sin(x / 30.0 * PI)) * 2.0 / 3.0;
  return r;
}
function wgs2gcj(lng, lat) {
  if (outOfChina(lng, lat)) return [lng, lat];
  let dlat = transformLat(lng - 105.0, lat - 35.0);
  let dlng = transformLng(lng - 105.0, lat - 35.0);
  const radlat = lat / 180.0 * PI;
  let magic = Math.sin(radlat);
  magic = 1 - EE * magic * magic;
  const sqrtmagic = Math.sqrt(magic);
  dlat = (dlat * 180.0) / ((A * (1 - EE)) / (magic * sqrtmagic) * PI);
  dlng = (dlng * 180.0) / (A / sqrtmagic * Math.cos(radlat) * PI);
  return [lng + dlng, lat + dlat];
}
function gcj2wgs(lng, lat) {
  const g = wgs2gcj(lng, lat);
  return [2 * lng - g[0], 2 * lat - g[1]];
}

// 标准 XYZ 瓦片的经纬度边界（EPSG:4326 经纬度序）
function tileBounds(x, y, z) {
  const n = Math.pow(2, z);
  const lon_min = x / n * 360 - 180;
  const lon_max = (x + 1) / n * 360 - 180;
  const lat_max = Math.atan(Math.sinh(Math.PI * (1 - 2 * y / n))) * 180 / PI;
  const lat_min = Math.atan(Math.sinh(Math.PI * (1 - 2 * (y + 1) / n))) * 180 / PI;
  return [lon_min, lat_min, lon_max, lat_max];
}

// 每瓦片一张 WMS GetMap；纠偏 = 把 GCJ-02 瓦片边界转回 WGS84 再请求
function wmsTileUrl(x, y, z) {
  const b = tileBounds(x, y, z);
  let minx = b[0], miny = b[1], maxx = b[2], maxy = b[3];
  if (corrected) {
    const sw = gcj2wgs(minx, miny);
    const ne = gcj2wgs(maxx, maxy);
    minx = sw[0]; miny = sw[1]; maxx = ne[0]; maxy = ne[1];
  }
  return GS + '/ep05/wms?service=WMS&version=1.1.0&request=GetMap'
    + '&layers=ep05:roads&bbox=' + minx + ',' + miny + ',' + maxx + ',' + maxy
    + '&width=256&height=256&srs=EPSG:4326&format=image/png&transparent=true';
}

const map = new AMap.Map('map', { center: [116.397, 39.909], zoom: 12 });

const wmsLayer = new AMap.TileLayer({
  tileSize: 256,
  getTileUrl: wmsTileUrl,
  zooms: [3, 18],
});
wmsLayer.setMap(map);

const cb = document.getElementById('fix');
cb.addEventListener('change', () => {
  corrected = cb.checked;
  wmsLayer.reload();
  document.getElementById('status').textContent = corrected ? 'corrected' : 'offset';
  document.getElementById('status').textContent = corrected ? 'already fixed' : 'offset (raw)';
}); 
