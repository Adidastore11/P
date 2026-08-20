#!/bin/bash

# Update package list dan install unzip jika belum ada
apt update -y
apt install -y unzip wget

# Mengunduh dan mengekstrak menu.zip
wget -q https://raw.githubusercontent.com/Adidastore11/P/main/menu/menu.zip -O menu.zip
unzip menu.zip
chmod +x menu/*
mv menu/* /usr/local/sbin
rm -rf menu menu.zip

# Menu change-domain selalu diambil dari source terbaru agar hostname API ikut tersinkron.
wget -q -O /usr/local/sbin/addhost https://raw.githubusercontent.com/Adidastore11/P/main/menu/menu/addhost
chmod +x /usr/local/sbin/addhost
wget -q -O /usr/local/sbin/fixcert https://raw.githubusercontent.com/Adidastore11/P/main/menu/menu/fixcert
chmod +x /usr/local/sbin/fixcert

# Mengunduh versionbaru dan menggantinya menjadi "version"
wget -q https://raw.githubusercontent.com/Adidastore11/P/main/versionbaru -O /usr/local/sbin/version
chmod +x /usr/local/sbin/version
