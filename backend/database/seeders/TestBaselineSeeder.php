<?php

namespace Database\Seeders;

use App\Models\CategoriaServicio;
use App\Models\Role;
use App\Models\Tarifa;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class TestBaselineSeeder extends Seeder
{
    public function run(): void
    {
        $adminRole = Role::query()->firstOrCreate(
            ['nombre' => 'Administrador'],
            ['descripcion' => 'Acceso completo al sistema']
        );

        Role::query()->firstOrCreate(
            ['nombre' => 'Operador'],
            ['descripcion' => 'Acceso a cobros y asistencia']
        );

        User::query()->updateOrCreate(
            ['username' => 'admin_jass'],
            [
                'nombres' => 'Administrador',
                'apellidos' => 'JASS Test',
                'email' => 'admin@test.jass.local',
                'password' => Hash::make('admin123'),
                'rol_id' => $adminRole->id,
                'estado' => 'activo',
            ]
        );

        $categoria = CategoriaServicio::query()->firstOrCreate(
            ['nombre' => 'Domestica'],
            [
                'descripcion' => 'Hogares y viviendas',
                'activa' => true,
            ]
        );

        Tarifa::query()->updateOrCreate(
            [
                'categoria_id' => $categoria->id,
                'fecha_vigencia_inicio' => now()->startOfYear()->toDateString(),
            ],
            [
                'monto' => 4.00,
                'fecha_vigencia_fin' => null,
                'activa' => true,
                'descripcion' => 'Tarifa base de prueba',
            ]
        );
    }
}
