<?php

namespace Tests\Support\Concerns;

use App\Models\Cobro;
use App\Models\User;
use App\Models\Vecino;

trait CreatesCobros
{
    protected function cobroAttributesFor(Vecino $vecino, ?User $operador = null, array $overrides = []): array
    {
        return array_merge([
            'vecino_id' => $vecino->id,
            'operador_id' => $operador?->id,
            'periodo_anio' => (int) now()->format('Y'),
            'periodo_mes' => (int) now()->format('n'),
            'monto_recibido' => 4.00,
            'estado' => 'pagado',
            'fecha_cobro' => now()->toDateString(),
        ], $overrides);
    }

    protected function createCobroRecord(Vecino $vecino, ?User $operador = null, array $overrides = []): Cobro
    {
        return Cobro::query()->create($this->cobroAttributesFor($vecino, $operador, $overrides));
    }
}
