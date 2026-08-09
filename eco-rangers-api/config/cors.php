<?php

return [

    'paths' => ['api/*', 'storage/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // '* untuk development. Production: daftar origin dipisah koma via
    // CORS_ALLOWED_ORIGINS. Fail-closed: di production tanpa konfigurasi,
    // jangan buka '*'.
    'allowed_origins' => (function () {
        $origins = env('CORS_ALLOWED_ORIGINS');
        if (is_string($origins) && $origins !== '') {
            return array_filter(array_map('trim', explode(',', $origins)));
        }
        // Dev (local/testing): tetap buka semua. Gunakan env() — jangan
        // app()->environment() karena container belum siap saat config load.
        return in_array(env('APP_ENV', 'production'), ['local', 'testing'], true) ? ['*'] : [];
    })(),

    'allowed_origins_patterns' => [],

    // Boleh pakai ['*'] untuk dev agar simpel.
    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
