# VPN API

Installer membuat API ini otomatis pada setiap VPS baru.

- API hanya listen di `127.0.0.1:3000`.
- Akses publik datang melalui HTTPS hostname `api.<domain-vps>` di port 443.
- API key dibuat unik pada instalasi dan disimpan di `/etc/vpn-api/api.env` dengan permission terbatas.
- Semua endpoint membutuhkan header `X-API-Key`.
- Tidak ada CORS header; website harus memanggil API dari backend, bukan JavaScript browser.

Endpoint tersedia: `GET /health`, `POST /ssh`, `POST /ssh/delete`, `POST /ssh/renew`, `POST /v2ray`, `POST /v2ray/delete`, dan `POST /v2ray/renew`.

Format request kompatibel dengan panduan lama. Create SSH menggunakan `username`, `password`, `iplimit`, dan `duration`. Endpoint V2Ray menggunakan `type` (`vmess`, `vless`, atau `trojan`), `username`, `days`, `gb`, dan `ip`.
