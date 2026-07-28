# 🌱 Eco Rangers

**Eco Rangers** adalah aplikasi pelaporan masalah lingkungan berbasis mobile yang memungkinkan pengguna untuk melaporkan, memantau, dan menindaklanjuti isu-isu lingkungan secara real-time. Proyek ini terdiri dari aplikasi mobile (Flutter) dan backend API (Laravel).

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 📸 **Laporan + Foto** | Laporkan masalah lingkungan lengkap dengan foto dan lokasi |
| 🔍 **Pencarian & Filter** | Cari laporan berdasarkan judul/deskripsi, filter berdasarkan status |
| 📊 **Status Real-time** | Pantau status laporan: Pending, Diproses, Selesai, Ditolak |
| 👤 **Autentikasi** | Login/Register untuk pengguna, role khusus untuk admin |
| 🛡️ **Dashboard Admin** | Kelola semua laporan, ubah status, dan kelola pengguna |
| 📱 **Responsif** | Tampilan optimal di berbagai ukuran layar mobile |

---

## 🧱 Teknologi

### Frontend (Mobile)
- **Flutter** — Framework UI cross-platform
- **Dart** — Bahasa pemrograman
- **Provider / GetIt** — Manajemen state & dependency injection
- **SharedPreferences** — Penyimpanan lokal token & sesi
- **DevicePreview** — Preview responsif saat debugging

### Backend (API)
- **Laravel 11** — Framework PHP
- **SQLite / MySQL** — Database
- **Sanctum** — Autentikasi API token
- **Laravel Dusk** — Browser testing

---

## 📂 Struktur Proyek

```
ECO-RANGERS/
├── lib/                          # Aplikasi Flutter
│   ├── main.dart                 # Entry point aplikasi
│   ├── config.dart               # Konfigurasi API URL
│   ├── locator.dart              # Dependency injection (GetIt)
│   ├── models/                   # Model data (User, Laporan)
│   ├── pages/                    # Halaman aplikasi
│   │   ├── auth_page.dart        # Halaman login/register
│   │   ├── dashboard_user_page.dart  # Dashboard user
│   │   ├── buat_laporan_page.dart    # Form laporan baru
│   │   └── laporan_detail_page.dart  # Detail laporan
│   ├── services/                 # Service layer
│   │   ├── api_client.dart       # HTTP client utama
│   │   ├── auth_service.dart     # Autentikasi
│   │   └── report_api.dart       # API laporan
│   └── ui/                       # Tema & komponen UI
│       └── app_theme.dart        # Tema kustom
├── eco-rangers-api/              # Backend Laravel
│   ├── app/Http/Controllers/     # Controller API
│   ├── app/Models/               # Model Eloquent
│   ├── database/migrations/      # Migrasi database
│   ├── database/seeders/         # Seeder data awal
│   └── routes/api.php            # Rute API
├── test/                         # Unit test Flutter
├── integration_test/             # Integration test Flutter
└── features/                     # BDD feature files
```

---

## 🚀 Panduan Instalasi

### Prasyarat

| Tools | Versi Minimal |
|-------|---------------|
| PHP | >= 8.2 |
| Composer | latest |
| Flutter SDK | 3.x |
| Database | SQLite / MySQL |

---

### 1. Setup Backend (Laravel API)

```bash
# Masuk ke folder API
cd eco-rangers-api

# Install dependencies PHP
composer install

# Konfigurasi environment
cp .env.example .env
# Edit file .env sesuai database Anda

# Generate application key
php artisan key:generate

# Migrasi database (dengan seeder untuk akun default)
php artisan migrate --seed

# Buat symbolic link untuk penyimpanan file
php artisan storage:link

# Jalankan server
php artisan serve --host=0.0.0.0 --port=8000
```

> **Catatan:** Gunakan `--host=0.0.0.0` agar API bisa diakses dari emulator atau HP fisik dalam jaringan yang sama.

---

### 2. Setup Frontend (Flutter)

```bash
# Kembali ke root folder
cd ..

# Install dependencies Flutter
flutter pub get

# Konfigurasi koneksi API
# Buat file .env di root folder (sejajar dengan pubspec.yaml)
```

**Isi file `.env`:**

```env
# Untuk Android Emulator
API_BASE_URL=http://10.0.2.2:8000

# Untuk HP Fisik (gunakan IP laptop Anda)
API_BASE_URL=http://192.168.1.X:8000
```

```bash
# Jalankan aplikasi
flutter run
```

---

## 🔑 Akun Default (Testing)

Setelah menjalankan `php artisan migrate --seed`, akun berikut tersedia:

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `admin@gmail.com` | `12345678` |
| **User** *(jika ada seeder)* | *(tergantung seeder)* | *(tergantung seeder)* |

---

## 🧪 Testing

### Backend (Laravel)

```bash
cd eco-rangers-api
php artisan test
```

### Frontend (Flutter)

```bash
# Unit test
flutter test

# Integration test
flutter test integration_test/
```

---

## 📝 Catatan Penting

### Gambar & File
Aplikasi menggunakan sistem proxy (`/api/files/{path}`) untuk memuat gambar. Pastikan folder storage telah di-link:

```bash
cd eco-rangers-api
php artisan storage:link
```

### Izin Aplikasi
Pada Android, pastikan izin berikut diberikan saat diminta:
- 📍 **Lokasi** — Untuk mengambil lokasi laporan
- 📷 **Kamera/Galeri** — Untuk mengunggah foto

### Koneksi API
Jika aplikasi tidak dapat terhubung ke API:
1. Pastikan server Laravel berjalan
2. Periksa alamat IP pada file `.env`
3. Pastikan perangkat dan server berada dalam jaringan yang sama
4. Nonaktifkan firewall jika perlu

---

## 🤝 Kontribusi

1. Fork repositori ini
2. Buat branch fitur baru: `git checkout -b fitur-keren`
3. Commit perubahan: `git commit -m 'Menambahkan fitur keren'`
4. Push ke branch: `git push origin fitur-keren`
5. Buat Pull Request

---

## 📄 Lisensi

Hak cipta © 2024 Eco Rangers. Didistribusikan di bawah lisensi MIT.

---

<p align="center">Dibuat dengan ❤️ untuk lingkungan yang lebih baik</p>