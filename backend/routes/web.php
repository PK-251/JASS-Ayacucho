<?php

use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\CobroController;
use App\Http\Controllers\Admin\IngresoController;
use App\Http\Controllers\Admin\EgresoController;
use App\Http\Controllers\Admin\MultaTarifaController;
use App\Http\Controllers\Admin\ReporteController;
use App\Http\Controllers\Admin\AsistenciaController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Operator\DashboardController as OperatorDashboardController;
use App\Http\Controllers\Operator\CobroController as OperatorCobroController;
use App\Http\Controllers\Operator\AsistenciaController as OperatorAsistenciaController;
use App\Http\Controllers\Admin\UsuarioController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'show'])->name('login');
    Route::post('/login', [LoginController::class, 'login'])->name('login.store');
});

Route::post('/logout', [LoginController::class, 'logout'])->middleware('auth')->name('logout');
Route::get('/logout', [LoginController::class, 'logout'])->middleware('auth')->name('logout.direct');

Route::get('/', function () {
    if (! auth()->check()) {
        return redirect()->route('login');
    }

    return auth()->user()->isOperator()
        ? redirect()->route('operator.dashboard')
        : redirect()->route('admin.dashboard');
});

Route::middleware(['auth', 'role:Administrador'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/inicio', AdminDashboardController::class)->name('dashboard');
    Route::resource('/usuarios', UsuarioController::class)->parameters(['usuarios' => 'usuario']);
    Route::get('/cobros/{cobro}/pdf', [CobroController::class, 'pdf'])->name('cobros.pdf');
    Route::resource('/cobros', CobroController::class);
    Route::resource('/ingresos', IngresoController::class);
    Route::post('/egresos/{egreso}/aprobar', [EgresoController::class, 'approve'])->name('egresos.approve');
    Route::post('/egresos/{egreso}/rechazar', [EgresoController::class, 'reject'])->name('egresos.reject');
    Route::resource('/egresos', EgresoController::class);
    Route::get('/multas', [MultaTarifaController::class, 'index'])->name('multas.index');
    Route::get('/multas/crear', [MultaTarifaController::class, 'createMulta'])->name('multas.create');
    Route::post('/multas', [MultaTarifaController::class, 'storeMulta'])->name('multas.store');
    Route::get('/multas/{multa}/editar', [MultaTarifaController::class, 'editMulta'])->name('multas.edit');
    Route::put('/multas/{multa}', [MultaTarifaController::class, 'updateMulta'])->name('multas.update');
    Route::delete('/multas/{multa}', [MultaTarifaController::class, 'destroyMulta'])->name('multas.destroy');
    Route::get('/tarifas/crear', [MultaTarifaController::class, 'createTarifa'])->name('tarifas.create');
    Route::post('/tarifas', [MultaTarifaController::class, 'storeTarifa'])->name('tarifas.store');
    Route::get('/reportes', [ReporteController::class, 'index'])->name('reportes.index');
    Route::post('/reportes/parcial', [ReporteController::class, 'parcial'])->name('reportes.parcial');
    Route::get('/reportes/{reporte}', [ReporteController::class, 'show'])->name('reportes.show');
    Route::post('/reportes/{reporte}/aprobar', [ReporteController::class, 'aprobar'])->name('reportes.aprobar');
    Route::post('/reportes/{reporte}/rechazar', [ReporteController::class, 'rechazar'])->name('reportes.rechazar');
    Route::get('/reportes/{reporte}/pdf', [ReporteController::class, 'pdf'])->name('reportes.pdf');
    Route::get('/asistencia', [AsistenciaController::class, 'index'])->name('asistencia.index');
    Route::get('/asistencia/crear', [AsistenciaController::class, 'create'])->name('asistencia.create');
    Route::post('/asistencia', [AsistenciaController::class, 'store'])->name('asistencia.store');
    Route::get('/asistencia/{evento}', [AsistenciaController::class, 'show'])->name('asistencia.show');
    Route::post('/asistencia/{evento}/generar-lista', [AsistenciaController::class, 'generarLista'])->name('asistencia.generar-lista');
    Route::patch('/asistencia/marca/{asistencia}', [AsistenciaController::class, 'updateAttendance'])->name('asistencia.update-attendance');
    Route::post('/asistencia/{evento}/confirmar', [AsistenciaController::class, 'confirmar'])->name('asistencia.confirmar');
});

Route::middleware(['auth', 'role:Operador'])->prefix('operador')->name('operator.')->group(function () {
    Route::get('/inicio', OperatorDashboardController::class)->name('dashboard');
    Route::get('/cobros', [OperatorCobroController::class, 'index'])->name('cobros.index');
    Route::post('/cobros/iniciar', [OperatorCobroController::class, 'iniciar'])->name('cobros.iniciar');
    Route::post('/cobros', [OperatorCobroController::class, 'store'])->name('cobros.store');
    Route::get('/cobros/{cobro}', [OperatorCobroController::class, 'show'])->name('cobros.show');
    Route::post('/cobros/{vecino}/pendiente', [OperatorCobroController::class, 'pendiente'])->name('cobros.pendiente');
    Route::post('/cobros/cerrar/jornada', [OperatorCobroController::class, 'cerrar'])->name('cobros.cerrar');
    Route::get('/asistencia', [OperatorAsistenciaController::class, 'index'])->name('asistencia.index');
    Route::get('/asistencia/{evento}', [OperatorAsistenciaController::class, 'show'])->name('asistencia.show');
    Route::patch('/asistencia/marca/{asistencia}', [OperatorAsistenciaController::class, 'update'])->name('asistencia.update');
    Route::post('/asistencia/{evento}/confirmar', [OperatorAsistenciaController::class, 'confirmar'])->name('asistencia.confirmar');
});
