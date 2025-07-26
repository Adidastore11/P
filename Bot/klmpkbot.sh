#!/bin/bash
NS=$( cat /etc/xray/dns )
PUB=$( cat /etc/slowdns/server.pub )
domain=$(cat /etc/xray/domain)
#color
grenbo="\e[92;1m"
NC='\e[0m'
#install
cd /root
rm -rf regis
#install
apt update && apt upgrade
apt install python3 python3-pip git
cd /usr/bin
wget -O bot.zip https://raw.githubusercontent.com/Adidastore11/P/main/Bot/bot.zip
7z x bot.zip
mv bot/* /usr/bin
chmod +x /usr/bin/*
rm -rf bot.zip
cd /root
wget -O regis.zip https://raw.githubusercontent.com/Adidastore11/P/main/Bot/regis.zip
7z x regis.zip
rm -rf regis.zip
pip3 install -r regis/requirements.txt
pip3 install pillow

#isi data
echo ""
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m          ADD BOT PANEL          \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Creat Bot and ID Telegram${NC}"
echo -e "${grenbo}[*] Creat Bot and Token Bot : @BotFather${NC}"
echo -e "${grenbo}[*] Info Id Telegram : @MissRose_bot , perintah /info${NC}"
echo -e "${grenbo}[*] Bot By AndyYuda KLMPK PROJECT${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -e -p "[*] Input your Bot Token : " bottoken
read -e -p "[*] Input Your Id Telegram :" admin
echo -e BOT_TOKEN='"'$bottoken'"' >> /root/regis/var.txt
echo -e ADMIN='"'$admin'"' >> /root/regis/var.txt
echo -e DOMAIN='"'$domain'"' >> /root/regis/var.txt
echo -e PUB='"'$PUB'"' >> /root/regis/var.txt
echo -e HOST='"'$NS'"' >> /root/regis/var.txt
clear

# Create the andy script
cat >/usr/bin/andy <<EOF
#!/bin/bash
cd /root
python3.8 -m regis
EOF
chmod +x /usr/bin/andy

# Create the regis service
cat >/etc/systemd/system/regis.service <<EOF
[Unit]
Description=KLMPK BOT 
Documentation=KLMPKVPN
After=syslog.target network-online.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/bin/andy

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl start regis
systemctl enable regis

# Cleanup the installation script
rm -rf klmpkbot.sh

# Display bot data
echo "Done"
echo "Your Bot Data:"
echo -e "==============================="
echo "Bot Token        : $bottoken"
echo "Admin ID         : $admin"
echo "Domain           : $domain"
echo "Public Key       : $PUB"
echo "Host             : $NS"
echo -e "==============================="
echo "Setup complete"
clear

echo "Installations complete, type /menu or /sayang in your bot"
