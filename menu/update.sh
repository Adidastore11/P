#!/bin/bash

# Update package list dan install unzip jika belum ada
apt update -y
apt install -y unzip wget

# Mengunduh dan mengekstrak menu.zip
wget -q https://raw.githubusercontent.com/Adidastore11/P/main/menu/menu.zip -O menu.zip
unzip menu.zip
if [[ ! -f menu/addhost || ! -f menu/fixcert || ! -f menu/api-domain ]]; then
  echo "menu.zip tidak lengkap: addhost, fixcert, atau api-domain tidak ditemukan."
  exit 1
fi
chmod +x menu/*
mv menu/* /usr/local/sbin
rm -rf menu menu.zip

# Mengunduh versionbaru dan menggantinya menjadi "version"
wget -q https://raw.githubusercontent.com/Adidastore11/P/main/versionbaru -O /usr/local/sbin/version
chmod +x /usr/local/sbin/version
