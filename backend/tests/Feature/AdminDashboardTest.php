<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->createSchema();
        $this->seedUsers();
    }

    public function test_usuario_no_autenticado_es_redireccionado_al_login()
    {
        $response = $this->get('/admin/inicio');

        $response->assertStatus(302);
        $response->assertRedirect('/login');
    }

    public function test_administrador_autenticado_puede_ver_dashboard()
    {
        $admin = User::whereHas('role', fn ($q) => $q->where('nombre', 'Administrador'))->firstOrFail();

        $response = $this->actingAs($admin)->get('/admin/inicio');

        $response->assertStatus(200);
        $response->assertSee('Inicio');
    }

    public function test_operador_no_puede_entrar_al_panel_admin()
    {
        $operator = User::whereHas('role', fn ($q) => $q->where('nombre', 'Operador'))->firstOrFail();

        $response = $this->actingAs($operator)->get('/admin/inicio');

        $response->assertStatus(302);
        $response->assertRedirect('/operador/inicio');
    }

    private function createSchema(): void
    {
        Schema::dropIfExists('cobros');
        Schema::dropIfExists('egresos');
        Schema::dropIfExists('vecinos');
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

        Schema::create('vecinos', function (Blueprint $table) {
            $table->id();
            $table->string('codigo')->unique();
            $table->string('documento_tipo')->default('DNI');
            $table->string('documento_num')->unique();
            $table->string('nombres');
            $table->string('apellidos');
            $table->string('direccion')->default('Quilcata');
            $table->foreignId('categoria_id')->default(1);
            $table->string('estado')->default('activo');
            $table->boolean('tiene_medidor')->default(false);
            $table->date('fecha_registro')->nullable();
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();
        });

        Schema::create('cobros', function (Blueprint $table) {
            $table->id();
            $table->string('numero_serie')->nullable();
            $table->foreignId('vecino_id')->nullable();
            $table->foreignId('operador_id')->nullable();
            $table->unsignedSmallInteger('periodo_anio');
            $table->unsignedTinyInteger('periodo_mes');
            $table->decimal('monto_recibido', 8, 2)->default(0);
            $table->string('estado')->default('pagado');
            $table->date('fecha_cobro')->nullable();
            $table->time('hora_cobro')->nullable();
            $table->timestamps();
        });

        Schema::create('egresos', function (Blueprint $table) {
            $table->id();
            $table->decimal('monto', 8, 2)->default(0);
            $table->string('estado')->default('aprobado');
            $table->date('fecha_egreso')->nullable();
            $table->timestamps();
        });
    }

    private function seedUsers(): void
    {
        $adminRole = Role::create(['nombre' => 'Administrador']);
        $operatorRole = Role::create(['nombre' => 'Operador']);

        User::create([
            'username' => 'admin_test',
            'nombres' => 'Admin',
            'apellidos' => 'Test',
            'email' => 'admin@test.local',
            'password' => Hash::make('secret'),
            'rol_id' => $adminRole->id,
            'estado' => 'activo',
        ]);

        User::create([
            'username' => 'operador_test',
            'nombres' => 'Operador',
            'apellidos' => 'Test',
            'email' => 'operador@test.local',
            'password' => Hash::make('secret'),
            'rol_id' => $operatorRole->id,
            'estado' => 'activo',
        ]);
    }
}
