<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $email = env('ADMIN_EMAIL', 'admin@gmail.com');
        $password = env('ADMIN_PASSWORD', '12345678');

        // Hapus admin lama jika ada, untuk menghindari error duplikat
        User::where('email', $email)->delete();

        User::create([
            'name' => 'Admin User', // Menambahkan kolom name yang wajib diisi
            'username' => 'admin',
            'email' => $email,
            'password' => Hash::make($password),
            'is_admin' => true,
        ]);
    }
}