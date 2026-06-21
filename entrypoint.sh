#!/bin/sh

# 读取环境变量，设置默认值
PORT=${HY2_PORT:-443}
PASSWORD=${HY2_PASSWORD:-HysteriaPassword123}

# 生成自签证书 (如果不存在)
if [ ! -f "/cert/server.crt" ]; then
    echo "未检测到证书，正在生成自签证书..."
    mkdir -p /cert
    # 签发一张有效期 10 年的证书，伪装域名设为 www.bing.com
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /cert/server.key \
        -out /cert/server.crt \
        -days 3650 \
        -subj "/CN=www.bing.com"
fi

# 计算证书的 SHA256 指纹
CERT_PIN=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in /cert/server.crt | cut -d "=" -f 2 | tr -d ":")
echo "================================================="
echo "✅ Hysteria 2 初始化完成!"
echo "👉 你的连接端口: $PORT"
echo "👉 你的连接密码: $PASSWORD"
echo "👉 你的证书指纹 (pinSHA256):"
echo "$CERT_PIN"
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
