<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;
use App\Models\Report;

class ReportListTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_view_all_reports()
    {
        // GIVEN ada beberapa laporan di database
        $user = User::factory()->create();
        Report::factory()->count(3)->create();

        // WHEN user mengambil semua laporan
        $response = $this->actingAs($user, 'api')
                         ->getJson('/api/reports');

        // THEN server mengembalikan status 200 dan daftar laporan
        $response->assertStatus(200)
                 ->assertJsonStructure([['id', 'title', 'description']]);
    }
}
