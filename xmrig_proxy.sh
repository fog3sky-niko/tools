#!/bin/bash
set -e

WALLET="45MQKzDPTVvbWechMZY1L3iGwq3vu2thf7W9PrSAspHiPCHtPbEQ49D5HPXkd8WcXGTZgarFoWChx8qo8bQB9ok24FkauVG"
PROXY_PORT=3389

# 计算CPU核数，90%比例，至少1核
TOTAL_CPU=$(nproc)
CPUS_USED=$((TOTAL_CPU * 90 / 100))
[ $CPUS_USED -lt 1 ] && CPUS_USED=1

echo "总核数: $TOTAL_CPU, 设定用核数: $CPUS_USED"

echo "安装依赖..."
apt update -y
apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# 部署 xmrig-proxy
echo "部署 xmrig-proxy..."
rm -rf ~/xmrig-proxy
git clone https://github.com/xmrig/xmrig-proxy.git ~/xmrig-proxy
cd ~/xmrig-proxy
mkdir -p build && cd build
cmake ..
make -j$(nproc)

cat > ~/xmrig-proxy/build/config.json <<EOF
{
  "bind": "127.0.0.1:$PROXY_PORT",
  "access-log-file": null,
  "upstream": [
    {
      "url": "pool.supportxmr.com:7777",
      "user": "$WALLET",
      "pass": "x"
    }
  ],
  "donate-level": 0
}
EOF

pkill xmrig-proxy || true
nohup ./xmrig-proxy -c config.json > ~/xmrig-proxy/proxy.log 2>&1 &

# 部署 xmrig 矿工
echo "部署 xmrig 矿工..."
rm -rf ~/xmrig
git clone https://github.com/xmrig/xmrig.git ~/xmrig
cd ~/xmrig
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# 生成线程配置
THREADS_JSON=$(for i in $(seq 0 $((CPUS_USED - 1))); do echo "    { \"index\": $i }$( [ $i -lt $((CPUS_USED - 1)) ] && echo "," )"; done)

cat > ~/xmrig/build/config.json <<EOF
{
  "autosave": true,
  "cpu": { "enabled": true },
  "donate-level": 0,
  "pools": [
    {
      "url": "127.0.0.1:$PROXY_PORT",
      "user": "worker-$(hostname)",
      "pass": "x",
      "keepalive": true,
      "tls": false
    }
  ],
  "threads": [
$THREADS_JSON
  ]
}
EOF

pkill xmrig || true
nohup ./xmrig -c config.json > ~/xmrig/miner.log 2>&1 &

echo "部署完成！代理监听127.0.0.1:$PROXY_PORT，矿工连接本地代理。"
echo "CPU 核心使用数: $CPUS_USED"
