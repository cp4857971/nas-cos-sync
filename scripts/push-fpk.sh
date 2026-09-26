#!/bin/bash
# ============================================================
# 将 nas-cos-sync.fpk 二进制包推送到 GitHub 仓库
# 说明：55MB 二进制无法经 MCP 文本接口提交，需在本机执行本脚本
# 用法：bash scripts/push-fpk.sh [fpk路径] [版本号]
#   fpk路径 默认 ./nas-cos-sync.fpk；版本号 默认 2.6.1
# ============================================================
set -euo pipefail

REPO_URL="https://github.com/cp4857971/nas-cos-sync.git"
FPK_SOURCE="${1:-./nas-cos-sync.fpk}"
VERSION="${2:-2.6.1}"

if [ ! -f "$FPK_SOURCE" ]; then
  echo "错误：找不到 $FPK_SOURCE"
  echo "请先下载："
  echo "  curl -L -o nas-cos-sync.fpk \"https://aka.doubaocdn.com/s/tRVBzv5qGE\""
  exit 1
fi

# 校验（可选，防文件损坏）
ACTUAL_MD5=$(md5sum "$FPK_SOURCE" | awk '{print $1}')
EXPECTED_MD5="67eb64889f2d0691e10c162f9faec123"
if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
  echo "警告：MD5 不匹配（实际 $ACTUAL_MD5，期望 $EXPECTED_MD5），请确认文件完整"
  read -r -p "仍然继续？[y/N] " ans
  [[ "$ans" == "y" ]] || exit 1
fi

cd "$(dirname "$0")/.."
mkdir -p releases
DEST="releases/nas-cos-sync-${VERSION}.fpk"
cp "$FPK_SOURCE" "$DEST"

git add "$DEST" README.md scripts/push-fpk.sh
git commit -m "release: nas-cos-sync ${VERSION}"
git tag "v${VERSION}"
git push origin HEAD --tags
echo "完成：$DEST 已推送，tag v${VERSION}"
