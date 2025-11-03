<?php

namespace Tests\Feature;

use Tests\TestCase;
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
}
