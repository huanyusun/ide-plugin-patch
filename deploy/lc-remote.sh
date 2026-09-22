#!/bin/bash
# lc.f2b.me 反代部署(root 在 VPS 上执行)
# 步骤:stream map 加条目 → webroot → 80 ACME conf → certbot 签证书 → 10444 ssl 反代块 → 验证
set -e
echo "==> 0. 直连 leetcode.cn 连通性"
curl -s -o /dev/null -w "direct leetcode.cn: %{http_code} %{time_total}s\n" --max-time 10 https://leetcode.cn/

echo "==> 1. stream map 加 lc.f2b.me"
if ! grep -q "lc.f2b.me" /etc/nginx/nginx.conf; then
  sed -i 's|        artifacts.f2b.me nginx_web;|        artifacts.f2b.me nginx_web;\n        lc.f2b.me    nginx_web;|' /etc/nginx/nginx.conf
fi
grep -n "lc.f2b.me" /etc/nginx/nginx.conf

echo "==> 2. webroot 目录"
mkdir -p /var/www/lc/.well-known/acme-challenge
chown -R bryan:bryan /var/www/lc

echo "==> 3. 写 80 ACME conf"
cat > /etc/nginx/conf.d/lc.conf <<'CONF'
# lc.f2b.me — leetcode 私有反代(80 ACME + 10444 SNI web;443 由 stream 层 SNI 分发)
server {
    listen 80;
    listen [::]:80;
    server_name lc.f2b.me;

    location /.well-known/acme-challenge/ {
        root /var/www/lc;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}
CONF
nginx -t
systemctl reload nginx

echo "==> 4. 签发证书"
if [ ! -d "/etc/letsencrypt/live/lc.f2b.me" ]; then
  certbot certonly --webroot -w /var/www/lc -d lc.f2b.me --non-interactive --agree-tos 2>&1 | tail -6
fi
test -f /etc/letsencrypt/live/lc.f2b.me/fullchain.pem || { echo "证书签发失败"; exit 1; }
echo "证书 OK"

echo "==> 5. 追加 10444 ssl 反代块"
cat >> /etc/nginx/conf.d/lc.conf <<'CONF'

server {
    listen 127.0.0.1:10444 ssl;
    server_name lc.f2b.me;

    ssl_certificate     /etc/letsencrypt/live/lc.f2b.me/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lc.f2b.me/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    access_log /var/log/nginx/lc.f2b.me.access.log;

    location / {
        proxy_pass https://leetcode.cn;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_ssl_server_name on;
        proxy_ssl_name leetcode.cn;
        proxy_set_header Host leetcode.cn;
        proxy_set_header Referer "https://leetcode.cn/";
        proxy_set_header Origin "https://leetcode.cn";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Accept-Encoding "";
        proxy_cookie_domain leetcode.cn lc.f2b.me;
        proxy_redirect https://leetcode.cn/ https://lc.f2b.me/;
        sub_filter "leetcode.cn" "lc.f2b.me";
        sub_filter_once off;
        sub_filter_types text/html application/json;
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
CONF
nginx -t
systemctl reload nginx

echo "==> 6. 验证"
sleep 1
ss -ltn | grep ":443 "
curl -s -o /dev/null -w "graphql via proxy: %{http_code} %{time_total}s\n" --max-time 20 \
  -X POST https://lc.f2b.me/graphql -H "Content-Type: application/json" \
  -d '{"query":"query{now}"}'
echo "==> DONE"
