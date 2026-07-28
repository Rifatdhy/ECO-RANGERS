<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Response;
use Illuminate\Support\Str;

Route::get('/', function () {
    return view('welcome');
});

// Rute ini akan menangani permintaan file dari storage secara manual
// agar melewati middleware CORS
Route::get('storage/{path}', function ($path) {
    // Keamanan untuk mencegah directory traversal
    $path = urldecode($path);
    $safePath = Storage::disk('public')->path($path);
    $diskRoot = Storage::disk('public')->path('');
    if (!Str::startsWith($safePath, $diskRoot)) {
        abort(403);
    }

    $disk = Storage::disk('public');

    if (!$disk->exists($path)) {
        abort(404);
    }

    return $disk->response($path);
})->where('path', '.+'); // Mengizinkan path yang berisi folder (e.g., 'reports/image.jpg')
