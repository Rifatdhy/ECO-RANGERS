<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminAuthController;

// Endpoint publik (tidak perlu login)
Route::get('/ping', fn () => response()->json(['ok' => true]));
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/admin/login', [AdminAuthController::class, 'login']);
Route::get('/reports', [ReportController::class, 'index']);
Route::get('/reports/{report}', [ReportController::class, 'show']);

// Endpoint untuk user yang sudah login (user biasa & admin)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // User biasa bisa membuat laporan
    Route::post('/reports', [ReportController::class, 'store']);
});

// Endpoint KHUSUS ADMIN (harus login sebagai admin)
Route::middleware(['auth:sanctum', 'ability:role:admin'])->group(function () {
    // Hanya admin yang bisa update status dan hapus laporan
    Route::patch('/reports/{report}/status', [ReportController::class, 'updateStatus']);
    Route::delete('/reports/{report}', [ReportController::class, 'destroy']);
});
