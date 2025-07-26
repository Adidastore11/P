# root all vps

# 🛠️ andyroot.sh

Script ini digunakan untuk **setup akses root dan instalasi otomatis tools tertentu** seperti Xray dan konfigurasi domain di VPS Linux (Ubuntu/Debian).

---

## 🔽 Cara Menggunakan

### 1. Download & Jalankan Script

Salin dan jalankan perintah ini di terminal (Linux / VPS):

```bash
wget https://raw.githubusercontent.com/Andyyuda/P/main/andyroot.sh -O andyroot.sh
chmod +x andyroot.sh
./andyroot.sh
```

---

## 🌐 Tambahan: Install Langsung dengan Domain

Jika kamu ingin langsung menjalankan instalasi Xray dari GitHub lain dan menyetel domain:

### ✅ Custom Domain

```bash
curl -sSL https://raw.githubusercontent.com/Adidastore11/P/main/install.sh | bash && mkdir -p /etc/xray && echo "domainmu.com" > /etc/xray/domain
```

> 💡 **KLO MAU CUSTOM DOMAIN**  
> GANTI `domainmu.com` dengan domain milikmu yang aktif dan sudah diarahkan ke IP VPS.

---

### 🔁 Domain Random (Otomatis)

```bash
curl -sSL https://raw.githubusercontent.com/Adidastore11/P/main/install.sh | bash
```

> 💡 **DOMAIN RANDOM**  
> Cocok digunakan jika script sudah menangani domain otomatis atau tidak ingin mengatur domain manual.

---
