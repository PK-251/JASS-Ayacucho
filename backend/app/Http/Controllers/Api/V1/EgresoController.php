<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\CategoriaEgreso;
use App\Models\ConfiguracionEgreso;
use App\Models\Egreso;
use App\Models\Proveedor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class EgresoController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');

        $inicio = sprintf('%04d-%02d-01', $anio, $mes);
        $fin    = date('Y-m-t', strtotime($inicio));

        $egresos = Egreso::with(['categoria', 'proveedor'])
            ->whereBetween('fecha_egreso', [$inicio, $fin]) // Optimizado: whereBetween usa idx_egresos_periodo
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('numero_serie', 'like', "%{$buscar}%")
                        ->orWhere('concepto', 'like', "%{$buscar}%");
                });
            })
            ->orderByDesc('fecha_egreso')->orderByDesc('id')
            ->paginate((int) $request->query('per_page', 10));

        return $this->paginated($egresos);
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $year = (int) date('Y', strtotime($data['fecha_egreso']));
        $requiereAprobacion = $this->money($data['monto']) > $this->approvalThreshold();
        $egreso = Egreso::create([
            ...$data,
            'numero_serie' => $this->nextSerie($year),
            'estado' => $requiereAprobacion ? 'pendiente_aprobacion' : 'aprobado',
            'requiere_aprobacion' => $requiereAprobacion,
            'aprobado_por' => $requiereAprobacion ? null : $request->user()->id,
            'fecha_aprobacion' => $requiereAprobacion ? null : now(),
            'created_by' => $request->user()->id,
        ]);
        $this->audit('INSERT', $egreso, null, $requiereAprobacion ? 'Registro pendiente de aprobacion desde API' : 'Registro de egreso desde API');

        return $this->created($egreso->load(['categoria', 'proveedor']), 'Egreso registrado correctamente.');
    }

    public function show(Egreso $egreso)
    {
        return $this->ok($egreso->load(['categoria', 'proveedor']));
    }

    public function update(Request $request, Egreso $egreso)
    {
        abort_if(in_array($egreso->estado, ['anulado', 'rechazado'], true), 404);
        $data = $this->validated($request, true);
        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $requiereAprobacion = $this->money($data['monto']) > $this->approvalThreshold();
        $egreso->update([
            ...$data,
            'estado' => $requiereAprobacion ? 'pendiente_aprobacion' : 'aprobado',
            'requiere_aprobacion' => $requiereAprobacion,
            'editado_por' => $request->user()->id,
            'fecha_ultima_edicion' => now(),
        ]);
        $this->audit('UPDATE', $egreso, $before, $data['motivo_ultima_edicion']);

        return $this->ok($egreso->fresh(['categoria', 'proveedor']), 'Egreso actualizado correctamente.');
    }

    public function approve(Request $request, Egreso $egreso)
    {
        abort_if($egreso->estado !== 'pendiente_aprobacion', 422, 'El egreso no esta pendiente de aprobacion.');
        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update(['estado' => 'aprobado', 'aprobado_por' => $request->user()->id, 'fecha_aprobacion' => now(), 'motivo_rechazo' => null, 'rechazado_por' => null, 'fecha_rechazo' => null]);
        $this->audit('UPDATE', $egreso, $before, 'Aprobacion de egreso desde API');

        return $this->ok($egreso->fresh(), 'Egreso aprobado correctamente.');
    }

    public function reject(Request $request, Egreso $egreso)
    {
        $data = $request->validate(['motivo_rechazo' => ['required', 'string', 'max:500']]);
        abort_if($egreso->estado !== 'pendiente_aprobacion', 422, 'El egreso no esta pendiente de aprobacion.');
        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update(['estado' => 'rechazado', 'rechazado_por' => $request->user()->id, 'fecha_rechazo' => now(), 'motivo_rechazo' => $data['motivo_rechazo']]);
        $this->audit('UPDATE', $egreso, $before, $data['motivo_rechazo']);

        return $this->ok($egreso->fresh(), 'Egreso rechazado correctamente.');
    }

    public function destroy(Request $request, Egreso $egreso)
    {
        $data = $request->validate(['motivo_anulacion' => ['required', 'string', 'max:500'], 'devolver_dinero' => ['nullable', 'boolean']]);
        $before = $egreso->only(['estado', 'monto', 'concepto']);
        $egreso->update(['estado' => 'anulado', 'motivo_anulacion' => $data['motivo_anulacion'], 'anulado_por' => $request->user()->id, 'fecha_anulacion' => now(), 'devolver_dinero' => (bool) ($data['devolver_dinero'] ?? false)]);
        $this->audit('UPDATE', $egreso, $before, $data['motivo_anulacion']);

        return $this->ok($egreso->fresh(), 'Egreso anulado correctamente.');
    }

    public function catalogos()
    {
        return $this->ok([
            'categorias' => CategoriaEgreso::where('activa', true)->orderBy('nombre')->get(),
            'proveedores' => Proveedor::where('activo', true)->whereNull('deleted_at')->orderBy('nombre')->get(),
            'umbral_aprobacion' => $this->approvalThreshold(),
        ]);
    }

    private function validated(Request $request, bool $editing = false): array
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
        ];
        if ($editing) {
            $rules['motivo_ultima_edicion'] = ['required', 'string', 'max:500'];
        }
        return $request->validate($rules);
    }

    private function approvalThreshold(): float
    {
        return (float) (ConfiguracionEgreso::where('clave', 'umbral_aprobacion')->value('valor') ?? 200);
    }

    private function nextSerie(int $year): string
    {
        $lastNumber = (int) DB::table('egresos')->where('numero_serie', 'like', "EGR-{$year}-%")->selectRaw("COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) AS last_number")->value('last_number');
        return 'EGR-'.$year.'-'.str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    private function audit(string $operation, Egreso $egreso, ?array $before, ?string $reason): void
    {
        DB::statement('CALL sp_audit_log(?, ?, ?, ?, ?, ?, ?)', [
            'egresos', $egreso->id, $operation, request()->user()?->id, $reason,
            $before ? json_encode($before, JSON_UNESCAPED_UNICODE) : null,
            json_encode($egreso->fresh()->only(['numero_serie', 'categoria_id', 'proveedor_id', 'concepto', 'monto', 'metodo_pago', 'fecha_egreso', 'estado']), JSON_UNESCAPED_UNICODE),
        ]);
    }
}
