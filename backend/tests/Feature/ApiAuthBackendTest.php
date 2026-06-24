<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Tests\Support\SqliteTestCase;

class ApiAuthBackendTest extends SqliteTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->seedApiAdminUser();
    }

    public function test_login_api_devuelve_token_con_credenciales_validas(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'username' => 'admin_api',
            'password' => 'admin123',
            'device_name' => 'phpunit',
        ]);

        $response->assertOk()
            ->assertJsonPath('message', 'Acceso correcto.')
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.user.rol', 'Administrador')
            ->assertJsonStructure(['data' => ['access_token']]);

        $this->assertDatabaseHas('login_logs', [
            'username_intentado' => 'admin_api',
            'resultado' => 'exitoso',
        ]);
    }

    public function test_login_api_rechaza_password_incorrecto_y_registra_intento(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'username' => 'admin_api',
            'password' => 'incorrecto',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Usuario o contrasena incorrectos.');

        $this->assertDatabaseHas('users', [
            'username' => 'admin_api',
            'intentos_fallidos' => 1,
        ]);

        $this->assertDatabaseHas('login_logs', [
            'username_intentado' => 'admin_api',
            'resultado' => 'fallido_credenciales',
        ]);
    }

    public function test_login_api_bloquea_usuario_tras_tres_intentos_fallidos(): void
    {
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/v1/login', [
                'username' => 'admin_api',
                'password' => 'incorrecto',
            ]);
        }

        $this->assertDatabaseHas('users', [
            'username' => 'admin_api',
            'estado' => 'bloqueado',
            'intentos_fallidos' => 3,
        ]);
    }

    public function test_endpoint_me_requiere_autenticacion(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response->assertStatus(401);
    }

    private function seedApiAdminUser(): void
    {
        $role = Role::create(['nombre' => 'Administrador']);

        User::create([
            'username' => 'admin_api',
            'nombres' => 'Admin',
            'apellidos' => 'API',
            'email' => 'admin-api@test.local',
            'password' => Hash::make('admin123'),
            'rol_id' => $role->id,
            'estado' => 'activo',
        ]);
    }
}
