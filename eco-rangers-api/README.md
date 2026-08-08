# 🌱 Eco Rangers API

Backend REST API untuk aplikasi **Eco Rangers** (pelaporan masalah lingkungan), dibangun dengan **Laravel 12** + **Sanctum**.

Klien utama: aplikasi Flutter di root repo `../`.

---

## ✨ Fitur

- **Autentikasi** — Register / Login / Logout via Sanctum personal access token
- **Role & Izin** — Kemampuan token `role:user` dan `role:admin` (dicek middleware `ability`)
- **Manajemen Laporan** — Buat, lihat (dengan filter status), ubah status + progres/dokumentasi, hapus
- **Upload Foto** — Foto laporan & foto dokumentasi petugas, disimpan di disk publik
- **Proxy File** — `/api/files/{path}` untuk akses foto dengan proteksi path traversal
- **Keamanan** — Rate limiting login (`THROTTLE_LOGIN`), token expiry 7 hari, CORS via env, guard password default di produksi
- **Error Tracking** — Sentry (opsional, via `SENTRY_LARAVEL_DSN`)
- **Berjalan di** — SQLite (dev) & MySQL (prod), siap CI (PHP 8.2–8.4)

---

## 📦 Kebutuhan

- PHP >= 8.2
- Composer
- SQLite (dev) atau MySQL (prod)

---

## 🚀 Setup

```bash
composer install
cp .env.example .env

# Konfigurasi database & env sesuai kebutuhan
php artisan key:generate

# Migrasi + seeder (membuat admin & 10 user)
php artisan migrate --seed

# Link disk publik agar foto bisa diakses
php artisan storage:link

php artisan serve --port=8000
```

### Akun default

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@gmail.com` | `12345678` |

Ganti via `ADMIN_EMAIL` / `ADMIN_PASSWORD` di `.env`. **Jangan** pakai password default di production — seeder akan menolak jika `APP_ENV` bukan `local`/`testing`.

---

## 🔗 Endpoint

| Method | Path | Middleware | Keterangan |
|--------|------|------------|------------|
| GET | `/api/ping` | — | Health check |
| POST | `/api/register` | `throttle` | Daftar user |
| POST | `/api/login` | `throttle` | Login (token: ability sesuai role) |
| POST | `/api/admin/login` | `throttle` | Login admin |
| GET | `/api/me` | `auth:sanctum` | Profil user |
| POST | `/api/logout` | `auth:sanctum` | Logout (revoke token) |
| GET | `/api/reports` | `auth:sanctum` | List laporan; `status`, `limit`, `offset`; user biasa hanya melihat miliknya |
| GET | `/api/reports/{id}` | `auth:sanctum` | Detail 1 laporan (+user, updates) |
| POST | `/api/reports` | `auth:sanctum` | Buat laporan (multipart: foto di `foto`) |
| PATCH/POST | `/api/reports/{id}/status` | admin | Ubah status & tambah update (foto di `foto_dokumentasi`) |
| DELETE | `/api/reports/{id}` | admin | Hapus laporan + file |
| POST | `/api/admin/clear-all-reports` | admin | Bersihkan semua laporan + file |
| GET | `/api/files/{path}` | — | Proxy akses file (anti `..`) |

Route `/api/testing/*` aktif hanya saat `APP_ENV=local|testing`.

---

## ⚙️ Konfigurasi Penting (`.env`)

| Kunci | Default | Keterangan |
|-------|---------|------------|
| `APP_ENV` | `local` | Ubah ke `production` |
| `APP_DEBUG` | `true` | Set `false` di prod |
| `CORS_ALLOWED_ORIGINS` | `*` | Dipisah koma; ketatkan di prod |
| `SANCTUM_TOKEN_EXPIRATION` | `10080` | Menit (7 hari) |
| `THROTTLE_LOGIN` | `10` | Percobaan login per menit |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | — | Akun admin seeder |
| `SENTRY_LARAVEL_DSN` | kosong | Aktifkan error tracking |
| `DB_CONNECTION` | `sqlite` | `mysql` di produksi |

Lihat `.env.production.example` untuk template produksi.

---

## 🧪 Testing

```bash
php artisan test
```

Test mencakup auth, register/login, laporan CRUD, otorisasi admin, dan normalisasi status.

---

## 📄 Lisensi

MIT.