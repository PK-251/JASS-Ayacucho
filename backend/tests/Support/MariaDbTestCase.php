<?php

namespace Tests\Support;

use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

abstract class MariaDbTestCase extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        try {
            parent::setUp();
        } catch (\PDOException) {
            $this->markTestSkipped(
                'MariaDB de pruebas no disponible. Levante Docker (puerto 3307) y ejecute: composer test:setup-db'
            );
        }

        if (! $this->isMariaDbAvailable()) {
            $this->markTestSkipped(
                'Base de datos jass_quilcata_test no seleccionada. Ejecute: composer test:setup-db'
            );
        }

        if (! $this->storedProceduresAreLoaded()) {
            $this->markTestSkipped(
                'Procedimientos almacenados no encontrados en jass_quilcata_test. Ejecute: composer test:setup-db'
            );
        }
    }

    protected function isMariaDbAvailable(): bool
    {
        try {
            DB::connection()->getPdo();

            $database = DB::selectOne('SELECT DATABASE() AS db');

            return $database && $database->db === 'jass_quilcata_test';
        } catch (\Throwable) {
            return false;
        }
    }

    protected function storedProceduresAreLoaded(): bool
    {
        $procedure = DB::selectOne(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES
             WHERE ROUTINE_SCHEMA = 'jass_quilcata_test'
               AND ROUTINE_NAME = 'sp_calcular_deuda_vecino'
             LIMIT 1"
        );

        return $procedure !== null;
    }
}
