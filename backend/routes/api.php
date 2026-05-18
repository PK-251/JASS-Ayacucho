<?php

use App\Http\Controllers\Api\V1\AsistenciaController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\CobroController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\EgresoController;
use App\Http\Controllers\Api\V1\IngresoController;
use App\Http\Controllers\Api\V1\MultaTarifaController;
use App\Http\Controllers\Api\V1\ReporteController;
use App\Http\Controllers\Api\V1\UsuarioController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])->name('api.login');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/catalogos', [CatalogController::class, 'index']);

        Route::middleware('api.role:Administrador')->prefix('admin')->group(function () {
            Route::get('/dashboard', [DashboardController::class, 'admin']);

            Route::get('/usuarios/categorias', [UsuarioController::class, 'categorias']);
            Route::get('/usuarios/{usuario}/deuda', [UsuarioController::class, 'deuda']);
            Route::apiResource('/usuarios', UsuarioController::class)->parameters(['usuarios' => 'usuario']);

            Route::get('/cobros/usuarios/{usuario}/deuda', [CobroController::class, 'deuda']);
            Route::post('/cobros/usuarios/{usuario}/pendiente', [CobroController::class, 'pendiente']);
            Route::apiResource('/cobros', CobroController::class)->only(['index', 'store', 'show']);

            Route::get('/ingresos/categorias', [IngresoController::class, 'categorias']);
            Route::apiResource('/ingresos', IngresoController::class);

            Route::get('/egresos/catalogos', [EgresoController::class, 'catalogos']);
            Route::post('/egresos/{egreso}/aprobar', [EgresoController::class, 'approve']);
            Route::post('/egresos/{egreso}/rechazar', [EgresoController::class, 'reject']);
            Route::apiResource('/egresos', EgresoController::class);

            Route::get('/multas-tarifas', [MultaTarifaController::class, 'index']);
            Route::post('/multas', [MultaTarifaController::class, 'storeMulta']);
            Route::put('/multas/{multa}', [MultaTarifaController::class, 'updateMulta']);
            Route::delete('/multas/{multa}', [MultaTarifaController::class, 'destroyMulta']);
            Route::post('/tarifas', [MultaTarifaController::class, 'storeTarifa']);

            Route::get('/reportes', [ReporteController::class, 'index']);
            Route::post('/reportes/parcial', [ReporteController::class, 'parcial']);
            Route::get('/reportes/{reporte}', [ReporteController::class, 'show']);
            Route::post('/reportes/{reporte}/aprobar', [ReporteController::class, 'aprobar']);
            Route::post('/reportes/{reporte}/rechazar', [ReporteController::class, 'rechazar']);

            Route::get('/asistencia', [AsistenciaController::class, 'index']);
            Route::get('/asistencia/{evento}', [AsistenciaController::class, 'show']);
            Route::post('/asistencia/{evento}/generar-lista', [AsistenciaController::class, 'generarLista']);
            Route::patch('/asistencia/marca/{asistencia}', [AsistenciaController::class, 'update']);
            Route::post('/asistencia/{evento}/confirmar', [AsistenciaController::class, 'confirmar']);
        });

        Route::middleware('api.role:Operador')->prefix('operador')->group(function () {
            Route::get('/dashboard', [DashboardController::class, 'operador']);
            Route::get('/cobros', [CobroController::class, 'index']);
            Route::post('/cobros/iniciar-jornada', [CobroController::class, 'iniciarJornada']);
            Route::post('/cobros/cerrar-jornada', [CobroController::class, 'cerrarJornada']);
            Route::get('/cobros/usuarios/{usuario}/deuda', [CobroController::class, 'deuda']);
            Route::post('/cobros/usuarios/{usuario}/pendiente', [CobroController::class, 'pendiente']);
            Route::post('/cobros', [CobroController::class, 'store']);
            Route::get('/cobros/{cobro}', [CobroController::class, 'show']);

            Route::get('/asistencia', [AsistenciaController::class, 'index']);
            Route::get('/asistencia/{evento}', [AsistenciaController::class, 'show']);
            Route::patch('/asistencia/marca/{asistencia}', [AsistenciaController::class, 'update']);
            Route::post('/asistencia/{evento}/confirmar', [AsistenciaController::class, 'confirmar']);
        });
    });
});
