<?php

namespace Tests\Support\Concerns;

use App\Models\CategoriaServicio;
use App\Models\Vecino;
use Database\Factories\VecinoFactory;

trait CreatesVecinos
{
    protected function createVecino(array $attributes = []): Vecino
    {
        return VecinoFactory::new()->create($attributes);
    }

    protected function ensureCategoriaServicio(string $nombre = 'Domestica'): CategoriaServicio
    {
        return CategoriaServicio::query()->firstOrCreate(
            ['nombre' => $nombre],
            [
                'descripcion' => 'Categoria de prueba',
                'activa' => true,
            ]
        );
    }
}
