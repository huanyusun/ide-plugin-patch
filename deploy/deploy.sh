#!/usr/bin/env bash
# 部署 lc.f2b.me 反代到 vps154。
# 通道:bryan key 登录(scp 到 /tmp)→ root(su 密码经 /tmp/.lc_deploy_pw,600,用完即删)。
# 密码文件由部署时人工创建,不入仓库。XRay/既有站点不受影响(只加 map 条目+新 conf)。
set -euo pipefail
cd "$(dirname "$0")"

SSHOPTS=(-i "$HOME/.ssh/id_rsa" -o IdentitiesOnly=yes -o ConnectTimeout=10)
VPS=bryan@154.29.144.91
PWFILE="${LC_DEPLOY_PWFILE:-/tmp/.lc_deploy_pw}"

if [[ ! -f "$PWFILE" ]]; then
  echo "缺 $PWFILE(root 密码文件,600)。创建后重试。" >&2
  exit 1
fi

echo "==> 上传远程脚本"
scp -q "${SSHOPTS[@]}" lc-remote.sh "$VPS":/tmp/lc-remote.sh

echo "==> 执行(root)"
PW=$(cat "$PWFILE")
expect -c "
set timeout 120
spawn ssh ${SSHOPTS[*]} $VPS \"su - root -c 'bash /tmp/lc-remote.sh && rm -f /tmp/lc-remote.sh'\"
expect \"Password:\"
send \"$PW\r\"
expect eof
" 2>&1 | sed '1,/Password:/d'

echo "==> 本地端到端验证"
curl -s -o /dev/null -w "graphql via https://lc.f2b.me: %{http_code} %{time_total}s\n" --max-time 20 \
  -X POST https://lc.f2b.me/graphql -H "Content-Type: application/json" -d '{"query":"query{now}"}'
curl -sI --max-time 15 https://lc.f2b.me/ | head -5

echo "==> 清理密码文件"
rm -f "$PWFILE"
echo "部署完成"
