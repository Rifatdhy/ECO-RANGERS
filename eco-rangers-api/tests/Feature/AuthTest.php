<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;

class AuthTest extends TestCase
{
    use RefreshDatabase; // <— ini penting!

    /** @test */
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

    /** @test */
    public function user_cannot_login_with_wrong_password()
    {
        // GIVEN user dengan password yang benar ada di database
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => bcrypt('correct'),
        ]);

        // WHEN user login dengan password yang salah
        $response = $this->postJson('/api/login', [
            'email' => 'test@example.com',
            'password' => 'wrong',
        ]);

        // THEN server merespons 401 dengan pesan error
        $response->assertStatus(401)
                 ->assertJson(['message' => 'Email atau password salah']);
    }
}
