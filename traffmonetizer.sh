#!/bin/bash
# ==============================================
# TraffMonetizer 一键安装脚本 (Ubuntu)
# 支持 Ubuntu 18.04 / 20.04 / 22.04
# 支持 amd64 与 arm64 架构
# 需要 root 权限执行
# ==============================================

TOKEN="Cp0Pu7Qd5gy1r/yrSts7rukiCgHYmm9wPl+wEnTo9LE="

echo ">>> 更新系统..."
apt-get update -y && apt-get upgrade -y

echo ">>> 安装 Docker..."
apt-get install -y docker.io

echo ">>> 启动 Docker 并设置开机自启..."
systemctl enable docker
systemctl start docker

# 判断系统架构
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
  IMAGE_TAG="latest"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
  IMAGE_TAG="arm64v8"
else
  echo "不支持的架构：$ARCH"
  exit 1
fi

echo ">>> 使用镜像版本：$IMAGE_TAG"

echo ">>> 拉取 TraffMonetizer 镜像..."
docker pull traffmonetizer/cli_v2:$IMAGE_TAG

echo ">>> 启动 TraffMonetizer 客户端..."
docker rm -f traffmonetizer 2>/dev/null || true
docker run -d \
  --restart always \
  --name traffmonetizer \
  traffmonetizer/cli_v2:$IMAGE_TAG \
  start accept --token $TOKEN

echo "=============================================="
echo "✅ TraffMonetizer 部署完成！"
echo "查看程序日志: docker logs traffmonetizer -f"
echo "停止服务:     docker stop traffmonetizer"
echo "启动服务:     docker start traffmonetizer"
echo "=============================================="
