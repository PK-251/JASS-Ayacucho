<?php

namespace Database\Factories;

use App\Models\CategoriaServicio;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CategoriaServicio>
 */
class CategoriaServicioFactory extends Factory
{
    protected $model = CategoriaServicio::class;

    public function definition(): array
    {
        return [
            'nombre' => fake()->unique()->word(),
            'descripcion' => fake()->sentence(),
            'activa' => true,
        ];
    }
}
