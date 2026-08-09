<?php

namespace Tests\Feature;

use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;

class AuthTest extends TestCase
{
    use RefreshDatabase; // <— ini penting!

    #[Test]
    public function user_can_login_with_valid_credentials()
    {
        // GIVEN user dengan akun valid ada di database
        $user = User::factory()->create([
            'email' => 'admin@example.com',
            'username' => 'admin',
            'password' => bcrypt('123456'),
        ]);

        // WHEN user mengirim permintaan login ke endpoint /api/login
        $response = $this->postJson('/api/login', [
            'email' => 'admin@example.com',
            'password' => '123456',
        ]);

        // THEN server mengembalikan status 200 dan token autentikasi
        $response->assertStatus(200)
                 ->assertJsonStructure(['token']);
    }
}
