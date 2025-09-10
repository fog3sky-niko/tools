#!/bin/bash
set -e

# === 配置参数 ===
POOL="141.148.173.232:3333"
WALLET="45MQKzDPTVvbWechMZY1L3iGwq3vu2thf7W9PrSAspHiPCHtPbEQ49D5HPXkd8WcXGTZgarFoWChx8qo8bQB9ok24FkauVG"
RIG_ID="node_$(hostname)"
WORK_DIR="/opt/xmrig"
CPU_USAGE=90
LOG_FILE="$WORK_DIR/xmrig.log" # 日志文件路径

# === 设置 needrestart 为自动模式（避免交互提示） ===
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# === 安装依赖 ===
echo "正在更新软件包列表并安装依赖..."
apt-get update
apt-get install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev
echo "依赖安装完成。"

# === 下载并编译 xmrig ===
echo "正在准备 XMRig..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
if [ ! -d "xmrig" ]; then
    echo "克隆 XMRig 仓库..."
    git clone https://github.com/xmrig/xmrig.git
fi
cd xmrig
# 可选：如果需要更新到最新版本
# echo "正在拉取最新代码..."
# git pull
# echo "清理旧的构建目录（如果存在）..."
# rm -rf build # 重新编译前删除旧的build目录
mkdir -p build && cd build
echo "正在使用 CMake 配置构建..."
cmake ..
echo "正在编译 XMRig (可能需要一些时间)..."
make -j$(nproc)
echo "XMRig 编译完成。"

# === 启动矿工（使用 XMRig 自带的后台模式）===
echo "正在启动 XMRig 矿工在后台运行..."
"$WORK_DIR/xmrig/build/xmrig" \
    -o "$POOL" \
    -u "$WALLET" \
    -p x \
    --rig-id "$RIG_ID" \
    -k \
    --coin monero \
    --threads $(($(nproc)*CPU_USAGE/100)) \
    --log-file "$LOG_FILE" \
    -B # 使用 -B 或 --background 使其在后台运行

echo "XMRig 矿工已尝试在后台启动。"
echo "日志文件位于: $LOG_FILE"
echo "您可以使用 'tail -f $LOG_FILE' 查看日志。"
echo "要检查进程是否在运行，可以使用 'pgrep xmrig'。"
echo "要停止矿工，您可以使用 'pkill xmrig'。"
