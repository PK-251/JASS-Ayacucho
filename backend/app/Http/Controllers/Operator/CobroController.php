<?php

namespace App\Http\Controllers\Operator;

use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\ComprobantePdf;
use App\Models\JornadaCobro;
use App\Models\MultaAplicada;
use App\Models\PagoPendiente;
use App\Models\Tarifa;
use App\Models\Vecino;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class CobroController extends Controller
{
    public function index(Request $request): View
    {
        $buscar = trim((string) $request->query('buscar'));
        $usuarioId = $request->integer('usuario_id');
        $jornada = $this->activeJornada();

        $usuarios = Vecino::query()
            ->with('categoria')
            ->whereNull('deleted_at')
            ->whereIn('estado', ['activo', 'suspendido', 'cortado'])
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('codigo', 'like', "%{$buscar}%")
                        ->orWhere('documento_num', 'like', "%{$buscar}%")
                        ->orWhere('nombres', 'like', "%{$buscar}%")
                        ->orWhere('apellidos', 'like', "%{$buscar}%");
                });
            })
            ->orderBy('codigo')
            ->limit(10)
            ->get()
            ->map(function ($vecino) {
                $vecino->deuda_total = $this->desglose($vecino, 2026, 5)['total'];
                return $vecino;
            });

        $usuario = $usuarioId ? Vecino::with('categoria')->whereNull('deleted_at')->find($usuarioId) : $usuarios->first();
        $desglose = $usuario ? $this->desglose($usuario, 2026, 5) : null;

        $stats = [
            'cobrados' => Cobro::where('operador_id', auth()->id())->whereDate('fecha_cobro', now()->toDateString())->where('estado', 'pagado')->count(),
            'recaudado' => Cobro::where('operador_id', auth()->id())->whereDate('fecha_cobro', now()->toDateString())->where('estado', 'pagado')->sum('monto_recibido'),
            'pendientes' => PagoPendiente::where('estado', 'pendiente')->count(),
        ];

        return view('operator.cobros.index', compact('usuarios', 'usuario', 'desglose', 'buscar', 'jornada', 'stats'));
    }

    public function iniciar(): RedirectResponse
    {
        if ($this->activeJornada()) {
            return redirect()->route('operator.cobros.index')->with('success', 'Ya tienes una jornada activa.');
        }

        JornadaCobro::create([
            'operador_id' => auth()->id(),
            'fecha_inicio' => now(),
            'estado' => 'activa',
        ]);

        return redirect()->route('operator.cobros.index')->with('success', 'Jornada de cobro iniciada.');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'vecino_id' => ['required', 'exists:vecinos,id'],
            'monto_recibido' => ['required', 'numeric', 'min:0'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'observaciones' => ['nullable', 'string', 'max:500'],
        ]);

        $jornada = $this->activeJornada() ?: JornadaCobro::create([
            'operador_id' => auth()->id(),
            'fecha_inicio' => now(),
            'estado' => 'activa',
        ]);

        $vecino = Vecino::with('categoria')->findOrFail($data['vecino_id']);
        $desglose = $this->desglose($vecino, 2026, 5);
        $total = $this->money($desglose['total']);
        $recibido = $this->money($data['monto_recibido']);

        if (abs($recibido - $total) > 0.009) {
            return back()->withInput()->withErrors(['monto_recibido' => 'El monto debe coincidir con el total: S/'.number_format($total, 2).'.']);
        }

        $duplicado = Cobro::where('vecino_id', $vecino->id)
            ->where('periodo_anio', 2026)
            ->where('periodo_mes', 5)
            ->where('estado', 'pagado')
            ->exists();

        if ($duplicado) {
            return back()->withInput()->withErrors(['vecino_id' => 'Este usuario ya pago el periodo actual.']);
        }

        $cobro = DB::transaction(function () use ($data, $desglose, $total, $recibido, $jornada) {
            $serie = $this->nextSerie(2026);
            $fecha = now()->toDateString();
            $hora = now()->format('H:i:s');

            $cobro = Cobro::create([
                'numero_serie' => $serie,
                'vecino_id' => $data['vecino_id'],
                'operador_id' => auth()->id(),
                'jornada_id' => $jornada->id,
                'periodo_anio' => 2026,
                'periodo_mes' => 5,
                'monto_cuota' => $this->money($desglose['cuota']),
                'monto_deuda_anterior' => $this->money($desglose['deuda_cuotas']),
                'monto_multas' => $this->money($desglose['deuda_multas']),
                'monto_total' => $total,
                'monto_recibido' => $recibido,
                'metodo_pago' => $data['metodo_pago'],
                'estado' => 'pagado',
                'fecha_cobro' => $fecha,
                'hora_cobro' => $hora,
                'observaciones' => $data['observaciones'] ?? null,
            ]);

            PagoPendiente::where('vecino_id', $data['vecino_id'])->where('estado', 'pendiente')
                ->update(['estado' => 'cobrado', 'fecha_cobro' => $fecha, 'cobro_id' => $cobro->id]);

            MultaAplicada::where('vecino_id', $data['vecino_id'])->where('estado', 'pendiente')
                ->update(['estado' => 'cobrada', 'fecha_cobro' => $fecha, 'cobro_id' => $cobro->id]);

            ComprobantePdf::create([
                'cobro_id' => $cobro->id,
                'numero_serie' => $serie,
                'ruta_archivo' => '/storage/comprobantes/'.date('Y').'/'.date('m').'/'.$serie.'.pdf',
                'nombre_archivo' => $serie.'.pdf',
                'codigo_qr_url' => route('operator.cobros.show', $cobro),
                'modalidad_entrega' => 'pendiente',
            ]);

            $this->refreshJornada($jornada);

            return $cobro;
        });

        return redirect()->route('operator.cobros.show', $cobro)->with('success', 'Pago registrado correctamente.');
    }

    public function show(Cobro $cobro): View
    {
        abort_unless($cobro->operador_id === auth()->id(), 403);
        $cobro->load(['vecino.categoria', 'comprobante']);
        return view('operator.cobros.show', compact('cobro'));
    }

    public function pendiente(Request $request, Vecino $vecino): RedirectResponse
    {
        $data = $request->validate(['motivo' => ['nullable', 'string', 'max:500']]);
        $jornada = $this->activeJornada() ?: JornadaCobro::create([
            'operador_id' => auth()->id(),
            'fecha_inicio' => now(),
            'estado' => 'activa',
        ]);
        $desglose = $this->desglose($vecino);

        PagoPendiente::firstOrCreate([
            'vecino_id' => $vecino->id,
            'periodo_anio' => 2026,
            'periodo_mes' => 5,
            'estado' => 'pendiente',
        ], [
            'monto_pendiente' => max(0.01, $this->money($desglose['cuota'])),
            'fecha_intento' => now()->toDateString(),
            'motivo' => $data['motivo'] ?? 'Usuario no atendido durante la jornada',
            'jornada_id' => $jornada->id,
            'registrado_por' => auth()->id(),
        ]);

        $this->refreshJornada($jornada);
        return redirect()->route('operator.cobros.index')->with('success', 'Usuario marcado como pendiente.');
    }

    public function cerrar(Request $request): RedirectResponse
    {
        $data = $request->validate(['observaciones' => ['nullable', 'string', 'max:500']]);
        $jornada = $this->activeJornada();
        if (! $jornada) {
            return redirect()->route('operator.dashboard')->with('success', 'No tienes una jornada activa.');
        }

        $this->refreshJornada($jornada);
        $jornada->update([
            'estado' => 'cerrada',
            'fecha_cierre' => now(),
            'observaciones' => $data['observaciones'] ?? null,
        ]);

        return redirect()->route('operator.dashboard')->with('success', 'Jornada cerrada correctamente.');
    }

    private function activeJornada(): ?JornadaCobro
    {
        return JornadaCobro::where('operador_id', auth()->id())->where('estado', 'activa')->latest('fecha_inicio')->first();
    }

    private function refreshJornada(JornadaCobro $jornada): void
    {
        $jornada->update([
            'total_vecinos_atendidos' => Cobro::where('jornada_id', $jornada->id)->where('estado', 'pagado')->count(),
            'total_recaudado' => Cobro::where('jornada_id', $jornada->id)->where('estado', 'pagado')->sum('monto_recibido'),
            'total_pendientes_registrados' => PagoPendiente::where('jornada_id', $jornada->id)->where('estado', 'pendiente')->count(),
        ]);
    }

    private function desglose(Vecino $vecino, ?int $anio = null, ?int $mes = null): array
    {
        $tarifa = Tarifa::where('categoria_id', $vecino->categoria_id)
            ->where('activa', true)
            ->whereNull('fecha_vigencia_fin')
            ->latest('fecha_vigencia_inicio')
            ->first() ?? Tarifa::where('categoria_id', $vecino->categoria_id)->latest('fecha_vigencia_inicio')->first();

        $cuota = $this->money($tarifa?->monto ?? 0);
        $pendientesQuery = PagoPendiente::where('vecino_id', $vecino->id)->where('estado', 'pendiente');
        if ($anio && $mes) {
            $pendientesQuery->where(function ($query) use ($anio, $mes) {
                $query->where('periodo_anio', '<>', $anio)
                    ->orWhere('periodo_mes', '<>', $mes);
            });
        }
        $deudaCuotas = $this->money($pendientesQuery->sum('monto_pendiente'));
        $deudaMultas = $this->money(MultaAplicada::where('vecino_id', $vecino->id)->where('estado', 'pendiente')->sum('monto_aplicado'));

        return [
            'cuota' => $cuota,
            'deuda_cuotas' => $deudaCuotas,
            'deuda_multas' => $deudaMultas,
            'total' => $this->money($cuota + $deudaCuotas + $deudaMultas),
        ];
    }

    private function nextSerie(int $year): string
    {
        $max = Cobro::where('numero_serie', 'like', "QLC-{$year}-%")
            ->selectRaw('MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)) as max_num')
            ->value('max_num');
        return 'QLC-'.$year.'-'.str_pad(((int) $max) + 1, 4, '0', STR_PAD_LEFT);
    }

    private function money(float|int|string $value): float
    {
        return round((float) $value, 2);
    }
}
