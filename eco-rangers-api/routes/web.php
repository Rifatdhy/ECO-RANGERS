<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;

Route::get('/', function () {
    return view('welcome');
});

// Rute storage untuk file publik (foto laporan/dokumentasi). CORS sudah
// ditangani config/cors.php paths; rute ini hanya streaming file secara manual.
Route::get('storage/{path}', function ($path) {
    // Keamanan dasar untuk mencegah directory traversal
    if (strpos($path, '..') !== false) {
        abort(403);
    }

    $disk = Storage::disk('public');

    if (!$disk->exists($path)) {
        abort(404);
    }

    return $disk->response($path);
})->where('path', '.+'); // Mengizinkan path yang berisi folder (e.g., 'reports/image.jpg')
