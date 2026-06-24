<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Tests\Support\SqliteTestCase;

class AdminDashboardTest extends SqliteTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->seedAdminAndOperatorUsers();
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

    private function seedAdminAndOperatorUsers(): void
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
