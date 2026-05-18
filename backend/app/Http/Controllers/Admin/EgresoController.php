<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CategoriaEgreso;
use App\Models\ConfiguracionEgreso;
use App\Models\Egreso;
use App\Models\Proveedor;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class EgresoController extends Controller
{
    public function index(Request $request): View
    {
        $anio = (int) $request->query('anio', 2026);
        $mes = (int) $request->query('mes', 5);
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');
        $categoriaId = $request->query('categoria_id');

        $query = Egreso::query()
            ->with(['categoria', 'proveedor'])
            ->whereYear('fecha_egreso', $anio)
            ->whereMonth('fecha_egreso', $mes)
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->when($categoriaId, fn ($q) => $q->where('categoria_id', $categoriaId))
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('numero_serie', 'like', "%{$buscar}%")
                        ->orWhere('concepto', 'like', "%{$buscar}%")
                        ->orWhereHas('proveedor', fn ($p) => $p->where('nombre', 'like', "%{$buscar}%"));
                });
            })
            ->orderByDesc('fecha_egreso')
            ->orderByDesc('id');

        $egresos = $query->paginate(10)->withQueryString();
        $base = Egreso::whereYear('fecha_egreso', $anio)->whereMonth('fecha_egreso', $mes);
        $validos = (clone $base)->whereIn('estado', ['aprobado', 'pendiente_aprobacion']);
        $total = (float) (clone $validos)->sum('monto');

        $distribucion = CategoriaEgreso::query()
            ->leftJoin('egresos', function ($join) use ($anio, $mes) {
                $join->on('egresos.categoria_id', '=', 'categorias_egreso.id')
                    ->whereYear('egresos.fecha_egreso', $anio)
                    ->whereMonth('egresos.fecha_egreso', $mes)
                    ->where('egresos.estado', 'aprobado');
            })
            ->select('categorias_egreso.id', 'categorias_egreso.nombre', DB::raw('COALESCE(SUM(egresos.monto),0) as total'), DB::raw('COUNT(egresos.id) as cantidad'))
            ->groupBy('categorias_egreso.id', 'categorias_egreso.nombre')
            ->orderByDesc('total')
            ->get();

        return view('admin.egresos.index', [
            'egresos' => $egresos,
            'buscar' => $buscar,
            'estado' => $estado,
            'categoriaId' => $categoriaId,
            'anio' => $anio,
            'mes' => $mes,
            'categorias' => CategoriaEgreso::where('activa', true)->orderBy('nombre')->get(),
            'numEgresos' => (clone $validos)->count(),
            'totalEgresos' => $total,
            'gastoPromedio' => (clone $validos)->avg('monto') ?? 0,
            'pendientesAprobacion' => (clone $base)->where('estado', 'pendiente_aprobacion')->count(),
            'distribucion' => $distribucion,
        ]);
    }

    public function create(): View
    {
        return view('admin.egresos.create', [
            'egreso' => new Egreso(['fecha_egreso' => now(), 'metodo_pago' => 'efectivo', 'comprobante_tipo' => 'sin_comprobante']),
            'categorias' => CategoriaEgreso::where('activa', true)->orderBy('nombre')->get(),
            'proveedores' => Proveedor::where('activo', true)->whereNull('deleted_at')->orderBy('nombre')->get(),
            'serieSugerida' => $this->nextSerie((int) now()->format('Y')),
            'umbral' => $this->approvalThreshold(),
            'editing' => false,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validatedData($request);
        $year = (int) date('Y', strtotime($data['fecha_egreso']));
        $serie = $this->nextSerie($year);
        $categoria = CategoriaEgreso::findOrFail($data['categoria_id']);
        $requiereAprobacion = $this->requiresApproval((float) $data['monto'], $categoria);

        if ($request->hasFile('comprobante')) {
            $file = $request->file('comprobante');
            $name = $serie.'-'.time().'.'.$file->getClientOriginalExtension();
            $data['comprobante_archivo'] = $file->storeAs('comprobantes/egresos/'.$year, $name, 'public');
            $data['comprobante_nombre'] = $file->getClientOriginalName();
        }

        $egreso = Egreso::create([
            ...$data,
            'numero_serie' => $serie,
            'estado' => $requiereAprobacion ? 'pendiente_aprobacion' : 'aprobado',
            'requiere_aprobacion' => $requiereAprobacion,
            'aprobado_por' => $requiereAprobacion ? null : auth()->id(),
            'fecha_aprobacion' => $requiereAprobacion ? null : now(),
            'created_by' => auth()->id(),
        ]);

        $this->audit('INSERT', $egreso, null, $requiereAprobacion ? 'Registro pendiente de aprobacion' : 'Registro de egreso aprobado automaticamente');

        return redirect()->route('admin.egresos.show', $egreso)->with('success', $requiereAprobacion ? 'Egreso registrado y pendiente de aprobacion.' : 'Egreso registrado correctamente.');
    }

    public function show(Egreso $egreso): View
    {
        $egreso->load(['categoria', 'proveedor']);

        return view('admin.egresos.show', [
            'egreso' => $egreso,
            'umbral' => $this->approvalThreshold(),
        ]);
    }

    public function edit(Egreso $egreso): View
    {
        abort_if(in_array($egreso->estado, ['anulado', 'rechazado'], true), 404);

        return view('admin.egresos.edit', [
            'egreso' => $egreso->load(['categoria', 'proveedor']),
            'categorias' => CategoriaEgreso::where('activa', true)->orderBy('nombre')->get(),
            'proveedores' => Proveedor::where('activo', true)->whereNull('deleted_at')->orderBy('nombre')->get(),
            'umbral' => $this->approvalThreshold(),
            'editing' => true,
        ]);
    }

    public function update(Request $request, Egreso $egreso): RedirectResponse
    {
        abort_if(in_array($egreso->estado, ['anulado', 'rechazado'], true), 404);

        $data = $this->validatedData($request, true);
        $before = $egreso->only(['categoria_id', 'proveedor_id', 'concepto', 'monto', 'metodo_pago', 'fecha_egreso', 'estado']);
        $categoria = CategoriaEgreso::findOrFail($data['categoria_id']);
        $requiereAprobacion = $this->requiresApproval((float) $data['monto'], $categoria);

        if ($request->hasFile('comprobante')) {
            if ($egreso->comprobante_archivo) {
                Storage::disk('public')->delete($egreso->comprobante_archivo);
            }
            $file = $request->file('comprobante');
            $year = (int) date('Y', strtotime($data['fecha_egreso']));
            $name = $egreso->numero_serie.'-'.time().'.'.$file->getClientOriginalExtension();
            $data['comprobante_archivo'] = $file->storeAs('comprobantes/egresos/'.$year, $name, 'public');
            $data['comprobante_nombre'] = $file->getClientOriginalName();
        }

        $egreso->update([
            ...$data,
            'requiere_aprobacion' => $requiereAprobacion,
            'estado' => $requiereAprobacion ? 'pendiente_aprobacion' : 'aprobado',
            'aprobado_por' => $requiereAprobacion ? null : auth()->id(),
            'fecha_aprobacion' => $requiereAprobacion ? null : now(),
            'motivo_ultima_edicion' => $data['motivo_ultima_edicion'],
            'editado_por' => auth()->id(),
            'fecha_ultima_edicion' => now(),
        ]);

        $this->audit('UPDATE', $egreso, $before, $data['motivo_ultima_edicion']);

        return redirect()->route('admin.egresos.show', $egreso)->with('success', 'Egreso actualizado correctamente.');
    }

    public function approve(Egreso $egreso): RedirectResponse
    {
        if ($egreso->estado !== 'pendiente_aprobacion') {
            return redirect()->route('admin.egresos.show', $egreso)->with('success', 'El egreso no esta pendiente de aprobacion.');
        }

        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update([
            'estado' => 'aprobado',
            'aprobado_por' => auth()->id(),
            'fecha_aprobacion' => now(),
            'motivo_rechazo' => null,
            'rechazado_por' => null,
            'fecha_rechazo' => null,
        ]);

        $this->audit('UPDATE', $egreso, $before, 'Aprobacion de egreso');

        return redirect()->route('admin.egresos.show', $egreso)->with('success', 'Egreso aprobado correctamente.');
    }

    public function reject(Request $request, Egreso $egreso): RedirectResponse
    {
        $data = $request->validate(['motivo_rechazo' => ['required', 'string', 'max:500']]);

        if ($egreso->estado !== 'pendiente_aprobacion') {
            return redirect()->route('admin.egresos.show', $egreso)->with('success', 'El egreso no esta pendiente de aprobacion.');
        }

        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update([
            'estado' => 'rechazado',
            'rechazado_por' => auth()->id(),
            'fecha_rechazo' => now(),
            'motivo_rechazo' => $data['motivo_rechazo'],
        ]);

        $this->audit('UPDATE', $egreso, $before, $data['motivo_rechazo']);

        return redirect()->route('admin.egresos.index')->with('success', 'Egreso rechazado correctamente.');
    }

    public function destroy(Request $request, Egreso $egreso): RedirectResponse
    {
        if ($egreso->estado === 'anulado') {
            return redirect()->route('admin.egresos.show', $egreso)->with('success', 'El egreso ya estaba anulado.');
        }

        $data = $request->validate([
            'motivo_anulacion' => ['required', 'string', 'max:500'],
            'devolver_dinero' => ['nullable', 'boolean'],
        ]);

        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update([
            'estado' => 'anulado',
            'motivo_anulacion' => $data['motivo_anulacion'],
            'anulado_por' => auth()->id(),
            'fecha_anulacion' => now(),
            'devolver_dinero' => (bool) ($data['devolver_dinero'] ?? false),
        ]);

        $this->audit('UPDATE', $egreso, $before, $data['motivo_anulacion']);

        return redirect()->route('admin.egresos.index')->with('success', 'Egreso anulado correctamente.');
    }

    private function validatedData(Request $request, bool $editing = false): array
    {
        $rules = [
            'categoria_id' => ['required', 'exists:categorias_egreso,id'],
            'proveedor_id' => ['nullable', 'exists:proveedores,id'],
            'concepto' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string', 'max:1000'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'fecha_egreso' => ['required', 'date'],
            'comprobante_tipo' => ['required', Rule::in(['boleta', 'factura', 'recibo', 'ticket', 'sin_comprobante', 'otro'])],
            'comprobante_numero' => ['nullable', 'string', 'max:50'],
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

    private function approvalThreshold(): float
    {
        return (float) (ConfiguracionEgreso::where('clave', 'umbral_aprobacion')->value('valor') ?? 200);
    }

    private function requiresApproval(float $amount, CategoriaEgreso $categoria): bool
    {
        return $amount > $this->approvalThreshold() || (bool) $categoria->requiere_aprobacion;
    }

    private function nextSerie(int $year): string
    {
        $lastNumber = (int) DB::table('egresos')
            ->where('numero_serie', 'like', "EGR-{$year}-%")
            ->selectRaw("COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) AS last_number")
            ->value('last_number');

        return 'EGR-'.$year.'-'.str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    private function audit(string $operation, Egreso $egreso, ?array $before, ?string $reason): void
    {
        DB::statement('CALL sp_audit_log(?, ?, ?, ?, ?, ?, ?)', [
            'egresos',
            $egreso->id,
            $operation,
            auth()->id(),
            $reason,
            $before ? json_encode($before, JSON_UNESCAPED_UNICODE) : null,
            json_encode($egreso->fresh()->only(['numero_serie', 'categoria_id', 'proveedor_id', 'concepto', 'monto', 'metodo_pago', 'fecha_egreso', 'estado']), JSON_UNESCAPED_UNICODE),
        ]);
    }
}
