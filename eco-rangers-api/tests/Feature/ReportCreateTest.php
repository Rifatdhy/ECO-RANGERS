<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;

class ReportCreateTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_create_new_report()
    {
        // GIVEN user yang sudah login
        $user = User::factory()->create();

        // WHEN user mengirim laporan baru ke /api/reports
        $payload = [
            'judul' => 'Sampah di Sungai Palu',
            'deskripsi' => 'Banyak sampah plastik di sekitar sungai.',
            'lokasi_text' => 'Palu Selatan',
        ];

        // Gunakan Sanctum actingAs agar auth:sanctum dikenali
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/reports', $payload);

        // THEN server mengembalikan status 201 dan data laporan baru
        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'report' => ['id', 'judul', 'deskripsi', 'lokasi_text']
                 ]);
    }
}
