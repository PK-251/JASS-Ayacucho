<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CategoriaIngreso;
use App\Models\Ingreso;
use App\Models\PagoPendiente;
use App\Models\Vecino;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class IngresoController extends Controller
{
    public function index(Request $request): View
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $buscar = trim((string) $request->query('buscar'));
        $origen = (string) $request->query('origen', '');
        $estado = (string) $request->query('estado', '');

        $inicio = sprintf('%04d-%02d-01', $anio, $mes);
        $fin    = date('Y-m-t', strtotime($inicio));

        $base = DB::table('vista_ingresos_completa')
            ->whereBetween('fecha_ingreso', [$inicio, $fin]); // Optimizado: whereBetween usa idx_ingresos_periodo

        $movimientos = (clone $base)
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('numero_serie', 'like', "%{$buscar}%")
                        ->orWhere('vecino_nombre', 'like', "%{$buscar}%")
                        ->orWhere('vecino_codigo', 'like', "%{$buscar}%")
                        ->orWhere('concepto', 'like', "%{$buscar}%");
                });
            })
            ->when($origen !== '', fn ($q) => $q->where('origen', $origen))
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->orderByDesc('fecha_ingreso')
            ->orderByDesc('hora')
            ->paginate(10)
            ->withQueryString();

        $activos = (clone $base)->whereIn('estado', ['pagado', 'activo']);

        $stats = (clone $activos)->selectRaw("
            COUNT(*) as total_transacciones,
            COALESCE(SUM(monto), 0) as total_ingresos,
            COALESCE(AVG(monto), 0) as ticket_promedio,
            COUNT(CASE WHEN origen = 'cobro' THEN 1 END) as de_cobros,
            COUNT(CASE WHEN origen = 'manual' THEN 1 END) as manuales
        ")->first();

        $categorias = (clone $activos)
            ->select('categoria', DB::raw('COUNT(*) as cantidad'), DB::raw('SUM(monto) as total'))
            ->groupBy('categoria')
            ->orderByDesc('total')
            ->get();

        return view('admin.ingresos.index', [
            'movimientos' => $movimientos,
            'buscar' => $buscar,
            'origen' => $origen,
            'estado' => $estado,
            'anio' => $anio,
            'mes' => $mes,
            'totalTransacciones' => (int) $stats->total_transacciones,
            'totalIngresos' => (float) $stats->total_ingresos,
            'ticketPromedio' => (float) $stats->ticket_promedio,
            'deCobros' => (int) $stats->de_cobros,
            'manuales' => (int) $stats->manuales,
            'pendienteCobro' => PagoPendiente::where('estado', 'pendiente')->sum('monto_pendiente'),
            'categorias' => $categorias,
        ]);
    }

    public function create(Request $request): View
    {
        return view('admin.ingresos.create', [
            'categorias' => CategoriaIngreso::where('activa', true)->where('es_manual', true)->orderBy('nombre')->get(),
            'usuarios' => Vecino::whereNull('deleted_at')->where('estado', 'activo')->orderBy('codigo')->limit(80)->get(),
            'serieSugerida' => $this->nextSerie((int) now()->format('Y')),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validatedData($request);
        $year = (int) date('Y', strtotime($data['fecha_ingreso']));
        $serie = $this->nextSerie($year);

        if ($request->hasFile('comprobante')) {
            $file = $request->file('comprobante');
            $name = $serie.'-'.time().'.'.$file->getClientOriginalExtension();
            $data['comprobante_archivo'] = $file->storeAs('comprobantes/ingresos/'.$year, $name, 'public');
            $data['comprobante_nombre'] = $file->getClientOriginalName();
        }

        $ingreso = Ingreso::create([
            ...$data,
            'numero_serie' => $serie,
            'estado' => 'activo',
            'created_by' => auth()->id(),
        ]);

        $this->audit('INSERT', $ingreso, null, 'Registro de ingreso manual');

        return redirect()->route('admin.ingresos.show', $ingreso)->with('success', 'Ingreso manual registrado correctamente.');
    }

    public function show(Ingreso $ingreso): View
    {
        $ingreso->load(['categoria', 'vecino']);

        return view('admin.ingresos.show', ['ingreso' => $ingreso]);
    }

    public function edit(Ingreso $ingreso): View
    {
        abort_if($ingreso->estado === 'anulado', 404);

        return view('admin.ingresos.edit', [
            'ingreso' => $ingreso->load(['categoria', 'vecino']),
            'categorias' => CategoriaIngreso::where('activa', true)->where('es_manual', true)->orderBy('nombre')->get(),
            'usuarios' => Vecino::whereNull('deleted_at')->where('estado', 'activo')->orderBy('codigo')->limit(80)->get(),
        ]);
    }

    public function update(Request $request, Ingreso $ingreso): RedirectResponse
    {
        abort_if($ingreso->estado === 'anulado', 404);

        $data = $this->validatedData($request, true);
        $before = $ingreso->only(['categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']);

        if ($request->hasFile('comprobante')) {
            if ($ingreso->comprobante_archivo) {
                Storage::disk('public')->delete($ingreso->comprobante_archivo);
            }
            $file = $request->file('comprobante');
            $year = (int) date('Y', strtotime($data['fecha_ingreso']));
            $name = $ingreso->numero_serie.'-'.time().'.'.$file->getClientOriginalExtension();
            $data['comprobante_archivo'] = $file->storeAs('comprobantes/ingresos/'.$year, $name, 'public');
            $data['comprobante_nombre'] = $file->getClientOriginalName();
        }

        $ingreso->update([
            ...$data,
            'editado_por' => auth()->id(),
            'fecha_ultima_edicion' => now(),
        ]);

        $this->audit('UPDATE', $ingreso, $before, $data['motivo_ultima_edicion']);

        return redirect()->route('admin.ingresos.show', $ingreso)->with('success', 'Ingreso manual actualizado correctamente.');
    }

    public function destroy(Request $request, Ingreso $ingreso): RedirectResponse
    {
        if ($ingreso->estado === 'anulado') {
            return redirect()->route('admin.ingresos.show', $ingreso)->with('success', 'El ingreso ya estaba anulado.');
        }

        $data = $request->validate([
            'motivo_anulacion' => ['required', 'string', 'max:500'],
            'devolver_dinero' => ['nullable', 'boolean'],
        ]);

        $before = $ingreso->only(['categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']);

        $ingreso->update([
            'estado' => 'anulado',
            'motivo_anulacion' => $data['motivo_anulacion'],
            'anulado_por' => auth()->id(),
            'fecha_anulacion' => now(),
            'devolver_dinero' => (bool) ($data['devolver_dinero'] ?? false),
        ]);

        $this->audit('UPDATE', $ingreso, $before, $data['motivo_anulacion']);

        return redirect()->route('admin.ingresos.index')->with('success', 'Ingreso manual anulado correctamente.');
    }

    private function validatedData(Request $request, bool $editing = false): array
    {
        $rules = [
            'categoria_id' => ['required', Rule::exists('categorias_ingreso', 'id')->where('es_manual', true)->where('activa', true)],
            'vecino_id' => ['nullable', 'exists:vecinos,id'],
            'concepto' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string', 'max:1000'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'fecha_ingreso' => ['required', 'date'],
            'observaciones' => ['nullable', 'string', 'max:500'],
            'comprobante' => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:5120'],
        ];

        if ($editing) {
            $rules['motivo_ultima_edicion'] = ['required', 'string', 'max:500'];
        }

        $data = $request->validate($rules);
        unset($data['comprobante']);
        return $data;
    }

    private function nextSerie(int $year): string
    {
        $lastNumber = (int) DB::table('ingresos')
            ->where('numero_serie', 'like', "ING-{$year}-%")
            ->selectRaw("COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) AS last_number")
            ->value('last_number');

        return 'ING-'.$year.'-'.str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    private function audit(string $operation, Ingreso $ingreso, ?array $before, ?string $reason): void
    {
        DB::statement('CALL sp_audit_log(?, ?, ?, ?, ?, ?, ?)', [
            'ingresos',
            $ingreso->id,
            $operation,
            auth()->id(),
            $reason,
            $before ? json_encode($before, JSON_UNESCAPED_UNICODE) : null,
            json_encode($ingreso->fresh()->only(['numero_serie', 'categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']), JSON_UNESCAPED_UNICODE),
        ]);
    }
}
