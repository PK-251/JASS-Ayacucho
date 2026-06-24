<?php

namespace Database\Factories;

use App\Models\CategoriaServicio;
use App\Models\Vecino;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Vecino>
 */
class VecinoFactory extends Factory
{
    protected $model = Vecino::class;

    public function definition(): array
    {
        static $sequence = 9000;

        return [
            'codigo' => 'U-'.str_pad((string) ++$sequence, 4, '0', STR_PAD_LEFT),
            'documento_tipo' => 'DNI',
            'documento_num' => (string) fake()->unique()->numerify('########'),
            'nombres' => fake()->firstName(),
            'apellidos' => fake()->lastName(),
            'direccion' => fake()->streetAddress(),
            'categoria_id' => CategoriaServicio::factory(),
            'estado' => 'activo',
            'tiene_medidor' => false,
            'fecha_registro' => now()->toDateString(),
        ];
    }
}
