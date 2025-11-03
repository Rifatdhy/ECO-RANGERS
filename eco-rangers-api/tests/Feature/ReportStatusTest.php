<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;
use App\Models\Report;

class ReportStatusTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_update_report_status()
    {
        // GIVEN user login dan satu laporan sudah ada
        $user = User::factory()->create();
        $report = Report::factory()->create(['status' => 'Pending']);

        // WHEN user mengubah status laporan
        $response = $this->actingAs($user, 'api')
                         ->patchJson("/api/reports/{$report->id}/status", [
                             'status' => 'resolved',
                         ]);

        // THEN server merespons 200 dan status berubah
        $response->assertStatus(200)
                 ->assertJsonFragment(['status' => 'resolved']);
    }
}
