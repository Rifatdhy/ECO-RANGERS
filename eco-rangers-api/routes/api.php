<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminAuthController;

// Endpoint publik
Route::get('/ping', fn () => response()->json(['ok' => true]));
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
Route::post('/admin/login', [AdminAuthController::class, 'login'])->middleware('throttle:5,1');

// Rute testing (hanya aktif di environment local/testing) untuk membantu
// pembuatan data yang diperlukan selama pengujian acceptance.
if (app()->environment(['local', 'testing'])) {
    Route::post('/testing/seed-admin', function () {
        // Buat atau perbarui admin dengan email admin@gmail.com
        $email = 'admin@gmail.com';
        $username = 'admin';
        $password = '12345678';

        $user = \App\Models\User::updateOrCreate(
            ['email' => $email],
            [
                'username' => $username,
                'name' => 'Admin User',
                'password' => Illuminate\Support\Facades\Hash::make($password),
                'is_admin' => true,
            ]
        );

        return response()->json(['created' => true, 'user' => $user]);
    });

    // Rute testing: reset database (migrate:fresh --seed)
    Route::post('/testing/reset', function () {
        // Hati-hati: hanya aktif di environment testing/local
        try {
            // Ensure SQLite database file exists when using file-based sqlite.
            if (config('database.default') === 'sqlite') {
                $db = config('database.connections.sqlite.database');
                $path = $db ?: database_path('database.sqlite');
                if (! file_exists($path)) {
                    $dir = dirname($path);
                    if (! file_exists($dir)) {
                        mkdir($dir, 0755, true);
                    }
                    // attempt to create writable sqlite file
                    if (@file_put_contents($path, '') === false) {
                        throw new \RuntimeException('Unable to create sqlite database file at: ' . $path);
                    }
                }
            }

            $exitCode = \Artisan::call('migrate:fresh', ['--seed' => true, '--no-interaction' => true]);
            if ($exitCode !== 0) {
                return response()->json(['reset' => false, 'message' => 'Artisan returned non-zero exit code', 'code' => $exitCode], 500);
            }
            return response()->json(['reset' => true]);
        } catch (\Throwable $e) {
            // Log and return an explicit error so test hooks can display helpful
            // messages instead of failing with an opaque 500.
            \Log::error('Testing.reset failed: ' . $e->getMessage(), ['exception' => $e]);
            return response()->json(['reset' => false, 'message' => 'Reset failed: ' . $e->getMessage()], 500);
        }
    });
}

// Rute proxy untuk mengambil file
Route::get('/files/{path}', function ($path) {
    try {
        $path = urldecode($path);
        $safePath = Storage::disk('public')->path($path);
        $diskRoot = Storage::disk('public')->path('');
        if (!Str::startsWith($safePath, $diskRoot)) {
            abort(403, 'Invalid path');
        }
        $disk = Storage::disk('public');
        if (!$disk->exists($path)) {
            abort(404, 'File not found');
        }
        return $disk->response($path);
    } catch (\League\Flysystem\PathTraversalDetected $e) {
        abort(403, 'Path traversal detected');
    }
})->where('path', '.+');

// Endpoint untuk user yang sudah login
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/reports', [ReportController::class, 'index']);
    Route::get('/reports/{report}', [ReportController::class, 'show']);
    Route::post('/reports', [ReportController::class, 'store']);
});

// Endpoint KHUSUS ADMIN
Route::middleware(['auth:sanctum', 'ability:role:admin'])->group(function () {
    // Support both POST (legacy) and PATCH (RESTful) for status updates to
    // be tolerant of different clients used by acceptance tests.
    Route::match(['post', 'patch'], '/reports/{report}/status', [ReportController::class, 'updateStatus']);
    Route::delete('/reports/{report}', [ReportController::class, 'destroy']);

    // RUTE BARU: Untuk membersihkan semua laporan
    Route::post('/admin/clear-all-reports', [ReportController::class, 'clearAll']);
});
