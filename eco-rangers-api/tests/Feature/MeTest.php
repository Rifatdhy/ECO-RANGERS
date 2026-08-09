<?php

namespace Tests\Feature;

use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;

class MeTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function authenticated_user_can_get_own_profile()
    {
        // GIVEN user sudah login
        $user = User::factory()->create();

        // WHEN user meminta data dirinya ke /api/me
        Sanctum::actingAs($user); // ✅ ganti baris ini
        $response = $this->getJson('/api/me');

        // THEN server mengembalikan status 200 dan data profil
        $response->assertStatus(200)
                 ->assertJsonStructure(['id', 'email']);
    }
}
