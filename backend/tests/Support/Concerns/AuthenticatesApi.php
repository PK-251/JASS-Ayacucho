<?php

namespace Tests\Support\Concerns;

use App\Models\User;

trait AuthenticatesApi
{
    protected function apiTokenFor(string $username, string $password, string $deviceName = 'phpunit'): string
    {
        $response = $this->postJson('/api/v1/login', [
            'username' => $username,
            'password' => $password,
            'device_name' => $deviceName,
        ]);

        $response->assertOk();

        return $response->json('data.access_token');
    }

    protected function withApiToken(string $token): static
    {
        return $this->withHeader('Authorization', 'Bearer '.$token);
    }

    protected function actingAsApiUser(User $user, string $deviceName = 'phpunit'): static
    {
        $token = $user->createToken($deviceName)->plainTextToken;

        return $this->withApiToken($token);
    }
}
