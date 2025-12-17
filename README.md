# Eco Rangers 🌱

Eco Rangers adalah aplikasi pelaporan masalah lingkungan berbasis mobile. Proyek ini terdiri dari aplikasi mobile (Flutter) dan backend API (Laravel).

## 📂 Struktur Proyek

Proyek ini menggunakan struktur monorepo dimana kode Frontend dan Backend berada dalam satu repositori utama:

*   **Root Folder (`/`)**: Berisi source code aplikasi Mobile **Flutter**.
*   **Folder API (`/eco-rangers-api`)**: Berisi source code Backend **Laravel**.

---

## 🛠 Prasyarat (Requirements)

Pastikan perangkat Anda telah terinstal:
*   **PHP** >= 8.2 & **Composer**
*   **Flutter SDK** (Versi 3.x)
*   **Android Studio** / VS Code
*   **Database** (MySQL atau SQLite)

---

## 🚀 Panduan Instalasi & Menjalankan

### 1. Setup Backend (Laravel API)

Backend menangani database, autentikasi, dan penyimpanan file.

1.  Masuk ke folder API:
    ```bash
    cd eco-rangers-api
    ```

2.  Install dependencies:
    ```bash
    composer install
    ```

3.  Konfigurasi Environment:
    *   Salin file contoh `.env`:
        ```bash
        cp .env.example .env
        ```
    *   Buka file `.env` dan atur koneksi database (DB_DATABASE, DB_USERNAME, dll).
    *   Generate Application Key:
        ```bash
        php artisan key:generate
        ```

4.  Migrasi Database:
    ```bash
    php artisan migrate
    ```
    *(Opsional) Jika ingin data dummy dan akun admin bawaan:*
    ```bash
    php artisan migrate --seed
    ```

5.  Jalankan Server:
    ```bash
    php artisan serve --host=0.0.0.0 --port=8000
    ```
    > **Catatan:** Menggunakan `0.0.0.0` penting agar API bisa diakses dari Emulator atau HP fisik dalam jaringan yang sama.

### 2. Setup Frontend (Flutter Mobile)

1.  Kembali ke root folder:
    ```bash
    cd ..
    ```

2.  Install dependencies Flutter:
    ```bash
    flutter pub get
    ```

3.  **PENTING: Konfigurasi Koneksi (.env)**
    Buat file `.env` di root folder (sejajar dengan `pubspec.yaml`), lalu isi dengan URL API Anda:

    *   **Jika menggunakan Android Emulator:**
        ```env
        API_BASE_URL=http://10.0.2.2:8000
        ```
    *   **Jika menggunakan HP Fisik (Debugging USB):**
        Gunakan IP address laptop Anda (cek dengan `ipconfig` atau `ifconfig`).
        ```env
        API_BASE_URL=http://192.168.1.X:8000
        ```

4.  Jalankan Aplikasi:
    ```bash
    flutter run
    ```

---

## 🔑 Akun Default (Testing)

Jika Anda menjalankan *seeding* atau menggunakan rute testing, berikut adalah akun admin default:

*   **Email:** `admin@gmail.com`
*   **Password:** `12345678`

---

## 🧪 Testing

### Backend Tests
Proyek ini dilengkapi dengan Feature Test dan Browser Test (Laravel Dusk).

```bash
cd eco-rangers-api
php artisan test
```

### Frontend Debugging
Aplikasi menggunakan `DevicePreview` untuk memudahkan pengembangan UI responsif. Fitur ini aktif secara default di mode debug.

---

## 📝 Catatan Penting

*   **Gambar & File:** Aplikasi menggunakan sistem proxy (`/api/files/{path}`) untuk memuat gambar. Pastikan folder `storage/app/public` di Laravel telah di-link:
    ```bash
    cd eco-rangers-api
    php artisan storage:link
    ```
*   **Izin Akses:** Pada Android, pastikan izin Lokasi dan Kamera/Galeri diberikan saat aplikasi meminta.
