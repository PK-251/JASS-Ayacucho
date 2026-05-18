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
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response;

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

        try {
            DB::statement(
                'CALL sp_registrar_cobro(?, ?, ?, ?, ?, ?, ?, ?, @sp_cobro_id, @sp_numero_serie)',
                [
                    (int) $data['vecino_id'],
                    auth()->id(),
                    $jornada->id,
                    2026,
                    5,
                    $this->money($data['monto_recibido']),
                    $data['metodo_pago'],
                    $data['observaciones'] ?? null,
                ]
            );

            $result = DB::selectOne('SELECT @sp_cobro_id AS cobro_id');
        } catch (\Illuminate\Database\QueryException $e) {
            return back()
                ->withInput()
                ->withErrors(['monto_recibido' => $this->procedureError($e)]);
        }

        $cobro = Cobro::findOrFail((int) $result->cobro_id);

        return redirect()->route('operator.cobros.show', $cobro)->with('success', 'Pago registrado correctamente.');
    }

    public function show(Cobro $cobro): View
    {
        abort_unless($cobro->operador_id === auth()->id(), 403);
        $cobro->load(['vecino.categoria', 'comprobante']);
        return view('operator.cobros.show', compact('cobro'));
    }


    public function pdf(Cobro $cobro): Response
    {
        abort_unless($cobro->operador_id === auth()->id(), 403);
        $cobro->load(['vecino.categoria', 'operador', 'comprobante']);
        $pdf = Pdf::loadView('admin.cobros.pdf', ['cobro' => $cobro])->setPaper('a5');

        return $pdf->download($cobro->numero_serie.'.pdf');
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
        $anio ??= (int) now()->year;
        $mes ??= (int) now()->month;

        try {
            $row = DB::selectOne('CALL sp_calcular_deuda_vecino(?, ?, ?)', [$vecino->id, $anio, $mes]);

            return [
                'cuota' => $this->money($row->cuota ?? 0),
                'deuda_cuotas' => $this->money($row->deuda_cuotas ?? 0),
                'deuda_multas' => $this->money($row->deuda_multas ?? 0),
                'total' => $this->money($row->total ?? 0),
            ];
        } catch (\Illuminate\Database\QueryException) {
            $tarifa = Tarifa::where('categoria_id', $vecino->categoria_id)
                ->where('activa', true)
                ->whereNull('fecha_vigencia_fin')
                ->latest('fecha_vigencia_inicio')
                ->first() ?? Tarifa::where('categoria_id', $vecino->categoria_id)->latest('fecha_vigencia_inicio')->first();
            $cuota = $this->money($tarifa?->monto ?? 0);
            $deudaCuotas = $this->money(PagoPendiente::where('vecino_id', $vecino->id)->where('estado', 'pendiente')->sum('monto_pendiente'));
            $deudaMultas = $this->money(MultaAplicada::where('vecino_id', $vecino->id)->where('estado', 'pendiente')->sum('monto_aplicado'));

            return [
                'cuota' => $cuota,
                'deuda_cuotas' => $deudaCuotas,
                'deuda_multas' => $deudaMultas,
                'total' => $this->money($cuota + $deudaCuotas + $deudaMultas),
            ];
        }
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

    private function procedureError(\Illuminate\Database\QueryException $e): string
    {
        $message = $e->getPrevious()?->getMessage() ?: $e->getMessage();

        if (preg_match('/1644\s+(.+)$/', $message, $matches)) {
            return trim($matches[1]);
        }

        if (str_contains($message, 'CONSTRAINT') || str_contains($message, 'constraint')) {
            return 'No se permiten valores negativos ni montos invalidos.';
        }

        return 'No se pudo completar la operacion en MariaDB. Revisa los datos e intenta nuevamente.';
    }

}