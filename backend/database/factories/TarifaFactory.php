<?php

namespace Database\Factories;

use App\Models\CategoriaServicio;
use App\Models\Tarifa;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Tarifa>
 */
class TarifaFactory extends Factory
{
    protected $model = Tarifa::class;

    public function definition(): array
    {
        return [
            'categoria_id' => CategoriaServicio::factory(),
            'monto' => fake()->randomFloat(2, 2, 10),
            'fecha_vigencia_inicio' => now()->startOfYear()->toDateString(),
            'fecha_vigencia_fin' => null,
            'activa' => true,
            'descripcion' => 'Tarifa de prueba',
        ];
    }
}
