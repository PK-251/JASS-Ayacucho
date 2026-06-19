<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ApiAuthBackendTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->createSchema();
        $this->seedUser();
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

    private function createSchema(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('login_logs');
        Schema::dropIfExists('users');
        Schema::dropIfExists('roles');

        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('nombre')->unique();
            $table->string('descripcion')->nullable();
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('username')->unique();
            $table->string('nombres');
            $table->string('apellidos');
            $table->string('email')->nullable()->unique();
            $table->string('password');
            $table->foreignId('rol_id');
            $table->string('estado')->default('activo');
            $table->unsignedTinyInteger('intentos_fallidos')->default(0);
            $table->timestamp('bloqueado_hasta')->nullable();
            $table->boolean('requiere_cambio_password')->default(false);
            $table->timestamp('ultimo_login')->nullable();
            $table->foreignId('created_by')->nullable();
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();
        });

        Schema::create('login_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable();
            $table->string('username_intentado');
            $table->string('ip_address');
            $table->text('user_agent')->nullable();
            $table->string('resultado');
            $table->string('motivo_fallo')->nullable();
            $table->timestamp('fecha_intento')->nullable();
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    private function seedUser(): void
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
