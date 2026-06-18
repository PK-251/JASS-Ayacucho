<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\Egreso;
use App\Models\Vecino;
use Illuminate\Support\Facades\Cache;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $anio = (int) now()->year;
        $mes = (int) now()->month;
        $inicio = sprintf('%04d-%02d-01', $anio, $mes);
        $fin = date('Y-m-t', strtotime($inicio));

        $metricas = Cache::remember("dashboard:web:admin:{$anio}:{$mes}", 300, function () use ($anio, $mes, $inicio, $fin) {
            $totalUsuarios = Vecino::whereNull('deleted_at')->count();
            $alDia = Vecino::whereNull('deleted_at')->where('estado', 'activo')->count();
            $morosos = Vecino::whereNull('deleted_at')->whereIn('estado', ['suspendido', 'cortado'])->count();

            $ingresosMes = Cobro::where('estado', 'pagado')
                ->where('periodo_anio', $anio)
                ->where('periodo_mes', $mes)
                ->sum('monto_recibido');

            $egresosMes = Egreso::where('estado', 'aprobado')
                ->whereBetween('fecha_egreso', [$inicio, $fin])
                ->sum('monto');

            $balanceMes = (float) $ingresosMes - (float) $egresosMes;

            return [
                'totalUsuarios' => $totalUsuarios,
                'alDia' => $alDia,
                'morosos' => $morosos,
                'balanceMes' => $balanceMes,
                'balanceEsDeficit' => $balanceMes < 0,
            ];
        });

        $movimientos = Cobro::with('vecino')
            ->latest('fecha_cobro')
            ->latest('hora_cobro')
            ->limit(5)
            ->get();

        return view('admin.dashboard', [
            'totalUsuarios' => $metricas['totalUsuarios'],
            'alDia' => $metricas['alDia'],
            'morosos' => $metricas['morosos'],
            'balanceMes' => $metricas['balanceMes'],
            'balanceEsDeficit' => $metricas['balanceEsDeficit'],
            'movimientos' => $movimientos,
        ]);
    }
}
