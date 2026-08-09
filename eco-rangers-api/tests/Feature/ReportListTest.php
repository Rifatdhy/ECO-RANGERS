<?php

namespace Tests\Feature;

use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class ReportListTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_can_view_all_reports()
    {
        // GIVEN ada beberapa laporan di database
        $user = User::factory()->create();
        Report::factory()->count(3)->create(['user_id' => $user->id]);

        // WHEN user mengambil semua laporan
        Sanctum::actingAs($user);
        $response = $this->getJson('/api/reports');

        // THEN server mengembalikan status 200 dan daftar laporan
        $response->assertStatus(200)
                 ->assertJsonStructure([['id', 'judul', 'deskripsi']]);
    }
}
