// 第 08 集：OpenLayers 对接 GeoServer
// 数据：ep05:roads（WMS/WFS/GetFeatureInfo）+ ep06:poi（CQL 过滤 + WFS 渲染）
// 运行：cd frontend/openlayers && python3 -m http.server 8001，打开 http://localhost:8001/

import Map from 'ol/Map.js';
import View from 'ol/View.js';
import TileLayer from 'ol/layer/Tile.js';
import XYZ from 'ol/source/XYZ.js';
import TileWMS from 'ol/source/TileWMS.js';
import {Vector as VectorLayer} from 'ol/layer/Vector.js';
import {Vector as VectorSource} from 'ol/source/Vector.js';
import GeoJSON from 'ol/format/GeoJSON.js';
import {fromLonLat} from 'ol/proj.js';
import {Style, Circle, Fill, Stroke} from 'ol/style.js';

const GS = 'http://localhost:8080/geoserver';
const PROXY = 'http://localhost:8000/ogc';   // 第 11 集 Django 代理
let useProxy = false;

const view = new View({center: fromLonLat([116.397, 39.909]), zoom: 11});
const base = new TileLayer({source: new XYZ({url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'})});

const roads = new TileLayer({
  source: new TileWMS({
    url: GS + '/ep05/wms',
    params: {LAYERS: 'ep05:roads', TILED: true, FORMAT: 'image/png'},
    serverType: 'geoserver',
  }),
});

const pois = new TileLayer({
  source: new TileWMS({
    url: GS + '/ep06/wms',
    params: {LAYERS: 'ep06:poi', FORMAT: 'image/png', CQL_FILTER: ''},
    serverType: 'geoserver',
  }),
});

const poiVec = new VectorLayer({
  source: new VectorSource(),
  style: new Style({
    image: new Circle({
      radius: 6,
      fill: new Fill({color: 'rgba(220,60,60,0.85)'}),
      stroke: new Stroke({color: '#fff', width: 1.5}),
    }),
  }),
});

// CQL 过滤：服务端过滤，前端只传一个参数（中文值 URL 编码同第 06 集坑）
document.getElementById('cat').addEventListener('change', (e) => {
  const cat = e.target.value;
  pois.getSource().updateParams({CQL_FILTER: cat ? `category='${cat}'` : undefined});
});

// GetFeatureInfo 点击查询：返回 JSON 属性，弹窗展示
const map = new Map({target: 'map', view: view, layers: [base, roads, pois, poiVec]});
map.on('singleclick', async (evt) => {
  const url = roads.getSource().getGetFeatureInfoUrl(
    evt.coordinate, map.getView().getResolution(), view.getProjection(),
    {INFO_FORMAT: 'application/json', QUERY_LAYERS: 'ep05:roads', FEATURE_COUNT: 5});
  if (!url) return;
  const r = await fetch(url);
  const j = await r.json();
  const f = j.features[0];
  const box = document.getElementById('popup');
  const t = document.getElementById('popup-title');
  const d = document.getElementById('popup-attrs');
  if (!f) { box.style.display = 'none'; return; }
  t.textContent = '道路要素';
  d.textContent = Object.entries(f.properties).map(([k, v]) => k + ': ' + v).join(' | ');
  box.style.display = 'block';
});

// WFS GeoJSON 渲染 POI 点位
async function fetchWfs() {
  const base0 = useProxy ? PROXY : GS;
  const res = await fetch(base0 + '/ep06/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=ep06:poi&outputFormat=application/json&maxFeatures=50');
  const j = await res.json();
  const feats = new GeoJSON().readFeatures(j, {dataProjection: 'EPSG:4326', featureProjection: 'EPSG:3857'});
  poiVec.getSource().clear();
  poiVec.getSource().addFeatures(feats);
  document.getElementById('status').textContent = 'WFS 50 点已渲染';
}
fetchWfs();

// 代理开关：第 11 集后端跑起来后勾选，跨域与内网暴露问题一起消失
const cb = document.getElementById('proxy');
cb.addEventListener('change', () => {
  useProxy = cb.checked;
  roads.getSource().setUrl((useProxy ? PROXY : GS) + '/ep05/wms');
  pois.getSource().setUrl((useProxy ? PROXY : GS) + '/ep06/wms');
  fetchWfs();
});
