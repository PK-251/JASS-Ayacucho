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
        $anio = (int) $request->query('anio', 2026);
        $mes = (int) $request->query('mes', 5);
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');

        $query = Cobro::query()
            ->with(['vecino', 'operador'])
            ->whereYear('fecha_cobro', $anio)
            ->whereMonth('fecha_cobro', $mes)
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
        $baseMes = Cobro::whereYear('fecha_cobro', $anio)->whereMonth('fecha_cobro', $mes);

        return view('admin.cobros.index', [
            'cobros' => $cobros,
            'buscar' => $buscar,
            'estado' => $estado,
            'anio' => $anio,
            'mes' => $mes,
            'cobrosMes' => (clone $baseMes)->where('estado', 'pagado')->count(),
            'totalRecaudado' => (clone $baseMes)->where('estado', 'pagado')->sum('monto_recibido'),
            'anulados' => (clone $baseMes)->where('estado', 'anulado')->count(),
            'pendientes' => PagoPendiente::where('estado', 'pendiente')->count(),
        ]);
    }

    public function create(Request $request): View
    {
        $buscar = trim((string) $request->query('buscar'));
        $usuarioId = $request->integer('usuario_id');
        $anio = (int) $request->query('anio', 2026);
        $mes = (int) $request->query('mes', 5);

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
        $desglose = $usuario ? $this->desglose($usuario) : null;

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

        $vecino = Vecino::with('categoria')->findOrFail($data['vecino_id']);
        $desglose = $this->desglose($vecino);
        $total = $this->money($desglose['total']);
        $recibido = $this->money($data['monto_recibido']);

        if (abs($recibido - $total) > 0.009) {
            return back()
                ->withInput()
                ->withErrors(['monto_recibido' => 'El monto recibido debe coincidir con el total a cobrar: S/'.number_format($total, 2).'.']);
        }

        $duplicado = Cobro::where('vecino_id', $vecino->id)
            ->where('periodo_anio', $data['periodo_anio'])
            ->where('periodo_mes', $data['periodo_mes'])
            ->where('estado', 'pagado')
            ->exists();

        if ($duplicado) {
            return back()->withInput()->withErrors(['vecino_id' => 'Este usuario ya tiene un cobro pagado para ese periodo.']);
        }

        $cobro = DB::transaction(function () use ($data, $desglose, $total, $recibido) {
            $fecha = now()->toDateString();
            $hora = now()->format('H:i:s');
            $serie = $this->nextSerie((int) $data['periodo_anio']);

            $cobro = Cobro::create([
                'numero_serie' => $serie,
                'vecino_id' => $data['vecino_id'],
                'operador_id' => auth()->id(),
                'jornada_id' => null,
                'periodo_anio' => $data['periodo_anio'],
                'periodo_mes' => $data['periodo_mes'],
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

            PagoPendiente::where('vecino_id', $data['vecino_id'])
                ->where('estado', 'pendiente')
                ->update(['estado' => 'cobrado', 'fecha_cobro' => $fecha, 'cobro_id' => $cobro->id]);

            MultaAplicada::where('vecino_id', $data['vecino_id'])
                ->where('estado', 'pendiente')
                ->update(['estado' => 'cobrada', 'fecha_cobro' => $fecha, 'cobro_id' => $cobro->id]);

            ComprobantePdf::create([
                'cobro_id' => $cobro->id,
                'numero_serie' => $serie,
                'ruta_archivo' => '/storage/comprobantes/'.date('Y').'/'.date('m').'/'.$serie.'.pdf',
                'nombre_archivo' => $serie.'.pdf',
                'codigo_qr_url' => route('admin.cobros.show', $cobro),
                'modalidad_entrega' => 'pendiente',
            ]);

            return $cobro;
        });

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

    private function desglose(Vecino $vecino): array
    {
        $tarifa = Tarifa::where('categoria_id', $vecino->categoria_id)
            ->where('activa', true)
            ->whereNull('fecha_vigencia_fin')
            ->latest('fecha_vigencia_inicio')
            ->first()
            ?? Tarifa::where('categoria_id', $vecino->categoria_id)->latest('fecha_vigencia_inicio')->first();

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

    private function nextSerie(int $year): string
    {
        $last = Cobro::where('numero_serie', 'like', "QLC-{$year}-%")
            ->orderByDesc('id')
            ->value('numero_serie');

        $next = 1;
        if ($last && preg_match('/(\d{4})$/', $last, $matches)) {
            $next = ((int) $matches[1]) + 1;
        }

        return 'QLC-'.$year.'-'.str_pad((string) $next, 4, '0', STR_PAD_LEFT);
    }

    private function money(mixed $value): float
    {
        return round((float) $value, 2);
    }
}
