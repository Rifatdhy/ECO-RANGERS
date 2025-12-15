# 🌍 Eco Rangers

Selamat datang di Eco Rangers! Sebuah proyek aplikasi seluler yang dirancang untuk **[Jelaskan secara singkat apa fungsi aplikasi Anda di sini, misalnya: melacak aktivitas daur ulang dan memberikan edukasi lingkungan]**.

Proyek ini dibangun dengan Flutter untuk frontend dan Laravel untuk backend. Panduan ini akan membantu Anda menjalankan proyek ini di lingkungan pengembangan lokal Anda.

---

## 📚 Daftar Isi

*   [Struktur Proyek](#-struktur-proyek)
*   [Prasyarat](#-prasyarat)
*   [Langkah-Langkah Instalasi](#-langkah-langkah-instalasi)
    *   [Backend (Laravel API)](#backend)
    *   [Frontend (Aplikasi Flutter)](#frontend)
*   [Troubleshooting](#-troubleshooting)
*   [Berkontribusi](#-berkontribusi)
*   [Lisensi](#-lisensi)

---

## 📂 Struktur Proyek

```
/eco_rangers
├── eco-rangers-api/      # Direktori backend (Laravel API)
├── lib/                  # Kode sumber aplikasi Flutter
└── README.md             # File panduan yang sedang Anda baca
```

## ✅ Prasyarat

Pastikan semua perangkat lunak berikut telah terinstal di sistem Anda.

| Perangkat Lunak     | Perintah Cek Versi          | Catatan                                      |
| ------------------- | --------------------------- | -------------------------------------------- |
| **Git**             | `git --version`             | Untuk mengkloning repositori.                |
| **Flutter SDK**     | `flutter --version`         | Disarankan versi 3.x.x atau lebih tinggi.      |
| **PHP**             | `php --version`             | Disarankan versi 8.1 atau lebih tinggi.      |
| **Composer**        | `composer --version`        | Manajer dependensi untuk PHP.              |
| **Node.js & npm**   | `node --version` `npm --version` | Untuk mengelola aset frontend Laravel. |

---

## ⚙️ Langkah-Langkah Instalasi

<a name="backend"></a>
### Backend (Laravel API)

Langkah-langkah ini akan menyiapkan server API lokal Anda.
> **💡 Kabar baik!** Database sudah disertakan dalam repositori ini, jadi Anda tidak perlu membuat atau memigrasi database secara manual.

1.  **Masuk ke Direktori API:**
    ```sh
    cd eco-rangers-api
    ```

2.  **Buat File Environment (`.env`):**
    ```sh
    # Untuk macOS/Linux
    cp .env.example .env
    
    # Untuk Windows
    copy .env.example .env
    ```

3.  **Instal Dependensi (PHP & Node.js):**
    ```sh
    composer install && npm install && npm run build
    ```

4.  **Hasilkan Kunci Aplikasi:**
    ```sh
    php artisan key:generate
    ```

5.  **(Opsional) Isi Database dengan Data Contoh:**
    ```sh
    php artisan db:seed
    ```

6.  **Jalankan Server API:**
    Jalankan perintah ini untuk membuat API dapat diakses dari perangkat lain di jaringan Anda.
    ```sh
    php artisan serve --host=0.0.0.0
    ```
    > Biarkan terminal ini tetap berjalan. API Anda sekarang aktif dan mendengarkan koneksi di port 8000.

<a name="frontend"></a>
### Frontend (Aplikasi Flutter)

Sekarang mari kita siapkan aplikasi selulernya. Buka **terminal baru** untuk langkah-langkah ini.

1.  **Instal Dependensi Flutter:**
    (Pastikan Anda berada di direktori root `eco_rangers`)
    ```sh
    flutter pub get
    ```

2.  **Konfigurasi Alamat IP API:**
    Ini adalah langkah **paling penting**. Aplikasi Flutter perlu tahu alamat server API Anda. Pilih alamat yang sesuai dengan target Anda:

    | Target Platform                                | Alamat API yang Digunakan                   |
    | ---------------------------------------------- | ------------------------------------------- |
    | **Web (Chrome)** atau **Aplikasi Desktop**     | `http://127.0.0.1:8000`                     |
    | **Emulator Android**                           | `http://10.0.2.2:8000`                      |
    | **Perangkat Fisik** atau **Simulator iOS**     | `http://<IP-LOKAL-ANDA>:8000`               |

    <details>
    <summary>❓ <strong>Bagaimana cara menemukan IP Lokal saya?</strong></summary>
    
    *   **Di Windows:** Buka **Command Prompt** dan ketik `ipconfig`. Cari alamat `IPv4 Address`.
    *   **Di macOS/Linux:** Buka **Terminal** dan ketik `ifconfig` atau `ip addr`. Cari alamat `inet`.
    
    </details>

3.  **Jalankan Aplikasi Flutter:**
    Pastikan Anda memiliki target (emulator, perangkat, atau web) yang berjalan, lalu jalankan:
    ```sh
    flutter run
    ```

---

## 🚨 Troubleshooting

*   **"Connection refused" di Perangkat Fisik:**
    1.  Pastikan server API berjalan dengan perintah `php artisan serve --host=0.0.0.0`.
    2.  Pastikan ponsel dan komputer Anda terhubung ke jaringan **Wi-Fi yang sama**.
    3.  Periksa **Firewall** di komputer Anda. Mungkin Anda perlu menambahkan aturan untuk mengizinkan koneksi masuk pada port 8000.

---

## 🤝 Berkontribusi

Kami sangat terbuka untuk kontribusi! Jika Anda ingin membantu, silakan *fork* repositori ini dan buat *pull request*.

1.  Fork repositori ini.
2.  Buat branch baru (`git checkout -b fitur/NamaFiturAnda`).
3.  Commit perubahan Anda (`git commit -m 'feat: Menambahkan Fitur Keren'`).
4.  Push ke branch tersebut (`git push origin fitur/NamaFiturAnda`).
5.  Buka Pull Request.

---

