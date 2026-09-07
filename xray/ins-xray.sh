#!/bin/bash
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================
# Getting
REPO="https://raw.githubusercontent.com/Adidastore11/P/main/"
echo -e "
"
date
echo ""
cd
if [[ -e /etc/xray/domain ]]; then
domain=$(cat /etc/xray/domain)
else
domain=""
fi
sleep 0.5
echo -e "[ ${green}INFO${NC} ] Checking... "
apt install iptables iptables-persistent -y
sleep 0.5
echo -e "[ ${green}INFO$NC ] Setting ntpdate"
ntpdate pool.ntp.org
timedatectl set-ntp true
sleep 0.5
echo -e "[ ${green}INFO$NC ] Enable chrony"
systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta
sleep 0.5
echo -e "[ ${green}INFO$NC ] Setting chrony tracking"
chronyc sourcestats -v
chronyc tracking -v
echo -e "[ ${green}INFO$NC ] Setting dll"
apt clean all && apt update
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
apt install zip -y
apt install curl pwgen openssl cron -y

# install xray
sleep 0.5
echo -e "[ ${green}INFO$NC ] Downloading & Installing xray core"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data:www-data $domainSock_dir
# Make Folder XRay
mkdir -p /var/log/xray
mkdir -p /etc/xray
chown www-data:www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log
# Download installer terlebih dahulu agar kegagalan unduh tidak diteruskan sebagai
# instalasi Xray kosong. Installer resmi juga memverifikasi checksum arsip Xray.
xray_installer="/tmp/xray-install-release.sh"
if ! curl -4 --fail --location --retry 5 --retry-delay 5 \
  --connect-timeout 15 --max-time 300 \
  "https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh" \
  -o "$xray_installer"; then
    echo "Gagal mengunduh installer Xray. Periksa jaringan VPS lalu ulangi instalasi."
    exit 1
fi
if ! head -n 1 "$xray_installer" | grep -q '^#!'; then
    echo "Installer Xray yang diunduh tidak valid. Instalasi dihentikan."
    exit 1
fi
if ! bash "$xray_installer" install --no-update-service -u www-data; then
    echo "Instalasi Xray gagal. Konfigurasi panel tidak diubah."
    exit 1
fi
if [[ ! -x /usr/local/bin/xray ]]; then
    echo "Binary /usr/local/bin/xray tidak ditemukan setelah instalasi. Instalasi dihentikan."
    exit 1
fi

## crt xray
if [[ -z "$domain" ]]; then
    echo "Domain kosong. Sertifikat tidak dapat dibuat."
    exit 1
fi

# Gunakan endpoint resmi acme.sh dan jangan lanjut bila instalasi/upgrade gagal.
if [[ ! -x /root/.acme.sh/acme.sh ]]; then
    acme_installer="/tmp/acme-install.sh"
    if ! curl -4 --fail --location --retry 5 --retry-delay 5 \
      --connect-timeout 15 --max-time 300 https://get.acme.sh -o "$acme_installer"; then
        echo "Gagal mengunduh acme.sh. Periksa jaringan VPS lalu ulangi instalasi."
        exit 1
    fi
    if ! sh "$acme_installer" --home /root/.acme.sh --nocron; then
        echo "Instalasi acme.sh gagal. Instalasi dihentikan."
        exit 1
    fi
fi
if [[ ! -x /root/.acme.sh/acme.sh ]]; then
    echo "Binary acme.sh tidak ditemukan. Instalasi dihentikan."
    exit 1
fi
if ! /root/.acme.sh/acme.sh --upgrade --auto-upgrade; then
    echo "Upgrade acme.sh gagal. Instalasi dihentikan agar sertifikat tidak invalid."
    exit 1
fi
if ! /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt; then
    echo "Gagal memilih CA Let's Encrypt. Instalasi dihentikan."
    exit 1
fi

# Standalone ACME membutuhkan port 80; hentikan dua service yang dapat memakainya.
systemctl stop nginx >/dev/null 2>&1 || true
systemctl stop haproxy >/dev/null 2>&1 || true
if ! /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256; then
    echo "Penerbitan sertifikat gagal. Periksa DNS domain dan port 80 VPS."
    systemctl start nginx >/dev/null 2>&1 || true
    systemctl start haproxy >/dev/null 2>&1 || true
    exit 1
fi
if ! /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc; then
    echo "Pemasangan sertifikat Xray gagal. Instalasi dihentikan."
    systemctl start nginx >/dev/null 2>&1 || true
    systemctl start haproxy >/dev/null 2>&1 || true
    exit 1
fi
if [[ ! -s /etc/xray/xray.crt || ! -s /etc/xray/xray.key ]] || ! openssl x509 -in /etc/xray/xray.crt -noout; then
    echo "File sertifikat Xray tidak valid. Instalasi dihentikan."
    systemctl start nginx >/dev/null 2>&1 || true
    systemctl start haproxy >/dev/null 2>&1 || true
    exit 1
fi

# nginx renew ssl
echo -n '#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
/etc/init.d/nginx status
' > /usr/local/bin/ssl_renew.sh
chmod +x /usr/local/bin/ssl_renew.sh
if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root;then (crontab -l;echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab;fi

mkdir -p /var/www/html

# set uuid
# set uuid
uuid=$(cat /proc/sys/kernel/random/uuid)
# xray config
cat > /etc/xray/config.json << END
{
  "log" : {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
      {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
   {
     "listen": "127.0.0.1",
     "port": "10001",
     "protocol": "vless",
      "settings": {
          "decryption":"none",
            "clients": [
               {
                 "id": "${uuid}"                 
#vless
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vless"
          }
        }
     },
     {
     "listen": "127.0.0.1",
     "port": "10002",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmess
             }
          ]
       },
       "streamSettings":{
         "network": "ws",
            "wsSettings": {
                "path": "/vmess"
          }
        }
     },
    {
      "listen": "127.0.0.1",
      "port": "10003",
      "protocol": "trojan",
      "settings": {
          "decryption":"none",		
           "clients": [
              {
                 "password": "${uuid}"
#trojanws
              }
          ],
         "udp": true
       },
       "streamSettings":{
           "network": "ws",
           "wsSettings": {
               "path": "/trojan-ws"
            }
         }
     },
    {
         "listen": "127.0.0.1",
        "port": "10004",
        "protocol": "shadowsocks",
        "settings": {
           "clients": [
           {
           "method": "aes-128-gcm",
          "password": "${uuid}"
#ssws
           }
          ],
          "network": "tcp,udp"
       },
       "streamSettings":{
          "network": "ws",
             "wsSettings": {
               "path": "/ss-ws"
           }
        }
     },	
      {
        "listen": "127.0.0.1",
     "port": "10005",
        "protocol": "vless",
        "settings": {
         "decryption":"none",
           "clients": [
             {
               "id": "${uuid}"
#vlessgrpc
             }
          ]
       },
          "streamSettings":{
             "network": "grpc",
             "grpcSettings": {
                "serviceName": "vless-grpc"
           }
        }
     },
     {
      "listen": "127.0.0.1",
     "port": "10006",
     "protocol": "vmess",
      "settings": {
            "clients": [
               {
                 "id": "${uuid}",
                 "alterId": 0
#vmessgrpc
             }
          ]
       },
       "streamSettings":{
         "network": "grpc",
            "grpcSettings": {
                "serviceName": "vmess-grpc"
          }
        }
     },
     {
        "listen": "127.0.0.1",
     "port": "10007",
        "protocol": "trojan",
        "settings": {
          "decryption":"none",
             "clients": [
               {
                 "password": "${uuid}"
#trojangrpc
               }
           ]
        },
         "streamSettings":{
         "network": "grpc",
           "grpcSettings": {
               "serviceName": "trojan-grpc"
         }
      }
   },
   {
    "listen": "127.0.0.1",
    "port": "10008",
    "protocol": "shadowsocks",
    "settings": {
        "clients": [
          {
             "method": "aes-128-gcm",
             "password": "${uuid}"
#ssgrpc
           }
         ],
           "network": "tcp,udp"
      },
    "streamSettings":{
     "network": "grpc",
        "grpcSettings": {
           "serviceName": "ss-grpc"
          }
       }
    }	
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
      "StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true,
      "statsOutboundUplink" : true,
      "statsOutboundDownlink" : true
    }
  }
}
END
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service
cat <<EOF> /etc/systemd/system/xray.service
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF
cat > /etc/systemd/system/runn.service <<EOF
[Unit]
Description=casper9
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

#nginx config
wget -O /etc/nginx/conf.d/xray.conf "${REPO}xray/xray.conf"
wget -O /etc/haproxy/haproxy.cfg "${REPO}xray/haproxy.cfg"
sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg
cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/haproxy/hap.pem
chmod 600 /etc/haproxy/hap.pem
wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" >/dev/null 2>&1
wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" >/dev/null 2>&1
echo -e "$yell[SERVICE]$NC Restart All service"
systemctl daemon-reload
sleep 0.5
echo -e "[ ${green}ok${NC} ] Enable & restart xray "
systemctl daemon-reload
if ! /usr/local/bin/xray run -test -config /etc/xray/config.json; then
  echo "Konfigurasi Xray tidak valid; layanan VPN tidak direstart."
  exit 1
fi
if ! nginx -t; then
  echo "Konfigurasi Nginx tidak valid; layanan VPN tidak direstart."
  exit 1
fi
if ! haproxy -c -f /etc/haproxy/haproxy.cfg; then
  echo "Konfigurasi HAProxy tidak valid; layanan VPN tidak direstart."
  exit 1
fi
systemctl enable xray
systemctl restart xray
if ! systemctl is-active --quiet xray; then
  echo "Xray gagal aktif setelah restart. Periksa: journalctl -u xray -n 50 --no-pager"
  exit 1
fi
systemctl restart nginx
if ! systemctl is-active --quiet nginx; then
  echo "Nginx gagal aktif setelah restart."
  exit 1
fi
systemctl enable haproxy
systemctl restart haproxy
if ! systemctl is-active --quiet haproxy; then
  echo "HAProxy gagal aktif setelah restart."
  exit 1
fi
systemctl enable runn
systemctl restart runn

sleep 0.5
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
yellow "xray/Vmess"
yellow "xray/Vless"

mv /root/domain /etc/xray/
if [ -f /root/scdomain ];then
rm /root/scdomain > /dev/null 2>&1
fi
clear
rm -r ins-xray.sh
