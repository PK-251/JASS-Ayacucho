<?php

namespace App\Http\Controllers\Operator;

use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\Evento;
use App\Models\JornadaCobro;
use App\Models\PagoPendiente;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $jornada = JornadaCobro::where('operador_id', auth()->id())
            ->where('estado', 'activa')
            ->latest('fecha_inicio')
            ->first();

        $cobrosHoy = Cobro::where('operador_id', auth()->id())
            ->whereDate('fecha_cobro', now()->toDateString())
            ->where('estado', 'pagado')
            ->count();

        $recaudadoHoy = Cobro::where('operador_id', auth()->id())
            ->whereDate('fecha_cobro', now()->toDateString())
            ->where('estado', 'pagado')
            ->sum('monto_recibido');

        return view('operator.dashboard', [
            'jornada' => $jornada,
            'cobrosHoy' => $cobrosHoy,
            'recaudadoHoy' => $recaudadoHoy,
            'pendientes' => PagoPendiente::where('estado', 'pendiente')->count(),
            'proximoEvento' => Evento::whereIn('estado', ['programado', 'lista_pendiente'])->orderBy('fecha_evento')->first(),
        ]);
    }
}
