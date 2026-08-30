# 🌱 Eco Rangers

**Eco Rangers** adalah aplikasi pelaporan masalah lingkungan yang memungkinkan pengguna untuk melaporkan, memantau, dan menindaklanjuti isu-isu lingkungan secara real-time. Terdiri dari aplikasi **Flutter** (Android / iOS / Web) dan backend **Laravel** (REST API).

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 📸 **Laporan + Foto** | Laporkan masalah lingkungan lengkap dengan foto (auto-resize) dan lokasi GPS |
| 🏷️ **Kategori Laporan** | Sampah, Pencemaran, Infrastruktur, Fauna, Flora, Lainnya — filter & statistik per kategori |
| 🗺️ **Peta Interaktif** | Peta `flutter_map` dengan marker berwarna-status, klik marker → detail & Google Maps |
| 📊 **Status Real-time** | Pantau status laporan: Pending, Diproses, Selesai, Ditolak + riwayat progres beranimasi |
| 🔔 **Notifikasi In-App** | Badge & halaman notifikasi saat status laporan berubah |
| 👍 **Upvote Isu** | Warga mendukung laporan; count + badge (protected dari IDOR & spam) |
| 👤 **Autentikasi** | Register/Login (token aman via Sanctum), role khusus admin |
| 🛡️ **Dashboard Admin** | 4 kartu statistik beranimasi, tren 7 hari, donut kategori, waktu tanggap, pencarian server-side, **export CSV** |
| ✅ **Konfirmasi Penyelesaian** | Pelapor menobatkan "Sesuai" / "Belum Tuntas" saat laporan selesai |
| 📱 **Desain Modern** | Tema ala iOS, frosted glass, dark mode otomatis, angka count-up (inspirasi 21st.dev) |
| 🌗 **Dark Mode** | Ikut mode gelap/terang perangkat (`ThemeMode.system`) |

---

## 🧱 Teknologi

### Frontend (Flutter)
- **Flutter** — Cross-platform (Android, iOS, Web)
- **GetIt** — Dependency injection
- **flutter_secure_storage** — Token & sesi tersimpan aman (native keystore); di web memakai SharedPreferences
- **http + Multipart** — REST API & upload
- **cached_network_image** — Cache gambar laporan
- **flutter_map + latlong2** — Peta interaktif dengan marker status
- **fl_chart** — Grafik tren & donut kategori di dashboard admin
- **DevicePreview** — Preview responsif saat debugging
- **Inter (font lokal)** — Font weights 400–800 di-bundle (tanpa fetch runtime, mirip SF Pro)

### Backend (Laravel API)
- **Laravel 12** — Framework PHP
- **Sanctum** — Personal access token dengan abilities (`role:user` / `role:admin`)
- **SQLite** (dev) / **MySQL** (produksi)
- **Sentry** — Error tracking (opsional, via env)
- **Rate limiting & token expiry** bawaan (7 hari default)

---

## 📂 Struktur Proyek

```
ECO-RANGERS/
├── lib/                          # Aplikasi Flutter
│   ├── main.dart                 # Entry point + navigator key global
│   ├── config.dart               # Konfigurasi API URL
│   ├── session.dart              # Penanganan sesi expired (auto re-auth)
│   ├── locator.dart              # Dependency injection (GetIt)
│   ├── models/                   # User, Laporan, ReportUpdate
│   ├── pages/                    # Splash, Auth, Home, Map, BuatLaporan,
│   │                             #   Activity, Profile, DashboardAdmin,
│   │                             #   LaporanDetail, UpdateStatus, PhotoViewer
│   ├── services/                 # api_client.dart, auth_service.dart
│   ├── ui/                       # app_theme.dart (tema iOS), tokens,
│   │   └── widgets/              #   status_badge, report_card, state_views, ...
│   └── utils/                    # image_utils.dart (resize sebelum upload)
├── eco-rangers-api/              # Backend Laravel
│   ├── app/Http/Controllers/     # Auth, AdminAuth, Api/Report
│   ├── app/Models/               # User, Report, ReportUpdate
│   ├── database/migrations/      # Migrasi (order sudah dinormalisasi)
│   ├── database/seeders/         # AdminUserSeeder + factory users
│   ├── routes/api.php            # Semua endpoint API
│   └── config/                   # CORS, Sanctum, dll
├── test/                         # Unit/widget test Flutter
├── integration_test/             # Integration test Flutter
└── .github/workflows/            # CI: flutter.yml + backend.yml
```

---

## 🚀 Instalasi Lokal

### Prasyarat

| Tools | Versi Minimal |
|-------|---------------|
| PHP | >= 8.2 |
| Composer | latest |
| Flutter SDK | 3.x (Dart 3.9+) |
| Database | SQLite (default) / MySQL |

### 1. Setup Backend (Laravel API)

```bash
cd eco-rangers-api

composer install
cp .env.example .env

# Sesuaikan .env bila perlu (default: SQLite)
php artisan key:generate

# Migrasi + seeder (membuat admin & 10 user testing)
php artisan migrate --seed

# Link penyimpanan publik untuk foto laporan
php artisan storage:link

php artisan serve --port=8000
```

> Gunakan `--host=0.0.0.0` bila ingin diakses emulator/HP lain dalam jaringan.
> Kredensial admin default ada di section [Akun Default](#-akun-default-testing).

### 2. Setup Frontend (Flutter)

```bash
cd ..
flutter pub get

# Buat file .env di root (sejajar pubspec.yaml)
```

**Isi `.env`:**

```env
API_BASE_URL=http://127.0.0.1:8000        # Desktop / emulator AVD (host)
# API_BASE_URL=http://10.0.2.2:8000       # Android Emulator
# API_BASE_URL=http://192.168.1.X:8000    # HP Fisik (IP laptop)
# API_BASE_URL=https://api.ecorangers.com # Produksi (HTTPS wajib)
```

```bash
flutter run                    # pilih device
flutter run -d chrome          # jalankan di browser
```

> Token berumur 7 hari (default). Saat expired semua permintaan 401 akan
> otomatis menghapus sesi dan membawa user ke halaman login.

---

## 🔑 Akun Default (Testing)

Untuk KINERJA `php artisan migrate --seed`:

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `admin@gmail.com` | `12345678` |

Admin dibuat dengan `is_admin = true`. Ganti via env:

```env
ADMIN_EMAIL=admin@domain.com
ADMIN_PASSWORD=password-kuat-anda
```

> **Keamanan:** di environment **produksi**, seeder akan menolak password default. Atur `ADMIN_PASSWORD` dengan string acak kuat di `.env.production.example` (disalin ke `.env` di server).

---

## 🧪 Testing

### Backend

```bash
cd eco-rangers-api
php artisan test
```

### Flutter

```bash
flutter test                # unit & widget
flutter test integration_test/   # integration (butuh device)
```

### CI
`push` / `pull_request` ke `main`/`master` menjalankan:
- `.github/workflows/backend.yml` — PHP 8.2–8.4, lint + test
- `.github/workflows/flutter.yml` — analyze + test + build web

---

## 🔑 Endpoint API Utama

| Method | Path | Keterangan |
|--------|------|-----------|
| POST | `/api/register` | Daftar pengguna baru |
| POST | `/api/login` | Login (token sesuai role) |
| POST | `/api/admin/login` | Login admin khusus (opsional) |
| GET/POST | `/api/me`, `/api/logout` | Profil & keluar |
| GET | `/api/reports?status=&limit=&offset=` | List laporan (admin semua, user miliknya) |
| POST | `/api/reports` | Buat laporan (multipart: judul, deskripsi, lokasi, foto) |
| PATCH/POST | `/api/reports/{id}/status` | Ubah status + update progres (admin) |
| DELETE | `/api/reports/{id}` | Hapus laporan (admin) |
| GET | `/api/files/{path}` | Proxy akses file foto |

---

## ⚙️ Konfigurasi Produksi

- **HTTPS wajib** — release build tidak memperbolehkan cleartext traffic (debug hanya untuk local).
- Siapkan `.env.production.example` → `.env` di server (MySQL, `APP_DEBUG=false`, CORS terbatas via `CORS_ALLOWED_ORIGINS`, admin password kuat, DSN Sentry).
- Pakai pekerja queue & cache aktiv: `QUEUE_CONNECTION=database` dan aktifkan `queue:work`.

---

## 🤝 Kontribusi

1. Fork repositori
2. Branch fitur: `git checkout -b fitur-keren`
3. Commit: `git commit -m 'Menambahkan fitur keren'`
4. Push: `git push origin fitur-keren`
5. Buat Pull Request

---

## 📄 Lisensi

Hak cipta © 2026 Eco Rangers. Didistribusikan di bawah lisensi MIT.

---

<p align="center">Dibuat dengan ❤️ untuk lingkungan yang lebih baik</p>