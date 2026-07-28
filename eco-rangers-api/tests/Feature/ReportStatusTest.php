<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
use App\Models\Report;

class ReportStatusTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function admin_can_update_report_status()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create(['status' => 'pending']);

        Sanctum::actingAs($admin, ['role:admin']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'selesai',
        ]);

        $response->assertStatus(200)
                 ->assertJsonFragment(['status' => 'selesai']);
    }

    /** @test */
    public function non_admin_cannot_update_status()
    {
        $user = User::factory()->create();
        $report = Report::factory()->create(['status' => 'pending']);

        Sanctum::actingAs($user, ['role:user']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'selesai',
        ]);

        $response->assertStatus(403);
    }
}
