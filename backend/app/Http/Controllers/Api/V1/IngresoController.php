<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\CategoriaIngreso;
use App\Models\Ingreso;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class IngresoController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $anio = (int) $request->query('anio', 2026);
        $mes = (int) $request->query('mes', 5);
        $buscar = trim((string) $request->query('buscar'));
        $query = DB::table('vista_ingresos_completa')
            ->whereYear('fecha_ingreso', $anio)
            ->whereMonth('fecha_ingreso', $mes)
            ->when($buscar !== '', fn ($q) => $q->where('numero_serie', 'like', "%{$buscar}%")->orWhere('vecino_nombre', 'like', "%{$buscar}%")->orWhere('concepto', 'like', "%{$buscar}%"))
            ->orderByDesc('fecha_ingreso')
            ->orderByDesc('hora');

        return $this->paginated($query->paginate((int) $request->query('per_page', 10)));
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $year = (int) date('Y', strtotime($data['fecha_ingreso']));
        $ingreso = Ingreso::create([
            ...$data,
            'numero_serie' => $this->nextSerie($year),
            'estado' => 'activo',
            'created_by' => $request->user()->id,
        ]);
        $this->audit('INSERT', $ingreso, null, 'Registro de ingreso manual desde API');

        return $this->created($ingreso->load(['categoria', 'vecino']), 'Ingreso manual registrado correctamente.');
    }

    public function show(Ingreso $ingreso)
    {
        return $this->ok($ingreso->load(['categoria', 'vecino']));
    }

    public function update(Request $request, Ingreso $ingreso)
    {
        abort_if($ingreso->estado === 'anulado', 404);
        $data = $this->validated($request, true);
        $before = $ingreso->only(['categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']);
        $ingreso->update([
            ...$data,
            'editado_por' => $request->user()->id,
            'fecha_ultima_edicion' => now(),
        ]);
        $this->audit('UPDATE', $ingreso, $before, $data['motivo_ultima_edicion']);

        return $this->ok($ingreso->fresh(['categoria', 'vecino']), 'Ingreso actualizado correctamente.');
    }

    public function destroy(Request $request, Ingreso $ingreso)
    {
        $data = $request->validate([
            'motivo_anulacion' => ['required', 'string', 'max:500'],
            'devolver_dinero' => ['nullable', 'boolean'],
        ]);
        $before = $ingreso->only(['categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']);
        $ingreso->update([
            'estado' => 'anulado',
            'motivo_anulacion' => $data['motivo_anulacion'],
            'anulado_por' => $request->user()->id,
            'fecha_anulacion' => now(),
            'devolver_dinero' => (bool) ($data['devolver_dinero'] ?? false),
        ]);
        $this->audit('UPDATE', $ingreso, $before, $data['motivo_anulacion']);

        return $this->ok($ingreso->fresh(), 'Ingreso anulado correctamente.');
    }

    public function categorias()
    {
        return $this->ok(CategoriaIngreso::where('activa', true)->where('es_manual', true)->orderBy('nombre')->get());
    }

    private function validated(Request $request, bool $editing = false): array
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
        ];
        if ($editing) {
            $rules['motivo_ultima_edicion'] = ['required', 'string', 'max:500'];
        }

        return $request->validate($rules);
    }

    private function nextSerie(int $year): string
    {
        $lastNumber = (int) DB::table('ingresos')->where('numero_serie', 'like', "ING-{$year}-%")->selectRaw("COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) AS last_number")->value('last_number');
        return 'ING-'.$year.'-'.str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    private function audit(string $operation, Ingreso $ingreso, ?array $before, ?string $reason): void
    {
        DB::statement('CALL sp_audit_log(?, ?, ?, ?, ?, ?, ?)', [
            'ingresos', $ingreso->id, $operation, request()->user()?->id, $reason,
            $before ? json_encode($before, JSON_UNESCAPED_UNICODE) : null,
            json_encode($ingreso->fresh()->only(['numero_serie', 'categoria_id', 'vecino_id', 'concepto', 'monto', 'metodo_pago', 'fecha_ingreso', 'estado']), JSON_UNESCAPED_UNICODE),
        ]);
    }
}
