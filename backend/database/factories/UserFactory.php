<?php

namespace Database\Factories;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'username' => fake()->unique()->userName(),
            'nombres' => fake()->firstName(),
            'apellidos' => fake()->lastName(),
            'email' => fake()->unique()->safeEmail(),
            'password' => static::$password ??= Hash::make('password'),
            'rol_id' => Role::factory(),
            'estado' => 'activo',
            'intentos_fallidos' => 0,
            'requiere_cambio_password' => false,
        ];
    }

    public function administrador(): static
    {
        return $this->state(fn () => [
            'rol_id' => Role::query()->firstOrCreate(
                ['nombre' => 'Administrador'],
                ['descripcion' => 'Acceso completo']
            )->id,
        ]);
    }

    public function operador(): static
    {
        return $this->state(fn () => [
            'rol_id' => Role::query()->firstOrCreate(
                ['nombre' => 'Operador'],
                ['descripcion' => 'Acceso a cobros']
            )->id,
        ]);
    }
}
