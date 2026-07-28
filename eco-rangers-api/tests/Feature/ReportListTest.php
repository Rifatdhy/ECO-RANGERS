<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class ReportListTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_view_own_reports()
    {
        $user = User::factory()->create();
        Report::factory()->count(3)->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);
        $response = $this->getJson('/api/reports');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [['id', 'judul', 'deskripsi', 'status']]
        ]);
        $response->assertJsonCount(3, 'data');
    }

    /** @test */
    public function admin_can_view_all_reports()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        User::factory()->count(2)->create()->each(function ($u) {
            Report::factory()->count(2)->create(['user_id' => $u->id]);
        });

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->getJson('/api/reports');

        $response->assertStatus(200);
        $response->assertJsonCount(4, 'data');
    }

    /** @test */
    public function unauthenticated_request_gets_unauthorized()
    {
        $response = $this->getJson('/api/reports');
        $response->assertStatus(401);
    }
}
