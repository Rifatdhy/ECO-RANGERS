<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class ReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'judul' => $this->faker->sentence(3),
            'deskripsi' => $this->faker->paragraph(),
            'lokasi_text' => $this->faker->city(),
            'lat' => $this->faker->latitude(),
            'lng' => $this->faker->longitude(),
            'status' => 'pending',
        ];
    }
}
