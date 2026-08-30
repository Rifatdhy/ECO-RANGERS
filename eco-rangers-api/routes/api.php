<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminAuthController;

$loginThrottle = 'throttle:' . config('security.login_throttle') . ',1';

// Endpoint publik
Route::get('/ping', fn () => response()->json(['ok' => true]));
Route::post('/register', [AuthController::class, 'register'])->middleware($loginThrottle);
Route::post('/login', [AuthController::class, 'login'])->middleware($loginThrottle);
Route::post('/admin/login', [AdminAuthController::class, 'login'])->middleware($loginThrottle);

// Rute testing: hanya aktif bila config('security.testing_routes') true
// (default local/testing) DAN environment bukan production.
// Di produksi WAJIB false lewat .env; guard ganda mencegah reset data
// bila misconfig.
if (config('security.testing_routes') && app()->environment() !== 'production') {
    Route::post('/testing/seed-admin', function () {
        $email = config('security.admin_email');
        $password = config('security.admin_password');

        if ($password === null || $password === '') {
            return response()->json(['created' => false, 'message' => 'ADMIN_PASSWORD tidak diset'], 500);
        }

        $user = \App\Models\User::updateOrCreate(
            ['email' => $email],
            [
                'username' => 'admin',
                'name' => 'Admin User',
                'password' => $password, // otomatis di-hash oleh cast 'hashed'
                'is_admin' => true,
            ]
        );

        return response()->json(['created' => true, 'user' => $user]);
    });

    // Rute testing: reset database (migrate:fresh --seed)
    Route::post('/testing/reset', function () {
        try {
            if (config('database.default') === 'sqlite') {
                $db = config('database.connections.sqlite.database');
                $path = $db ?: database_path('database.sqlite');
                if (! file_exists($path)) {
                    $dir = dirname($path);
                    if (! file_exists($dir)) {
                        mkdir($dir, 0755, true);
                    }
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
            \Log::error('Testing.reset failed: ' . $e->getMessage(), ['exception' => $e]);
            return response()->json(['reset' => false, 'message' => 'Reset failed: ' . $e->getMessage()], 500);
        }
    });
}

// Rute proxy untuk mengambil file (foto laporan/dokumentasi).
// Whitelist MIME (hanya gambar) + anti path traversal + cache lama (path unik per upload).
Route::get('/files/{path}', function ($path) {
    if (strpos($path, '..') !== false) {
        abort(403, 'Invalid path');
    }
    $disk = Illuminate\Support\Facades\Storage::disk('public');
    if (! $disk->exists($path)) {
        abort(404, 'File not found');
    }

    $allowedMime = ['image/jpeg', 'image/png'];
    $mime = $disk->mimeType($path);
    if (! in_array($mime, $allowedMime, true)) {
        abort(403, 'File type not allowed');
    }

    $response = $disk->response($path);
    $response->headers->set('Cache-Control', 'public, max-age=31536000, immutable');
    $response->headers->set('X-Content-Type-Options', 'nosniff');
    return $response;
})->where('path', '.+')->middleware('throttle:120,1');

// Endpoint untuk user yang sudah login
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/reports', [ReportController::class, 'index']);
    Route::get('/reports/stats', [ReportController::class, 'stats']);
    Route::get('/reports/{report}', [ReportController::class, 'show']);
    Route::post('/reports', [ReportController::class, 'store'])->middleware('throttle:10,1');
    Route::post('/reports/{report}/vote', [ReportController::class, 'toggleVote'])->middleware('throttle:30,1');
    Route::post('/reports/{report}/confirm', [ReportController::class, 'confirmResolution'])->middleware('throttle:30,1');
});

// Endpoint KHUSUS ADMIN
Route::middleware(['auth:sanctum', 'ability:role:admin'])->group(function () {
    // Support both POST (legacy) and PATCH (RESTful) for status updates to
    // be tolerant of different clients used by acceptance tests.
    Route::match(['post', 'patch'], '/reports/{report}/status', [ReportController::class, 'updateStatus']);
    Route::delete('/reports/{report}', [ReportController::class, 'destroy']);

    // Untuk membersihkan semua laporan
    Route::post('/admin/clear-all-reports', [ReportController::class, 'clearAll']);

    // Minta URL unduhan CSV bertanda (signed, kedaluwarsa 60 detik).
    Route::get('/admin/export/reports/url', [ReportController::class, 'exportCsvUrl']);
});

// Export CSV: hanya dapat diakses via URL bertanda (HMAC + expires) yang
// diterbitkan oleh /admin/export/reports/url — tidak ada token di query.
Route::get('/admin/export/reports', [ReportController::class, 'exportCsv']);