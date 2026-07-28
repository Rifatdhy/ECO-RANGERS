<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->create()->id,
            'judul' => $this->faker->sentence(3),
            'deskripsi' => $this->faker->paragraph(),
            'lokasi_text' => $this->faker->city(),
            'lat' => $this->faker->latitude(),
            'lng' => $this->faker->longitude(),
            'foto_path' => null,
            'status' => 'pending',
        ];
    }
}
