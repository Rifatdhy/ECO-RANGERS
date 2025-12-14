Eco Rangers — Cara Menjalankan Project (Local)
Prasyarat

Pastikan sudah ter-install:
Git
PHP 8.x
Composer
SQLite (atau MySQL/PostgreSQL jika project Anda pakai itu)
Node.js + npm (opsional, jika ada build asset tertentu)
Flutter SDK (jika ada aplikasi Flutter)
Android Studio / Emulator / Device (untuk Flutter)

1) Clone Repository
git clone https://github.com/rifatdhiya/Project-Eco-Rangers.git
cd Project-Eco-Rangers

2) Menjalankan Backend (Laravel API)
Masuk ke folder backend:
cd eco-rangers-api

Install dependency:
composer install

Siapkan file environment:
cp .env.example .env
php artisan key:generate

Konfigurasi Database
Opsi A — SQLite (paling mudah untuk local)

Buat file database:
# Windows (PowerShell):
New-Item -ItemType File -Path database/database.sqlite -Force

Edit .env:
DB_CONNECTION=sqlite
# DB_DATABASE= (biarkan kosong untuk sqlite)

Opsi B — MySQL (jika project Anda pakai MySQL)
Edit .env:
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=eco_rangers
DB_USERNAME=root
DB_PASSWORD=

Jalankan migrasi + seeder:
php artisan migrate --seed

Jika Anda punya akun admin default dari seeder, pastikan sesuai dengan kredensial yang Anda gunakan.
Dari info Anda:
Admin: admin@gmail.com / 11111111
User: rifat@gmail.com / 12345678

(Opsional) Storage link untuk akses file upload

Jika fitur upload foto dipakai:
php artisan storage:link

Jalankan server Laravel:
php artisan serve


Secara default akan jalan di:
http://127.0.0.1:8000

3) Menjalankan Frontend (Flutter) — Jika Ada
Sesuaikan nama folder Flutter Anda. Contoh di bawah saya pakai eco_rangers (ubah jika berbeda).

Masuk ke folder Flutter:
cd ../eco_rangers

Install dependency Flutter:
flutter pub get

Konfigurasi Base URL API di .env
Pastikan base URL API mengarah ke backend lokal:
http://127.0.0.1:8000

Jika Anda menjalankan di Android emulator, gunakan:
http://10.0.2.2:8000

Jalankan aplikasi:
flutter run

4) Menjalankan BDD / Testing (Jika Digunakan):
cd eco-rangers-api
vendor/bin/behat
