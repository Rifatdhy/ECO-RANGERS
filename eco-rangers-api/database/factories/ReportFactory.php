<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::inRandomOrder()->value('id'),
            'kategori' => $this->faker->randomElement(['sampah','pencemaran','infrastruktur','fauna','flora','laimnya']),
            'judul' => $this->faker->sentence(3),
            'deskripsi' => $this->faker->paragraph(),
            'lokasi_text' => $this->faker->city(),
            'lat' => $this->faker->latitude(),
            'lng' => $this->faker->longitude(),
            // ponytail: foto_path NULL — faker imageUrl mengembalikan URL absolut
            // (via.placeholder.com) yang tak pernah tersimpan di storage, jadi
            // memicu burst 404 di list. UI sudah punya fallback ikon.
            'foto_path' => null,
            'status' => 'pending',
        ];
    }
}
