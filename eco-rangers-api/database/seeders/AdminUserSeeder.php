<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $email = env('ADMIN_EMAIL', 'admin@gmail.com');
        $password = env('ADMIN_PASSWORD');

        $isLocalEnv = app()->environment('local', 'testing');
        if ($isLocalEnv && ($password === null || $password === '')) {
            // Default hanya untuk lingkungan local/testing.
            $password = '12345678';
        }

        // Di produksi: password WAJIB ada & bukan default.
        $isDefaultPassword = in_array($password, ['12345678', 'GANTI-DENGAN-PASSWORD-ACAK-YANG-SANGAT-KUAT'], true);
        if (!$isLocalEnv && ($password === null || $password === '' || $isDefaultPassword)) {
            throw new \RuntimeException(
                'ADMIN_PASSWORD tidak boleh default/kosong di environment ini. Set password kuat di .env produksi.'
            );
        }

        // Hapus admin lama jika ada, untuk menghindari error duplikat
        User::where('email', $email)->delete();

        User::create([
            'name' => 'Admin User',
            'username' => 'admin',
            'email' => $email,
            'password' => \Illuminate\Support\Facades\Hash::make($password),
            'is_admin' => true,
        ]);
    }
}