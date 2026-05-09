<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\Egreso;
use App\Models\Vecino;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $totalUsuarios = Vecino::whereNull('deleted_at')->count();
        $alDia = Vecino::whereNull('deleted_at')->where('estado', 'activo')->count();
        $morosos = Vecino::whereNull('deleted_at')->whereIn('estado', ['suspendido', 'cortado'])->count();

        $ingresosMes = Cobro::where('estado', 'pagado')
            ->whereYear('fecha_cobro', 2026)
            ->whereMonth('fecha_cobro', 5)
            ->sum('monto_recibido');

        $egresosMes = Egreso::where('estado', 'aprobado')
            ->whereYear('fecha_egreso', 2026)
            ->whereMonth('fecha_egreso', 5)
            ->sum('monto');

        $movimientos = Cobro::with('vecino')
            ->latest('fecha_cobro')
            ->latest('hora_cobro')
            ->limit(5)
            ->get();

        return view('admin.dashboard', [
            'totalUsuarios' => $totalUsuarios,
            'alDia' => $alDia,
            'morosos' => $morosos,
            'balanceMes' => (float) $ingresosMes - (float) $egresosMes,
            'movimientos' => $movimientos,
        ]);
    }
}
