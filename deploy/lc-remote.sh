#!/bin/bash
# 修复 lc.f2b.me 资源子域加载(精确映射子域到主域路径)+ robots.txt 拒爬虫
set -e
cat > /etc/nginx/conf.d/lc.conf <<'CONF'
# lc.f2b.me — 私有反代(80 ACME + 10444 SNI web;443 由 stream 层 SNI 分发)
server {
    listen 80;
    listen [::]:80;
    server_name lc.f2b.me;

    location /.well-known/acme-challenge/ {
        root /var/www/lc;
    }

    location = /robots.txt {
        default_type text/plain;
        return 200 "User-agent: *\nDisallow: /\n";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 127.0.0.1:10444 ssl;
    server_name lc.f2b.me;

    ssl_certificate     /etc/letsencrypt/live/lc.f2b.me/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lc.f2b.me/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    access_log /var/log/nginx/lc.f2b.me.access.log;

    location = /robots.txt {
        default_type text/plain;
        return 200 "User-agent: *\nDisallow: /\n";
    }

    # ---- 资源子域:static / assets / pic / e ----
    location /__static/ {
        proxy_pass https://static.leetcode.cn/;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_ssl_server_name on;
        proxy_ssl_name static.leetcode.cn;
        proxy_set_header Host static.leetcode.cn;
        proxy_set_header Referer "https://leetcode.cn/";
        proxy_set_header Accept-Encoding "";
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
    }
    location /__assets/ {
        proxy_pass https://assets.leetcode.cn/;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_ssl_server_name on;
        proxy_ssl_name assets.leetcode.cn;
        proxy_set_header Host assets.leetcode.cn;
        proxy_set_header Referer "https://leetcode.cn/";
        proxy_set_header Accept-Encoding "";
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
    }
    location /__pic/ {
        proxy_pass https://pic.leetcode.cn/;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_ssl_server_name on;
        proxy_ssl_name pic.leetcode.cn;
        proxy_set_header Host pic.leetcode.cn;
        proxy_set_header Referer "https://leetcode.cn/";
        proxy_set_header Accept-Encoding "";
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
    }
    location /__e/ {
        proxy_pass https://e.leetcode.cn/;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_ssl_server_name on;
        proxy_ssl_name e.leetcode.cn;
        proxy_set_header Host e.leetcode.cn;
        proxy_set_header Accept-Encoding "";
        proxy_connect_timeout 10s;
        proxy_read_timeout 30s;
    }

    # ---- 主站反代 ----
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
        proxy_redirect https://www.leetcode.cn/ https://lc.f2b.me/;
        # 资源子域 → 主域代理路径(JSON 转义斜杠形式单独覆盖)
        sub_filter 'https://static.leetcode.cn/'  'https://lc.f2b.me/__static/';
        sub_filter '//static.leetcode.cn/'         '/__static/';
        sub_filter 'https:\/\/static.leetcode.cn\/'  'https:\/\/lc.f2b.me\/__static\/';
        sub_filter 'https://assets.leetcode.cn/'   'https://lc.f2b.me/__assets/';
        sub_filter '//assets.leetcode.cn/'         '/__assets/';
        sub_filter 'https:\/\/assets.leetcode.cn\/'  'https:\/\/lc.f2b.me\/__assets\/';
        sub_filter 'https://pic.leetcode.cn/'      'https://lc.f2b.me/__pic/';
        sub_filter '//pic.leetcode.cn/'            '/__pic/';
        sub_filter 'https:\/\/pic.leetcode.cn\/'  'https:\/\/lc.f2b.me\/__pic\/';
        sub_filter 'https://e.leetcode.cn/'        'https://lc.f2b.me/__e/';
        sub_filter '//e.leetcode.cn/'              '/__e/';
        sub_filter 'https://leetcode.cn/'          'https://lc.f2b.me/';
        sub_filter 'https:\/\/leetcode.cn\/'       'https:\/\/lc.f2b.me\/';
        sub_filter 'https://leetcode.cn?'          'https://lc.f2b.me?';
        sub_filter 'https://leetcode.cn"'          'https://lc.f2b.me"';
        sub_filter 'https:\/\/leetcode.cn?'        'https:\/\/lc.f2b.me?';
        sub_filter_once off;
        sub_filter_types text/html application/json;
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
CONF
nginx -t && systemctl reload nginx
echo "==> 验证"
curl -s --max-time 15 https://lc.f2b.me/ | grep -c "lc\.f2b\.me/__static" && echo "子域映射 OK" || echo "警告:首页未出现 __static 引用(可能当前页面模板无引用)"
BAD=$(curl -s --max-time 15 https://lc.f2b.me/ | grep -c "static\.lc\.f2b\.me\|assets\.lc\.f2b\.me\|pic\.lc\.f2b\.me" || true)
echo "坏子域引用残留: $BAD"
curl -s -o /dev/null -w "robots.txt: %{http_code}\n" https://lc.f2b.me/robots.txt
echo "==> DONE"
