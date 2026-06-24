<?php

namespace Tests\Integration\Database;

use App\Models\Vecino;
use Illuminate\Support\Facades\DB;
use Tests\Support\MariaDbTestCase;

class MariaDbSmokeTest extends MariaDbTestCase
{
    public function test_conexion_mariadb_responde(): void
    {
        $result = DB::selectOne('SELECT 1 AS ok');

        $this->assertSame(1, (int) $result->ok);
    }

    public function test_sp_calcular_deuda_vecino_con_vecino_del_seed(): void
    {
        $vecino = Vecino::query()->where('codigo', 'U-0001')->first();

        $this->assertNotNull($vecino, 'Se esperaba el vecino U-0001 del SQL base.');

        $anio = (int) now()->format('Y');
        $mes = (int) now()->format('n');

        $deuda = DB::selectOne(
            'CALL sp_calcular_deuda_vecino(?, ?, ?)',
            [$vecino->id, $anio, $mes]
        );

        $this->assertNotNull($deuda);
        $this->assertObjectHasProperty('cuota', $deuda);
        $this->assertObjectHasProperty('deuda_cuotas', $deuda);
        $this->assertObjectHasProperty('deuda_multas', $deuda);
        $this->assertObjectHasProperty('total', $deuda);
        $this->assertGreaterThanOrEqual(0, (float) $deuda->total);
    }
}
