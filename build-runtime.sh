#!/usr/bin/env bash
# build-runtime.sh <platform> <arch> <outdir>
#   构建一个自包含 OpenClaw 运行时目录：官方 node tarball + npm 全局安装 openclaw
#   产出 <outdir>/runtime/ 即 node 根目录（bin/ lib/ 齐全），可整目录拷到 exFAT U 盘
# 用法示例：
#   ./build-runtime.sh darwin arm64 /tmp/rt-darwin-arm64
#   ./build-runtime.sh linux  x64   /tmp/rt-linux-x64
set -euo pipefail

PLAT="$1"; ARCH="$2"; OUT="${3:-$(pwd)/runtime-$PLAT-$ARCH}"
NODE_VER="${NODE_VER:-v25.9.0}"     # 与主脑 node 版本一致
OC_VER="${OC_VER:-2026.8.2}"        # 与主脑 openclaw 版本一致
ALLOW_SCRIPTS="openclaw,@google/genai,koffi,tree-sitter-bash,protobufjs"

echo "== [$PLAT-$ARCH] node $NODE_VER + openclaw $OC_VER -> $OUT"
mkdir -p "$OUT"
BASE="https://nodejs.org/dist/$NODE_VER/node-$NODE_VER-$PLAT-$ARCH"
case "$PLAT" in
  darwin|linux) EXT="tar.gz";;
  win)          EXT="zip";;
  *) echo "bad platform $PLAT"; exit 1;;
esac

cd "$OUT"
echo "== download $BASE.$EXT"
curl -fL --retry 3 -o node.$EXT "$BASE.$EXT"
rm -rf runtime && mkdir runtime
if [ "$EXT" = "zip" ]; then
  tar -xf node.$EXT -C runtime --strip-components=1
else
  tar -xzf node.$EXT -C runtime --strip-components=1
fi
rm -f node.$EXT

# Windows 用 cmd 包装（workflow 里跑）；类 Unix 直接跑
if [ "$PLAT" = "win" ]; then
  ( cd runtime && cmd //c "npm.cmd install -g openclaw@$OC_VER --allow-scripts=$ALLOW_SCRIPTS" )
else
  ( cd runtime && ./bin/npm install -g "openclaw@$OC_VER" --allow-scripts="$ALLOW_SCRIPTS" )
fi

echo "== [$PLAT-$ARCH] done"
"$OUT/runtime/bin/node" -v 2>/dev/null || true
du -sh "$OUT/runtime"
