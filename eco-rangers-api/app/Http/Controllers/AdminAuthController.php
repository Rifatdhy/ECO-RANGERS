<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminAuthController extends Controller
{
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials)) {
            $user = Auth::user();

            // Memeriksa apakah user adalah admin
            if ($user->is_admin) {
                // Hapus token lama jika ada, untuk memastikan hanya ada satu sesi aktif
                $user->tokens()->delete();
                $token = $user->createToken('admin-token', ['role:admin'])->plainTextToken;
                return response()->json([
                    'token' => $token,
                    'user' => $user
                ]);
            }
        }

        // Jika login gagal atau user bukan admin
        return response()->json(['message' => 'Email, password salah, atau Anda bukan admin'], 401);
    }
}
