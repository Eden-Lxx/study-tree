#!/bin/bash
# study-tree · 服务器部署脚本（Ubuntu 20.04+ / 阿里云轻量应用服务器）
# 用法：把项目上传到 /opt/study-tree 后，sudo bash deploy.sh
set -e

echo "=============================================="
echo " study-tree 部署脚本"
echo "=============================================="

if [ ! -f /opt/study-tree/server.js ]; then
  echo "[错误] 没找到 /opt/study-tree/server.js"
  echo "请先把项目上传到 /opt/study-tree，再运行本脚本。"
  exit 1
fi

echo ""
echo "==> 1/5 安装 Node.js 20 与 Nginx"
apt update -y
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs nginx

echo "Node: $(node -v)"
echo "Nginx: $(nginx -v 2>&1)"

echo ""
echo "==> 2/5 写入 systemd 服务（开机自启 + 崩溃自动重启）"
cat > /etc/systemd/system/study-tree.service <<'EOF'
[Unit]
Description=study-tree
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/study-tree
Environment=PORT=5173
Environment=HOST=127.0.0.1
Environment=NO_OPEN=1
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable study-tree

echo ""
echo "==> 3/5 配置 Nginx 反向代理（先用 IP 访问）"
cat > /etc/nginx/sites-available/study-tree <<'EOF'
server {
    listen 80 default_server;
    server_name _;
    client_max_body_size 40m;

    location / {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/study-tree /etc/nginx/sites-enabled/study-tree
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo ""
echo "==> 4/5 放行本机防火墙（如启用）"
if command -v ufw >/dev/null 2>&1; then
  ufw allow 22/tcp  >/dev/null 2>&1 || true
  ufw allow 80/tcp  >/dev/null 2>&1 || true
  ufw allow 443/tcp >/dev/null 2>&1 || true
fi

echo ""
echo "==> 5/5 启动服务"
systemctl restart study-tree
sleep 1
systemctl --no-pager status study-tree | head -12

echo ""
echo "=============================================="
echo " 部署完成！浏览器访问：http://120.77.70.216"
echo " 查看日志：journalctl -u study-tree -f"
echo " 重启服务：systemctl restart study-tree"
echo " 数据目录：/opt/study-tree/data （记得定期备份）"
echo "=============================================="
