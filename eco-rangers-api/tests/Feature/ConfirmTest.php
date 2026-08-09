<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class ConfirmTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function non_pelapor_cannot_confirm(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $owner->id, 'status' => 'selesai']);

        Sanctum::actingAs($other);

        $this->postJson("/api/reports/{$report->id}/confirm", ['konfirmasi' => 'sesuai'])
            ->assertStatus(403);
    }

    #[Test]
    public function cannot_confirm_before_report_is_selesai(): void
    {
        $user = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $user->id, 'status' => 'pending']);

        Sanctum::actingAs($user);

        $this->postJson("/api/reports/{$report->id}/confirm", ['konfirmasi' => 'sesuai'])
            ->assertStatus(422);
    }

    #[Test]
    public function pelapor_can_confirm_selesai_report(): void
    {
        $user = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $user->id, 'status' => 'selesai']);

        Sanctum::actingAs($user);

        $this->postJson("/api/reports/{$report->id}/confirm", ['konfirmasi' => 'sesuai'])
            ->assertStatus(200)
            ->assertJsonPath('konfirmasi_user', 'sesuai');
    }

    #[Test]
    public function re_status_resets_konfirmasi_user(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $report = Report::factory()->create([
            'user_id' => User::factory()->create()->id,
            'status' => 'selesai',
            'konfirmasi_user' => 'sesuai',
        ]);

        Sanctum::actingAs($admin, ['role:admin']);

        $this->patchJson("/api/reports/{$report->id}/status", ['status' => 'diproses'])
            ->assertStatus(200);

        $this->assertDatabaseHas('reports', [
            'id' => $report->id,
            'status' => 'diproses',
            'konfirmasi_user' => null,
        ]);
    }
}