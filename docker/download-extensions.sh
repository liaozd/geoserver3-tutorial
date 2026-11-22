#!/usr/bin/env bash
# 预下载 GeoServer 3.0.x 扩展包到 docker/additional_libs/
# 容器启动时挂载该目录即可离线安装，跳过容器内慢速下载（install-extensions.sh 已支持）
# 用法：bash docker/download-extensions.sh
# 支持断点续传：中断后重跑即可；按 Content-Length + zip 完整性双重校验
# 注意：ext-latest 是 nightly 快照，重建会改变文件内容；跨重建续传会产生坏包，
# 校验失败时自动删除重下
set -euo pipefail

BASE_URL="https://build.geoserver.org/geoserver/3.0.x/ext-latest"
VERSION="3.0.3-SNAPSHOT"   # 构建服务器当前文件名版本；若 404 会自动回退抓目录列表
EXTENSIONS="css ysld wps vectortiles netcdf netcdf-out mongodb"
DEST="$(cd "$(dirname "$0")" && pwd)/additional_libs"
mkdir -p "$DEST"

# 慢速链路友好：不设总时长上限，仅当连续 120 秒低于 1KB/s 才中断（配合重试续传）
CURL_SLOW_OPTS="--speed-limit 1024 --speed-time 120"

# 构建服务器会主动掐断长连接（实测约 3 分半一次），循环续传直到拉完
fetch_resume() {
  local url="$1" dest="$2" attempt
  for attempt in $(seq 1 60); do
    # shellcheck disable=SC2086
    if curl -fL -C - --retry 3 --retry-delay 3 $CURL_SLOW_OPTS -o "$dest" "$url"; then
      return 0
    fi
    echo "连接中断，3 秒后续传（第 $attempt 次）: $(basename "$dest")"
    sleep 3
  done
  echo "错误: 60 次续传后仍未完成: $(basename "$dest")" >&2
  return 1
}

download_one() {
  local url="$1" dest="$2" size
  size=$(curl -fsSI --max-time 30 "$url" | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2; exit}')
  if [ -e "$dest" ] && [ -n "$size" ] && [ "$(wc -c < "$dest" | tr -d ' ')" = "$size" ] \
     && unzip -tq "$dest" >/dev/null 2>&1; then
    echo "已存在且完整，跳过: $(basename "$dest")"
    return 0
  fi
  echo "下载: $(basename "$dest")"
  fetch_resume "$url" "$dest"
  if ! unzip -tq "$dest" >/dev/null 2>&1; then
    echo "包损坏（可能跨 nightly 重建续传所致），删除后全新重下: $(basename "$dest")"
    rm -f "$dest"
    fetch_resume "$url" "$dest"
    unzip -tq "$dest" >/dev/null
  fi
}

LISTING=""
for ext in $EXTENSIONS; do
  file="geoserver-${VERSION}-${ext}-plugin.zip"
  if curl -fsSI --max-time 30 "$BASE_URL/$file" >/dev/null 2>&1; then
    download_one "$BASE_URL/$file" "$DEST/$file"
  else
    # 文件名版本可能已变化（如升到 3.0.4-SNAPSHOT），抓目录列表找真实文件名
    if [ -z "$LISTING" ]; then
      LISTING=$(curl -fsS --max-time 60 "$BASE_URL/")
    fi
    real=$(echo "$LISTING" | grep -o "geoserver-[0-9][^\"]*-${ext}-plugin\.zip" | head -n 1)
    if [ -z "$real" ]; then
      echo "错误: 未找到 $ext 的插件包" >&2
      exit 1
    fi
    download_one "$BASE_URL/$real" "$DEST/$real"
  fi
done

echo "完成。扩展包位于 $DEST"
echo "启动容器时挂载: --mount type=bind,src=\"$DEST\",target=/opt/additional_libs"