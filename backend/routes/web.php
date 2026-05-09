<?php

use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\CobroController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Operator\DashboardController as OperatorDashboardController;
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
});

Route::middleware(['auth', 'role:Operador'])->prefix('operador')->name('operator.')->group(function () {
    Route::get('/inicio', OperatorDashboardController::class)->name('dashboard');
});
