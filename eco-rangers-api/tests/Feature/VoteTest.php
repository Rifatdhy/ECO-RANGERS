<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class VoteTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function user_cannot_vote_on_others_report(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $owner->id]);

        Sanctum::actingAs($other);

        $this->postJson("/api/reports/{$report->id}/vote")->assertStatus(403);
    }

    #[Test]
    public function user_can_toggle_vote_on_own_report(): void
    {
        $user = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $this->postJson("/api/reports/{$report->id}/vote")
            ->assertStatus(200)
            ->assertJson(['voted' => true, 'votes' => 1]);

        $this->postJson("/api/reports/{$report->id}/vote")
            ->assertStatus(200)
            ->assertJson(['voted' => false, 'votes' => 0]);

        $this->assertDatabaseCount('votes', 0);
    }

    #[Test]
    public function admin_can_vote_any_report(): void
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $owner = User::factory()->create();
        $report = Report::factory()->create(['user_id' => $owner->id]);

        Sanctum::actingAs($admin, ['role:admin']);

        $this->postJson("/api/reports/{$report->id}/vote")
            ->assertStatus(200)
            ->assertJson(['voted' => true]);
    }
}