<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\Egreso;
use App\Models\Evento;
use App\Models\JornadaCobro;
use App\Models\PagoPendiente;
use App\Models\Vecino;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class DashboardController extends Controller
{
    use ApiHelpers;

    public function admin(Request $request)
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $inicio = sprintf('%04d-%02d-01', $anio, $mes);
        $fin = date('Y-m-t', strtotime($inicio));

        $kpis = Cache::remember("dashboard:api:admin:{$anio}:{$mes}", 300, function () use ($anio, $mes, $inicio, $fin) {
            $base = Vecino::whereNull('deleted_at');
        
            $ingresosMes = Cobro::where('estado', 'pagado')
                ->where('periodo_anio', $anio)
                ->where('periodo_mes', $mes)
                ->sum('monto_recibido');
        
            $egresosMes = Egreso::where('estado', 'aprobado')
                ->whereBetween('fecha_egreso', [$inicio, $fin])
                ->sum('monto');
        
            $balance = round((float) $ingresosMes - (float) $egresosMes, 2);
        
            return [
                'total_usuarios' => (clone $base)->count(),
                'al_dia' => (clone $base)->where('estado', 'activo')->count(),
                'morosos' => (clone $base)->whereIn('estado', ['suspendido', 'cortado'])->count(),
                'balance_mes' => $balance,
                'balance_estado' => $balance < 0 ? 'deficit' : 'neto',
            ];
        });

        return $this->ok([
            'periodo' => ['anio' => $anio, 'mes' => $mes],
            'kpis' => $kpis,
            'ultimos_movimientos' => Cobro::with('vecino:id,codigo,nombres,apellidos')
                ->latest('fecha_cobro')->latest('hora_cobro')->limit(5)->get(),
        ]);
    }

    public function operador(Request $request)
    {
        $user = $request->user();
        $jornada = JornadaCobro::where('operador_id', $user->id)->where('estado', 'activa')->latest('fecha_inicio')->first();

        return $this->ok([
            'jornada_activa' => $jornada,
            'kpis' => [
                'cobros_hoy' => Cobro::where('operador_id', $user->id)->where('estado', 'pagado')->whereDate('fecha_cobro', now()->toDateString())->count(),
                'recaudado_hoy' => $this->money(Cobro::where('operador_id', $user->id)->where('estado', 'pagado')->whereDate('fecha_cobro', now()->toDateString())->sum('monto_recibido')),
                'pendientes' => PagoPendiente::where('estado', 'pendiente')->count(),
                'proximo_evento' => Evento::with('tipo')->whereIn('estado', ['programado', 'lista_pendiente'])->whereNull('deleted_at')->orderBy('fecha_evento')->first(),
            ],
            'actividad_reciente' => Cobro::with('vecino:id,codigo,nombres,apellidos')->where('operador_id', $user->id)->latest('fecha_cobro')->latest('hora_cobro')->limit(5)->get(),
        ]);
    }
}
