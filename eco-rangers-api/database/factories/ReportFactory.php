<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::all()->random()->id,
            'judul' => $this->faker->sentence(3),
            'deskripsi' => $this->faker->paragraph(),
            'lokasi_text' => $this->faker->city(),
            'lat' => $this->faker->latitude(),
            'lng' => $this->faker->longitude(),
            'foto_path' => $this->faker->imageUrl(640, 480, 'nature', true, 'eco-rangers'), // Memperbaiki: Menambahkan kembali foto_path
            'status' => 'pending',
        ];
    }
}
