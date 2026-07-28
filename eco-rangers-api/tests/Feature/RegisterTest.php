<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class RegisterTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_register_successfully()
    {
        // GIVEN data user baru valid
        $data = [
            'username' => 'eco_user',
            'email' => 'eco@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        // WHEN request dikirim ke /api/register
        $response = $this->postJson('/api/register', $data);

        // THEN server mengembalikan status 201 dan token user
        $response->assertStatus(201)
                 ->assertJsonStructure(['user', 'token']);
    }

    /** @test */
    public function cannot_register_with_duplicate_email()
    {
        User::factory()->create(['email' => 'existing@example.com']);

        $data = [
            'username' => 'newuser',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        $response = $this->postJson('/api/register', $data);
        $response->assertStatus(422)->assertInvalid('email');
    }
}
