<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\ComprobantePdf;
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
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');

        $query = Cobro::query()
            ->with(['vecino', 'operador'])
            ->where('periodo_anio', $anio)
            ->where('periodo_mes', $mes)
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('numero_serie', 'like', "%{$buscar}%")
                        ->orWhereHas('vecino', function ($vecino) use ($buscar) {
                            $vecino->where('codigo', 'like', "%{$buscar}%")
                                ->orWhere('documento_num', 'like', "%{$buscar}%")
                                ->orWhere('nombres', 'like', "%{$buscar}%")
                                ->orWhere('apellidos', 'like', "%{$buscar}%");
                        });
                });
            })
            ->orderByDesc('fecha_cobro')
            ->orderByDesc('hora_cobro');

        $cobros = $query->paginate(10)->withQueryString();

        $stats = Cobro::query()
            ->where('periodo_anio', $anio)
            ->where('periodo_mes', $mes)
            ->selectRaw("
                COUNT(CASE WHEN estado = 'pagado' THEN 1 END) AS cobros_mes,
                COALESCE(SUM(CASE WHEN estado = 'pagado' THEN monto_recibido END), 0) AS total_recaudado,
                COUNT(CASE WHEN estado = 'anulado' THEN 1 END) AS anulados
            ")
            ->first();

        $pendientes = PagoPendiente::where('estado', 'pendiente')->count();

        return view('admin.cobros.index', [
            'cobros' => $cobros,
            'buscar' => $buscar,
            'estado' => $estado,
            'anio' => $anio,
            'mes' => $mes,
            'cobrosMes' => (int) $stats->cobros_mes,
            'totalRecaudado' => (float) $stats->total_recaudado,
            'anulados' => (int) $stats->anulados,
            'pendientes' => $pendientes,
        ]);
    }

    public function create(Request $request): View
    {
        $buscar = trim((string) $request->query('buscar'));
        $usuarioId = $request->integer('usuario_id');
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);

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
            ->limit(12)
            ->get();

        $usuario = $usuarioId ? Vecino::with('categoria')->whereNull('deleted_at')->find($usuarioId) : null;
        $desglose = $usuario ? $this->desglose($usuario, $anio, $mes) : null;

        return view('admin.cobros.create', [
            'usuarios' => $usuarios,
            'usuario' => $usuario,
            'desglose' => $desglose,
            'buscar' => $buscar,
            'anio' => $anio,
            'mes' => $mes,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'vecino_id' => ['required', 'exists:vecinos,id'],
            'periodo_anio' => ['required', 'integer', 'between:2020,2100'],
            'periodo_mes' => ['required', 'integer', 'between:1,12'],
            'monto_recibido' => ['required', 'numeric', 'min:0'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'observaciones' => ['nullable', 'string', 'max:500'],
        ]);

        try {
            DB::statement(
                'CALL sp_registrar_cobro(?, ?, ?, ?, ?, ?, ?, ?, @sp_cobro_id, @sp_numero_serie)',
                [
                    (int) $data['vecino_id'],
                    auth()->id(),
                    null,
                    (int) $data['periodo_anio'],
                    (int) $data['periodo_mes'],
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

        return redirect()->route('admin.cobros.show', $cobro)->with('success', 'Cobro registrado correctamente.');
    }

    public function show(Cobro $cobro): View
    {
        $cobro->load(['vecino.categoria', 'operador', 'comprobante']);

        return view('admin.cobros.show', [
            'cobro' => $cobro,
            'pendientesCobrados' => PagoPendiente::where('cobro_id', $cobro->id)->get(),
            'multasCobradas' => MultaAplicada::with('multa')->where('cobro_id', $cobro->id)->get(),
        ]);
    }

    public function edit(Cobro $cobro): View
    {
        abort_if($cobro->estado === 'anulado', 404);
        $cobro->load('vecino');

        return view('admin.cobros.edit', ['cobro' => $cobro]);
    }

    public function update(Request $request, Cobro $cobro): RedirectResponse
    {
        abort_if($cobro->estado === 'anulado', 404);

        $data = $request->validate([
            'monto_recibido' => ['required', 'numeric', 'min:0'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'observaciones' => ['nullable', 'string', 'max:500'],
            'motivo_ultima_edicion' => ['required', 'string', 'max:500'],
        ]);

        $cobro->update([
            'monto_recibido' => $this->money($data['monto_recibido']),
            'metodo_pago' => $data['metodo_pago'],
            'observaciones' => $data['observaciones'] ?? null,
            'motivo_ultima_edicion' => $data['motivo_ultima_edicion'],
            'editado_por' => auth()->id(),
            'fecha_ultima_edicion' => now(),
        ]);

        return redirect()->route('admin.cobros.show', $cobro)->with('success', 'Cobro actualizado correctamente.');
    }

    public function destroy(Request $request, Cobro $cobro): RedirectResponse
    {
        $data = $request->validate([
            'motivo_anulacion' => ['required', 'string', 'max:500'],
            'devolver_dinero' => ['nullable', 'boolean'],
        ]);

        if ($cobro->estado === 'anulado') {
            return redirect()->route('admin.cobros.show', $cobro)->with('success', 'El cobro ya estaba anulado.');
        }

        DB::transaction(function () use ($cobro, $data) {
            $cobro->update([
                'estado' => 'anulado',
                'motivo_anulacion' => $data['motivo_anulacion'],
                'anulado_por' => auth()->id(),
                'fecha_anulacion' => now(),
                'devolver_dinero' => (bool) ($data['devolver_dinero'] ?? false),
            ]);

            PagoPendiente::where('cobro_id', $cobro->id)
                ->update(['estado' => 'pendiente', 'fecha_cobro' => null, 'cobro_id' => null]);

            MultaAplicada::where('cobro_id', $cobro->id)
                ->update(['estado' => 'pendiente', 'fecha_cobro' => null, 'cobro_id' => null]);
        });

        return redirect()->route('admin.cobros.index')->with('success', 'Cobro anulado y deudas restauradas correctamente.');
    }

    public function pdf(Cobro $cobro): Response
    {
        $cobro->load(['vecino.categoria', 'operador', 'comprobante']);
        $pdf = Pdf::loadView('admin.cobros.pdf', ['cobro' => $cobro])->setPaper('a5');

        return $pdf->download($cobro->numero_serie.'.pdf');
    }

    private function desglose(Vecino $vecino, ?int $anio = null, ?int $mes = null): array
    {
        $anio ??= (int) now()->year;
        $mes ??= (int) now()->month;

        $tarifa = Tarifa::where('categoria_id', $vecino->categoria_id)
            ->where('activa', true)
            ->whereNull('fecha_vigencia_fin')
            ->latest('fecha_vigencia_inicio')
            ->first()
            ?? Tarifa::where('categoria_id', $vecino->categoria_id)->latest('fecha_vigencia_inicio')->first();

        try {
            $row = DB::selectOne('CALL sp_calcular_deuda_vecino(?, ?, ?)', [$vecino->id, $anio, $mes]);

            return [
                'tarifa' => $tarifa,
                'cuota' => $this->money($row->cuota ?? 0),
                'deuda_cuotas' => $this->money($row->deuda_cuotas ?? 0),
                'deuda_multas' => $this->money($row->deuda_multas ?? 0),
                'total' => $this->money($row->total ?? 0),
            ];
        } catch (\Illuminate\Database\QueryException) {
            $cuota = $this->money($tarifa?->monto ?? 0);
            $deudaCuotas = $this->money(PagoPendiente::where('vecino_id', $vecino->id)->where('estado', 'pendiente')->sum('monto_pendiente'));
            $deudaMultas = $this->money(MultaAplicada::where('vecino_id', $vecino->id)->where('estado', 'pendiente')->sum('monto_aplicado'));

            return [
                'tarifa' => $tarifa,
                'cuota' => $cuota,
                'deuda_cuotas' => $deudaCuotas,
                'deuda_multas' => $deudaMultas,
                'total' => $this->money($cuota + $deudaCuotas + $deudaMultas),
            ];
        }
    }

    private function nextSerie(int $year): string
    {
        $lastNumber = Cobro::where('numero_serie', 'like', "QLC-{$year}-%")
            ->selectRaw('MAX(CAST(RIGHT(numero_serie, 4) AS UNSIGNED)) as last_number')
            ->value('last_number');

        $next = ((int) $lastNumber) + 1;

        return 'QLC-'.$year.'-'.str_pad((string) $next, 4, '0', STR_PAD_LEFT);
    }

    private function money(mixed $value): float
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