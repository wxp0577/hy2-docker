#!/bin/sh

# 读取环境变量的端口，默认 443
PORT=${HY2_PORT:-443}

# 创建配置文件夹
mkdir -p /cert

# 自动生成或读取密码逻辑
if [ -n "$HY2_PASSWORD" ]; then
    PASSWORD=$HY2_PASSWORD
else
    if [ ! -f "/cert/password.txt" ]; then
        openssl rand -hex 8 > /cert/password.txt
    fi
    PASSWORD=$(cat /cert/password.txt)
fi

# 生成自签证书 (如果不存在)
if [ ! -f "/cert/server.crt" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /cert/server.key \
        -out /cert/server.crt \
        -days 3650 \
        -subj "/CN=www.bing.com" 2>/dev/null
fi

# 计算证书的 SHA256 指纹
CERT_PIN=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in /cert/server.crt | cut -d "=" -f 2 | tr -d ":")

# 尝试自动获取 VPS 的公网 IPv4 地址
PUBLIC_IP=$(wget -qO- ipv4.icanhazip.com || echo "你的VPS_IP")

# 拼装标准 Hysteria2 节点分享链接
SHARE_LINK="hysteria2://$PASSWORD@$PUBLIC_IP:$PORT/?sni=www.bing.com&insecure=0&pinSHA256=$CERT_PIN#MyHY2-Node"

echo "================================================="
echo "✅ Hysteria 2 初始化成功运行中!"
echo "-------------------------------------------------"
echo "🔗 专属节点分享链接 (直接复制下方整段链接即可导入):"
echo ""
echo "$SHARE_LINK"
echo ""
echo "⚠️ 提示: 如果上面获取的 IP 是 '你的VPS_IP' 或获取错了，请手动将链接里的 IP 替换为你真实的服务器 IP。"
echo "================================================="

# 动态生成 HY2 配置文件
cat <<EOF > /config.yaml
listen: :$PORT
tls:
  cert: /cert/server.crt
  key: /cert/server.key
auth:
  type: password
  password: $PASSWORD
masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com/
    rewriteHost: true
EOF

# 启动 HY2 服务
exec hysteria server -c /config.yaml
