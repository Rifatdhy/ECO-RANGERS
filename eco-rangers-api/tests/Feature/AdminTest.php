<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function admin_can_delete_report()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create();

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->deleteJson("/api/reports/{$report->id}");

        $response->assertStatus(200)
                 ->assertJson(['deleted' => true]);
        $this->assertDatabaseMissing('reports', ['id' => $report->id]);
    }

    /** @test */
    public function non_admin_cannot_delete_report()
    {
        $user = User::factory()->create();
        $report = Report::factory()->create();

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->deleteJson("/api/reports/{$report->id}");

        $response->assertStatus(403);
    }

    /** @test */
    public function admin_can_clear_all_reports()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        Report::factory()->count(5)->create();

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->postJson('/api/admin/clear-all-reports');

        $response->assertStatus(200);
        $this->assertDatabaseCount('reports', 0);
    }

    /** @test */
    public function non_admin_cannot_clear_all_reports()
    {
        $user = User::factory()->create();
        Report::factory()->count(3)->create();

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->postJson('/api/admin/clear-all-reports');

        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_admin_endpoints()
    {
        $response = $this->deleteJson('/api/reports/1');
        $response->assertStatus(401);
    }
}
