<?php

namespace Tests\Support;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

abstract class SqliteTestCase extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->createMinimalSchema();
    }

    protected function createMinimalSchema(): void
    {
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('login_logs');
        Schema::dropIfExists('cobros');
        Schema::dropIfExists('egresos');
        Schema::dropIfExists('vecinos');
        Schema::dropIfExists('users');
        Schema::dropIfExists('roles');

        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('nombre')->unique();
            $table->string('descripcion')->nullable();
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('username')->unique();
            $table->string('nombres');
            $table->string('apellidos');
            $table->string('email')->nullable()->unique();
            $table->string('password');
            $table->foreignId('rol_id');
            $table->string('estado')->default('activo');
            $table->unsignedTinyInteger('intentos_fallidos')->default(0);
            $table->timestamp('bloqueado_hasta')->nullable();
            $table->boolean('requiere_cambio_password')->default(false);
            $table->timestamp('ultimo_login')->nullable();
            $table->foreignId('created_by')->nullable();
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();
        });

        Schema::create('vecinos', function (Blueprint $table) {
            $table->id();
            $table->string('codigo')->unique();
            $table->string('documento_tipo')->default('DNI');
            $table->string('documento_num')->unique();
            $table->string('nombres');
            $table->string('apellidos');
            $table->string('direccion')->default('Quilcata');
            $table->foreignId('categoria_id')->default(1);
            $table->string('estado')->default('activo');
            $table->boolean('tiene_medidor')->default(false);
            $table->date('fecha_registro')->nullable();
            $table->timestamps();
            $table->timestamp('deleted_at')->nullable();
        });

        Schema::create('cobros', function (Blueprint $table) {
            $table->id();
            $table->string('numero_serie')->nullable();
            $table->foreignId('vecino_id')->nullable();
            $table->foreignId('operador_id')->nullable();
            $table->unsignedSmallInteger('periodo_anio');
            $table->unsignedTinyInteger('periodo_mes');
            $table->decimal('monto_recibido', 8, 2)->default(0);
            $table->string('estado')->default('pagado');
            $table->date('fecha_cobro')->nullable();
            $table->time('hora_cobro')->nullable();
            $table->timestamps();
        });

        Schema::create('egresos', function (Blueprint $table) {
            $table->id();
            $table->decimal('monto', 8, 2)->default(0);
            $table->string('estado')->default('aprobado');
            $table->date('fecha_egreso')->nullable();
            $table->timestamps();
        });

        Schema::create('login_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable();
            $table->string('username_intentado');
            $table->string('ip_address');
            $table->text('user_agent')->nullable();
            $table->string('resultado');
            $table->string('motivo_fallo')->nullable();
            $table->timestamp('fecha_intento')->nullable();
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }
}
