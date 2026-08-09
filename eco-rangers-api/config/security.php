<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Konfigurasi Keamanan & Rutin non-config
    |--------------------------------------------------------------------------
    |
    | Nilai env() hanya boleh dibaca di sini (bukan di routes/closure), supaya
    | tetap valid setelah `php artisan config:cache` di produksi.
    |
    */

    // Limit percobaan login/register per menit (per IP).
    'login_throttle' => (int) env('THROTTLE_LOGIN', 10),

    // Kredensial admin default (hanya untuk seeder & route testing).
    'admin_email' => env('ADMIN_EMAIL', 'admin@gmail.com'),
    'admin_password' => env('ADMIN_PASSWORD'),

    // Aktifkan route testing (/api/testing/*) hanya bila true.
    // Default lokal/testing; produksi Wajib false. Gunakan env() (container
    // belum siap saat config load).
    'testing_routes' => (bool) env('APP_TESTING_ROUTES', in_array(env('APP_ENV', 'production'), ['local', 'testing'], true)),
];