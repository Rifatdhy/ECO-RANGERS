<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Panggil seeder untuk admin
        $this->call(AdminUserSeeder::class);

        // Buat 10 user biasa secara otomatis
        User::factory(10)->create();

        // Data demo: 20 laporan + beberapa vote acak antar user.
        \App\Models\Report::factory(20)->create();

        $users = User::where('is_admin', false)->get();
        $reports = \App\Models\Report::all();
        foreach ($users as $user) {
            foreach ($reports->random(min(3, $reports->count())) as $report) {
                \App\Models\Vote::firstOrCreate([
                    'user_id' => $user->id,
                    'report_id' => $report->id,
                ]);
            }
        }

        // User::factory()->create([
        //     'name' => 'Test User',
        //     'email' => 'test@example.com',
        // ]);
    }
}
