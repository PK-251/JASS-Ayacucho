<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Foundation\Testing\DatabaseTransactions;

abstract class TestCase extends BaseTestCase
{
    // Revierte cualquier cambio en la base de datos tras finalizar cada prueba
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutVite();
    }
}
