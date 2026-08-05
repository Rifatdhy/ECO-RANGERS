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
    public function user_can_update_report_status()
    {
        // GIVEN admin login dan satu laporan sudah ada
        $user = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create(['user_id' => $user->id, 'status' => 'pending']);

        // WHEN admin mengubah status laporan
        Sanctum::actingAs($user, ['role:admin']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'selesai',
        ]);

        // THEN server merespons 200 dan status berubah
        $response->assertStatus(200)
                 ->assertJsonPath('report.status', 'Selesai');
    }

    /** @test */
    public function invalid_status_is_rejected()
    {
        // GIVEN admin login dan satu laporan sudah ada
        $user = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create(['user_id' => $user->id, 'status' => 'pending']);

        // WHEN admin mengirim status yang tidak valid (mis. 'resolved')
        Sanctum::actingAs($user, ['role:admin']);
        $response = $this->patchJson("/api/reports/{$report->id}/status", [
            'status' => 'resolved',
        ]);

        // THEN server menolak dengan 422
        $response->assertStatus(422);
        $this->assertDatabaseHas('reports', ['id' => $report->id, 'status' => 'pending']);
    }
}
