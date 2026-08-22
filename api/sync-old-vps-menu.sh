#!/usr/bin/env bash
# Sinkronkan hanya menu yang berkaitan dengan domain VPN/API pada VPS lama.
# Tidak menimpa skrip akun, database akun, Xray, Nginx, atau HAProxy.

set -Eeuo pipefail
PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

readonly MENU_ZIP_URL='https://raw.githubusercontent.com/Adidastore11/P/main/menu/menu.zip'
readonly TARGET_DIR='/usr/local/sbin'

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }

[[ ${EUID} -eq 0 ]] || fail 'Jalankan sebagai root.'
command -v curl >/dev/null 2>&1 || fail 'curl tidak tersedia.'
command -v unzip >/dev/null 2>&1 || fail 'unzip tidak tersedia.'

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/root/api-menu-sync-${STAMP}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

install -d -m 700 "$BACKUP_DIR"
info 'Mengunduh menu.zip terbaru...'
curl -fsSL "$MENU_ZIP_URL" -o "$TMP_DIR/menu.zip"

for script in utility addhost fixcert api-domain; do
    unzip -p "$TMP_DIR/menu.zip" "menu/${script}" >"$TMP_DIR/${script}"
    [[ -s "$TMP_DIR/${script}" ]] || fail "${script} tidak ditemukan dalam menu.zip."
    sed -i 's/\r$//' "$TMP_DIR/${script}"
done

grep -q 'API VPS CONTROL' "$TMP_DIR/utility" || fail 'utility versi baru tidak valid.'
grep -q 'Domain API tidak ikut berubah' "$TMP_DIR/addhost" || fail 'addhost versi baru tidak valid.'
grep -q 'api-domain --renew-cert' "$TMP_DIR/fixcert" || fail 'fixcert versi baru tidak valid.'

for script in utility addhost fixcert api-domain; do
    [[ -e "${TARGET_DIR}/${script}" ]] && cp -a "${TARGET_DIR}/${script}" "${BACKUP_DIR}/${script}"
done

for script in utility addhost fixcert api-domain; do
    install -m 755 "$TMP_DIR/${script}" "${TARGET_DIR}/${script}"
done

# Membuat ulang cron cek sertifikat tanpa menerbitkan ulang cert bila masih sehat.
/usr/local/sbin/api-domain --renew-cert

echo
info 'Sinkronisasi menu API berhasil.'
echo 'Buka: menu -> utility -> 23. API VPS CONTROL'
echo "Backup menu lama: ${BACKUP_DIR}"
