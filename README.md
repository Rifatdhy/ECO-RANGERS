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
    File ini berisi semua konfigurasi untuk API Anda, termasuk koneksi database.
    ```sh
    # Untuk Windows (Command Prompt atau PowerShell)
    copy .env.example .env

    # Untuk macOS/Linux
    cp .env.example .env
    ```
    > File `.env.example` sudah dikonfigurasi untuk menggunakan SQLite, jadi Anda tidak perlu mengubahnya lagi.

3.  **Instal Dependensi (PHP & Node.js):**
    Jalankan perintah-perintah berikut secara berurutan.
    
    *   Instal dependensi PHP:
        ```sh
        composer install
        ```
    *   Instal dependensi Node.js:
        ```sh
        npm install
        ```
    *   Build aset frontend:
        ```sh
        npm run build
        ```

4.  **Hasilkan Kunci Aplikasi:**
    Setiap aplikasi Laravel membutuhkan kunci enkripsi yang unik.
    ```sh
    php artisan key:generate
    ```

5.  **Buat File Database SQLite:**
    Buat file kosong yang akan menjadi database Anda.

    *   **Opsi 1: Otomatis (PowerShell di Windows):**
        ```powershell
        New-Item -ItemType File -Path database\database.sqlite
        ```

    *   **Opsi 2: Manual:**
        Masuk ke folder `eco-rangers-api/database/` dan buat file baru bernama `database.sqlite`.

6.  **Jalankan Migrasi & Seeding Database:**
    Perintah ini akan membuat semua tabel yang dibutuhkan dan mengisinya dengan data awal (seperti akun admin).
    ```sh
    php artisan migrate --seed
    ```

7.  **Jalankan Server API:**
    Sekarang API Anda siap dijalankan.
    ```sh
    php artisan serve --host=0.0.0.0
    ```
    > Biarkan terminal ini tetap berjalan. API Anda sekarang aktif dan dapat diakses di port 8000.

<a name="frontend"></a>
### Frontend (Aplikasi Flutter)

Sekarang mari kita siapkan aplikasi selulernya. Buka **terminal baru** dan pastikan Anda berada di direktori root `eco_rangers`.

1.  **Buat File Environment (`.env`):**
    Sama seperti backend, aplikasi Flutter juga butuh file `.env` untuk mengetahui alamat API.
    ```sh
    # Untuk Windows
    copy .env.example .env

    # Untuk macOS/Linux
    cp .env.example .env
    ```

2.  **Konfigurasi Alamat API:**
    Buka file `.env` yang baru Anda buat, dan sesuaikan nilai `API_BASE_URL` dengan target platform Anda.
    
    | Target Platform                                | Baris Konfigurasi di File `.env`                    |
    | ---------------------------------------------- | --------------------------------------------------- |
    | **Web (Chrome)** atau **Aplikasi Desktop**     | `API_BASE_URL=http://127.0.0.1:8000`                |
    | **Emulator Android**                           | `API_BASE_URL=http://10.0.2.2:8000`                 |
    | **Perangkat Fisik** atau **Simulator iOS**     | `API_BASE_URL=http://<IP-LOKAL-ANDA>:8000`          |

    <details>
    <summary>❓ <strong>Bagaimana cara menemukan IP Lokal saya?</strong></summary>
    
    *   **Di Windows:** Buka **Command Prompt** dan ketik `ipconfig`. Cari alamat `IPv4 Address`.
    *   **Di macOS/Linux:** Buka **Terminal** dan ketik `ifconfig` atau `ip addr`. Cari alamat `inet`.
    
    </details>

3.  **Instal Dependensi Flutter:**
    ```sh
    flutter pub get
    ```

4.  **Jalankan Aplikasi Flutter:**
    Pastikan Anda memiliki target (emulator, perangkat, atau web) yang berjalan, lalu jalankan:
    ```sh
    flutter run
    ```

---

## 🚨 Troubleshooting

*   **`npm` atau `node` is not recognized:**
    Ini berarti Node.js tidak terinstal atau tidak ada di PATH sistem Anda. Instal Node.js versi **LTS** dari [nodejs.org](https://nodejs.org/) dan pastikan opsi "Add to PATH" diaktifkan saat instalasi. Jangan lupa untuk membuka ulang terminal setelahnya.

*   **Error Migrasi: `no such table: migrations` atau sejenisnya:**
    Ini biasanya terjadi jika Anda lupa membuat file `database.sqlite` (langkah #5 di bagian backend) sebelum menjalankan `php artisan migrate`.

*   **"Connection refused" di Perangkat Fisik:**
    1.  Pastikan server API berjalan dengan `php artisan serve --host=0.0.0.0`.
    2.  Pastikan ponsel dan komputer Anda terhubung ke jaringan **Wi-Fi yang sama**.
    3.  Periksa **Firewall** di komputer Anda. Mungkin Anda perlu menambahkan aturan untuk mengizinkan koneksi masuk pada port 8000.
    4.  Pastikan IP di file `.env` aplikasi Flutter sudah benar.

---

## 🤝 Berkontribusi

Kami sangat terbuka untuk kontribusi! Jika Anda ingin membantu, silakan *fork* repositori ini dan buat *pull request*.

1.  Fork repositori ini.
2.  Buat branch baru (`git checkout -b fitur/NamaFiturAnda`).
3.  Commit perubahan Anda (`git commit -m 'feat: Menambahkan Fitur Keren'`).
4.  Push ke branch tersebut (`git push origin fitur/NamaFiturAnda`).
5.  Buka Pull Request.
