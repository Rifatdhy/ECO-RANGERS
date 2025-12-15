# 🌍 Eco Rangers

Selamat datang di Eco Rangers! Sebuah proyek aplikasi seluler yang dirancang untuk **[Jelaskan secara singkat apa fungsi aplikasi Anda di sini, misalnya: melacak aktivitas daur ulang dan memberikan edukasi lingkungan]**.

Proyek ini dibangun dengan Flutter untuk frontend dan Laravel untuk backend. Panduan ini akan membantu Anda menjalankan proyek ini di lingkungan pengembangan lokal Anda.

---

## 📚 Daftar Isi

*   [Struktur Proyek](#-struktur-proyek)
*   [Prasyarat](#-prasyarat)
*   [Langkah-Langkah Instalasi](#️-langkah-langkah-instalasi)
    *   [Backend (Laravel API)](#backend)
    *   [Frontend (Aplikasi Flutter)](#frontend)
*   [Troubleshooting](#-troubleshooting)
*   [Berkontribusi](#-berkontribusi)

---

## 📂 Struktur Proyek

```
/eco_rangers
├── .env.example          # Contoh file environment untuk Flutter
├── eco-rangers-api/      # Direktori backend (Laravel API)
│   ├── .env.example      # Contoh file environment untuk Laravel
│   └── database/
│       └── database.sqlite   # File database (dibuat saat instalasi)
├── lib/                  # Kode sumber aplikasi Flutter
└── README.md             # File panduan yang sedang Anda baca
```

## ✅ Prasyarat

Pastikan semua perangkat lunak berikut telah terinstal di sistem Anda. Jika belum, silakan unduh dan instal dari tautan yang disediakan.

| Perangkat Lunak     | Tautan Unduh / Instalasi                                         | Perintah Cek Versi          |
| ------------------- | ---------------------------------------------------------------- | --------------------------- |
| **Git**             | [git-scm.com/downloads](https://git-scm.com/downloads)           | `git --version`             |
| **Flutter SDK**     | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) | `flutter --version`         |
| **PHP**             | [php.net/downloads](https://www.php.net/downloads)               | `php --version`             |
| **Composer**        | [getcomposer.org/download](https://getcomposer.org/download)     | `composer --version`        |
| **Node.js & npm**   | [nodejs.org](https://nodejs.org/) (Unduh versi **LTS**) | `node -v` dan `npm -v` |

> **PENTING untuk Node.js:** Saat menginstal di Windows, pastikan Anda membiarkan opsi **"Add to PATH"** tetap aktif (default) agar perintah `npm` dapat dikenali di terminal. Setelah instalasi, **tutup dan buka kembali terminal Anda**.

---

## ⚙️ Langkah-Langkah Instalasi

<a name="backend"></a>
### Backend (Laravel API)

Langkah-langkah ini akan menyiapkan server API lokal Anda dari awal.

1.  **Masuk ke Direktori API:**
    ```sh
    cd eco-rangers-api
    ```

2.  **Buat File Environment (`.env`):**
    ```sh
    copy .env.example .env
    ```

3.  **Instal Dependensi (PHP & Node.js):**
    *   Instal dependensi PHP: `composer install`
    *   Instal dependensi Node.js: `npm install`
    *   Build aset frontend: `npm run build`

4.  **Hasilkan Kunci Aplikasi & Bersihkan Cache:**
    ```sh
    php artisan key:generate
    php artisan config:clear
    php artisan cache:clear
    ```

5.  **Buat File Database SQLite:**
    Gunakan perintah ini di PowerShell.
    ```powershell
    New-Item -ItemType File -Path database\database.sqlite
    ```

6.  **Jalankan Migrasi & Seeding Database:**
    *   Buat tabel database: `php artisan migrate`
    *   Isi dengan data awal: `php artisan db:seed`

7.  **Jalankan Server API:**
    ```sh
    php artisan serve --host=0.0.0.0
    ```
    > Biarkan terminal ini tetap berjalan. API Anda sekarang aktif di port 8000.

<a name="frontend"></a>
### Frontend (Aplikasi Flutter)

Buka **terminal baru** dan pastikan Anda berada di direktori root `eco_rangers`.

1.  **Buat File Environment (`.env`):**
    ```sh
    copy .env.example .env
    ```

2.  **Konfigurasi Alamat API:**
    Buka file `.env` dan sesuaikan `API_BASE_URL` dengan target platform Anda.

3.  **Instal Dependensi Flutter:**
    ```sh
    flutter pub get
    ```

4.  **Jalankan Aplikasi Flutter:**
    Pastikan target (emulator, perangkat, atau web) berjalan, lalu jalankan:
    ```sh
    flutter run
    ```

---

## 🚨 Troubleshooting

*   **`npm`, `node`, atau `composer` is not recognized:**
    Ini berarti perangkat lunak tersebut tidak terinstal atau tidak ada di PATH sistem. Instal dari tautan di tabel **Prasyarat** dan pastikan untuk mengaktifkan "Add to PATH" saat instalasi. Jangan lupa membuka ulang terminal.

*   **Error Migrasi Laravel (mis: `could not find driver`):**
    Ini biasanya berarti ekstensi PHP untuk SQLite belum aktif. Cari file `php.ini` Anda dan hapus tanda titik koma (`;`) di depan baris `extension=sqlite3` dan `extension=pdo_sqlite`, lalu restart server Anda jika ada.

*   **"Connection refused" di Perangkat Fisik:**
    1.  Pastikan server API berjalan dengan `php artisan serve --host=0.0.0.0`.
    2.  Pastikan ponsel dan komputer terhubung ke jaringan **Wi-Fi yang sama**.
    3.  Periksa **Firewall** di komputer Anda (izinkan koneksi masuk port 8000).
    4.  Pastikan IP di file `.env` aplikasi Flutter sudah benar.

---

## 🤝 Berkontribusi

Kami sangat terbuka untuk kontribusi! Jika Anda ingin membantu, silakan *fork* repositori ini dan buat *pull request*.
