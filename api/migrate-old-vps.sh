#!/usr/bin/env bash
# Migrasi API lama (PM2 + IP:3000) ke VPN API HTTPS tanpa memasang ulang VPS.
# Tidak mengubah akun SSH/Xray, database akun, atau domain tunnel.

set -Eeuo pipefail
PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

readonly REPO_BASE='https://raw.githubusercontent.com/Adidastore11/P/main/'
readonly HAPROXY_CFG='/etc/haproxy/haproxy.cfg'
readonly XRAY_DOMAIN_FILE='/etc/xray/domain'
readonly XRAY_CERT='/etc/xray/xray.crt'
readonly XRAY_KEY='/etc/xray/xray.key'
readonly HAPROXY_PEM='/etc/haproxy/hap.pem'
readonly ACME='/root/.acme.sh/acme.sh'

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }
fail() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }

[[ ${EUID} -eq 0 ]] || fail 'Jalankan sebagai root.'

for command in curl node sudo systemctl haproxy nginx openssl unzip pm2 getent; do
    command -v "$command" >/dev/null 2>&1 || fail "Perintah tidak ada: $command"
done

[[ -s "$XRAY_DOMAIN_FILE" ]] || fail "Domain tunnel tidak ditemukan: $XRAY_DOMAIN_FILE"
[[ -s "$XRAY_CERT" && -s "$XRAY_KEY" && -s "$HAPROXY_PEM" ]] || fail 'File sertifikat tunnel belum lengkap.'
[[ -x "$ACME" ]] || fail "acme.sh tidak ditemukan: $ACME"
[[ -f "$HAPROXY_CFG" ]] || fail "HAProxy config tidak ditemukan: $HAPROXY_CFG"
systemctl is-active --quiet haproxy || fail 'HAProxy tidak aktif.'
systemctl is-active --quiet nginx || fail 'Nginx tidak aktif.'

# Nama proses API lama tidak seragam pada instalasi terdahulu.
# Dukungan dua nama ini menjaga migrasi tidak menyentuh proses PM2 lain.
LEGACY_PM2_NAME=''
for candidate in botvpn apivpn; do
    if pm2 describe "$candidate" >/dev/null 2>&1; then
        LEGACY_PM2_NAME="$candidate"
        break
    fi
done
[[ -n "$LEGACY_PM2_NAME" ]] || fail 'PM2 API lama tidak ditemukan (nama yang didukung: botvpn atau apivpn).'

for path in /opt/vpn-api /usr/local/lib/vpn-api /etc/vpn-api /etc/systemd/system/vpn-api.service /etc/sudoers.d/vpn-api /usr/local/sbin/api-domain; do
    [[ ! -e "$path" ]] || fail "Komponen VPN API baru sudah ada: $path. Batal agar tidak menimpa."
done

grep -qE '^[[:space:]]*frontend[[:space:]]+https_frontend' "$HAPROXY_CFG" || fail 'frontend https_frontend tidak ditemukan.'
grep -qE '^[[:space:]]*bind .*:443[[:space:]]+ssl' "$HAPROXY_CFG" || fail 'Bind HTTPS HAProxy tidak ditemukan.'
grep -qE '^[[:space:]]*acl[[:space:]]+is_websocket_ssl[[:space:]]' "$HAPROXY_CFG" || fail 'ACL WebSocket HTTPS tidak ditemukan.'
! grep -qE '^[[:space:]]*backend[[:space:]]+vpn_api_backend' "$HAPROXY_CFG" || fail 'Backend API sudah ada. Gunakan proses upgrade, bukan migrasi awal.'

valid_domain() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]]
}

public_ip() {
    curl -4fsSL --connect-timeout 5 --max-time 10 https://api.ipify.org
}

domain_points_here() {
    local domain="$1" ip="$2"
    getent ahostsv4 "$domain" 2>/dev/null | awk '{print $1}' | sort -u | grep -Fxq "$ip"
}

wait_for_local_api() {
    local attempt
    for ((attempt = 1; attempt <= 15; attempt++)); do
        if curl -fsS --max-time 3 -H "x-api-key: ${api_key}" http://127.0.0.1:3000/health | grep -q '"ok":true'; then
            return 0
        fi
        sleep 1
    done
    return 1
}

wait_for_https_api() {
    local attempt
    for ((attempt = 1; attempt <= 15; attempt++)); do
        if curl -fsS --max-time 5 --resolve "${API_DOMAIN}:443:127.0.0.1" \
            -H "x-api-key: ${api_key}" "https://${API_DOMAIN}/health" | grep -q '"ok":true'; then
            return 0
        fi
        sleep 1
    done
    return 1
}

API_DOMAIN="${1:-}"
if [[ -z "$API_DOMAIN" ]]; then
    read -rp 'Input API domain baru (contoh api.server-singapura.gachorr.web.id): ' API_DOMAIN
fi
API_DOMAIN=${API_DOMAIN,,}
valid_domain "$API_DOMAIN" || fail 'Format API domain tidak valid.'

TUNNEL_DOMAIN=$(tr -d '[:space:]' <"$XRAY_DOMAIN_FILE")
VPS_IP=$(public_ip) || fail 'IP publik VPS tidak dapat dideteksi.'

domain_points_here "$TUNNEL_DOMAIN" "$VPS_IP" || fail "DNS tunnel ${TUNNEL_DOMAIN} belum mengarah ke ${VPS_IP}."
domain_points_here "$API_DOMAIN" "$VPS_IP" || fail "DNS API ${API_DOMAIN} belum mengarah ke ${VPS_IP} atau masih orange-cloud."

echo
echo "Tunnel domain : ${TUNNEL_DOMAIN}"
echo "API baru      : https://${API_DOMAIN}"
echo "IP VPS        : ${VPS_IP}"
echo 'Akun VPN tidak akan diubah. API PM2 lama diganti hanya setelah API HTTPS baru lulus tes.'
read -rp 'Ketik MIGRATE untuk mulai: ' confirmation
[[ "$confirmation" == 'MIGRATE' ]] || { warn 'Migrasi dibatalkan.'; exit 0; }

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/vpn-api-migration-${STAMP}"
TMP_DIR=$(mktemp -d)
PM2_STOPPED=false
CRONTAB_EXISTS=false

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

install -d -m 700 "$BACKUP_DIR"
cp -a "$HAPROXY_CFG" "$BACKUP_DIR/haproxy.cfg"
cp -a "$XRAY_CERT" "$BACKUP_DIR/xray.crt"
cp -a "$XRAY_KEY" "$BACKUP_DIR/xray.key"
cp -a "$HAPROXY_PEM" "$BACKUP_DIR/hap.pem"
pm2 jlist >"$BACKUP_DIR/pm2-jlist.json" 2>/dev/null || true
if crontab -l >"$BACKUP_DIR/root-crontab" 2>/dev/null; then
    CRONTAB_EXISTS=true
fi

rollback() {
    local rc=$?
    trap - ERR
    set +e
    warn 'Migrasi gagal. Mengembalikan API dan konfigurasi lama...'
    systemctl disable --now vpn-api >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/vpn-api.service /etc/sudoers.d/vpn-api /usr/local/sbin/api-domain /usr/local/bin/ssl_renew.sh
    rm -rf /opt/vpn-api /usr/local/lib/vpn-api /etc/vpn-api
    cp -a "$BACKUP_DIR/haproxy.cfg" "$HAPROXY_CFG"
    cp -a "$BACKUP_DIR/xray.crt" "$XRAY_CERT"
    cp -a "$BACKUP_DIR/xray.key" "$XRAY_KEY"
    cp -a "$BACKUP_DIR/hap.pem" "$HAPROXY_PEM"
    if [[ "$CRONTAB_EXISTS" == true ]]; then
        crontab "$BACKUP_DIR/root-crontab"
    else
        crontab -r 2>/dev/null || true
    fi
    systemctl daemon-reload
    systemctl restart nginx >/dev/null 2>&1 || true
    systemctl restart haproxy >/dev/null 2>&1 || true
    if [[ "$PM2_STOPPED" == true ]]; then
        pm2 restart "$LEGACY_PM2_NAME" >/dev/null 2>&1 || true
    fi
    echo -e "${RED}Rollback selesai. API PM2 lama dipulihkan.${NC}"
    exit "$rc"
}
trap rollback ERR

info 'Mengunduh komponen API baru...'
curl -fsSL "${REPO_BASE}api/server.js" -o "$TMP_DIR/server.js"
curl -fsSL "${REPO_BASE}api/dispatch" -o "$TMP_DIR/dispatch"
curl -fsSL "${REPO_BASE}api/vpn-api.service" -o "$TMP_DIR/vpn-api.service"
curl -fsSL "${REPO_BASE}menu/menu.zip" -o "$TMP_DIR/menu.zip"
unzip -p "$TMP_DIR/menu.zip" 'menu/api-domain' >"$TMP_DIR/api-domain"
[[ -s "$TMP_DIR/api-domain" ]] || fail 'api-domain tidak ditemukan dalam menu.zip.'
sed -i 's/\r$//' "$TMP_DIR/server.js" "$TMP_DIR/dispatch" "$TMP_DIR/vpn-api.service" "$TMP_DIR/api-domain"

node_bin=$(command -v node)
api_key=$(openssl rand -hex 32)

getent group vpnapi >/dev/null || groupadd --system vpnapi
id -u vpnapi >/dev/null 2>&1 || useradd --system --gid vpnapi --home-dir /nonexistent --shell /usr/sbin/nologin vpnapi
install -d -m 755 /opt/vpn-api /usr/local/lib/vpn-api
install -d -m 750 -o root -g vpnapi /etc/vpn-api
install -m 644 "$TMP_DIR/server.js" /opt/vpn-api/server.js
install -m 750 "$TMP_DIR/dispatch" /usr/local/lib/vpn-api/dispatch
install -m 755 "$TMP_DIR/api-domain" /usr/local/sbin/api-domain
install -m 644 "$TMP_DIR/vpn-api.service" /etc/systemd/system/vpn-api.service
sed -i "s|NODE_BIN_PLACEHOLDER|${node_bin}|g" /etc/systemd/system/vpn-api.service
printf 'API_KEY=%s\nPORT=3000\nCMD_TIMEOUT_MS=120000\n' "$api_key" >/etc/vpn-api/api.env
printf '%s\n' "$API_DOMAIN" >/etc/vpn-api/domain
chown root:vpnapi /etc/vpn-api/api.env
chmod 640 /etc/vpn-api/api.env
chmod 600 /etc/vpn-api/domain

cat >/etc/sudoers.d/vpn-api <<'EOF'
vpnapi ALL=(root) NOPASSWD: /usr/local/lib/vpn-api/dispatch
EOF
chmod 440 /etc/sudoers.d/vpn-api
visudo -cf /etc/sudoers.d/vpn-api >/dev/null

info 'Menambahkan route API ke HAProxy...'
sed -i "/^[[:space:]]*acl is_websocket_ssl /i\    acl api_sni ssl_fc_sni -i ${API_DOMAIN}" "$HAPROXY_CFG"
sed -i '/^[[:space:]]*acl is_websocket_ssl /i\    use_backend vpn_api_backend if api_sni' "$HAPROXY_CFG"
cat >>"$HAPROXY_CFG" <<'EOF'

backend vpn_api_backend
    mode tcp
    server vpn_api_server 127.0.0.1:3000 check
EOF
haproxy -c -f "$HAPROXY_CFG" >/dev/null

info "Memindahkan API PM2 (${LEGACY_PM2_NAME}) ke systemd..."
pm2 stop "$LEGACY_PM2_NAME" >/dev/null
PM2_STOPPED=true
systemctl daemon-reload
systemctl enable vpn-api >/dev/null
systemctl start vpn-api
systemctl is-active --quiet vpn-api || fail 'vpn-api gagal aktif.'
wait_for_local_api || fail 'vpn-api aktif tetapi belum siap menerima koneksi lokal.'

info 'Memasang sertifikat HTTPS untuk tunnel dan API...'
/usr/local/sbin/api-domain --renew-cert --force
wait_for_https_api || fail 'API HTTPS belum dapat diakses setelah sertifikat dipasang.'

pm2 delete "$LEGACY_PM2_NAME" >/dev/null
pm2 save >/dev/null
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
    ufw deny 3000/tcp >/dev/null || true
fi

trap - ERR
echo
info 'Migrasi API berhasil.'
echo "API Base URL : https://${API_DOMAIN}"
echo "API Key      : ${api_key}"
echo 'Masukkan Base URL dan API Key baru ke admin panel, lalu tes create akun.'
echo 'API lama PM2 sudah dihentikan; port publik 3000 tidak lagi digunakan.'
echo "Backup        : ${BACKUP_DIR}"
