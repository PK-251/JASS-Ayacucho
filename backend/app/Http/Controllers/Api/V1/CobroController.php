<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\Cobro;
use App\Models\JornadaCobro;
use App\Models\PagoPendiente;
use App\Models\Vecino;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CobroController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');

        $cobros = Cobro::with(['vecino:id,codigo,nombres,apellidos,documento_num', 'operador:id,nombres,apellidos'])
            ->where('periodo_anio', $anio)
            ->where('periodo_mes', $mes)
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->when($request->user()->isOperator(), fn ($q) => $q->where('operador_id', $request->user()->id))
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where('numero_serie', 'like', "%{$buscar}%")
                    ->orWhereHas('vecino', fn ($v) => $v->where('codigo', 'like', "%{$buscar}%")->orWhere('documento_num', 'like', "%{$buscar}%")->orWhere('nombres', 'like', "%{$buscar}%")->orWhere('apellidos', 'like', "%{$buscar}%"));
            })
            ->orderByDesc('fecha_cobro')
            ->orderByDesc('hora_cobro')
            ->paginate((int) $request->query('per_page', 10));

        return $this->paginated($cobros);
    }

    public function show(Cobro $cobro)
    {
        return $this->ok($cobro->load(['vecino.categoria', 'operador', 'comprobante', 'jornada']));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'vecino_id' => ['required', 'exists:vecinos,id'],
            'periodo_anio' => ['required', 'integer', 'between:2020,2100'],
            'periodo_mes' => ['required', 'integer', 'between:1,12'],
            'monto_recibido' => ['required', 'numeric', 'min:0'],
            'metodo_pago' => ['required', Rule::in(['efectivo', 'transferencia', 'yape', 'plin', 'otro'])],
            'observaciones' => ['nullable', 'string', 'max:500'],
            'jornada_id' => ['nullable', 'exists:jornadas_cobro,id'],
        ]);

        $jornadaId = $data['jornada_id'] ?? null;
        if ($request->user()->isOperator()) {
            $jornadaId = JornadaCobro::firstOrCreate([
                'operador_id' => $request->user()->id,
                'estado' => 'activa',
            ], [
                'fecha_inicio' => now(),
            ])->id;
        }

        try {
            DB::statement('CALL sp_registrar_cobro(?, ?, ?, ?, ?, ?, ?, ?, @sp_cobro_id, @sp_numero_serie)', [
                (int) $data['vecino_id'],
                $request->user()->id,
                $jornadaId,
                (int) $data['periodo_anio'],
                (int) $data['periodo_mes'],
                $this->money($data['monto_recibido']),
                $data['metodo_pago'],
                $data['observaciones'] ?? null,
            ]);
            $result = DB::selectOne('SELECT @sp_cobro_id AS cobro_id, @sp_numero_serie AS numero_serie');
        } catch (QueryException $e) {
            return response()->json(['message' => $this->procedureError($e)], 422);
        }

        return $this->created(Cobro::with(['vecino', 'operador', 'comprobante'])->findOrFail((int) $result->cobro_id), 'Cobro registrado correctamente.');
    }

    public function deuda(Request $request, Vecino $usuario)
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);

        return $this->ok(DB::selectOne('CALL sp_calcular_deuda_vecino(?, ?, ?)', [$usuario->id, $anio, $mes]));
    }

    public function pendiente(Request $request, Vecino $usuario)
    {
        $data = $request->validate([
            'periodo_anio' => ['required', 'integer', 'between:2020,2100'],
            'periodo_mes' => ['required', 'integer', 'between:1,12'],
            'monto_pendiente' => ['required', 'numeric', 'min:0.01'],
            'motivo' => ['nullable', 'string', 'max:500'],
            'jornada_id' => ['nullable', 'exists:jornadas_cobro,id'],
        ]);

        $pendiente = PagoPendiente::create([
            ...$data,
            'vecino_id' => $usuario->id,
            'estado' => 'pendiente',
            'fecha_intento' => now()->toDateString(),
            'registrado_por' => $request->user()->id,
        ]);

        return $this->created($pendiente, 'Pago pendiente registrado correctamente.');
    }

    public function iniciarJornada(Request $request)
    {
        abort_if(! $request->user()->isOperator(), 403);
        $jornada = JornadaCobro::firstOrCreate([
            'operador_id' => $request->user()->id,
            'estado' => 'activa',
        ], [
            'fecha_inicio' => now(),
        ]);

        return $this->ok($jornada, 'Jornada activa.');
    }

    public function cerrarJornada(Request $request)
    {
        abort_if(! $request->user()->isOperator(), 403);
        $data = $request->validate(['observaciones' => ['nullable', 'string', 'max:500']]);
        $jornada = JornadaCobro::where('operador_id', $request->user()->id)->where('estado', 'activa')->latest('fecha_inicio')->firstOrFail();
        $jornada->update([
            'estado' => 'cerrada',
            'fecha_cierre' => now(),
            'observaciones' => $data['observaciones'] ?? null,
            'total_vecinos_atendidos' => Cobro::where('jornada_id', $jornada->id)->where('estado', 'pagado')->count(),
            'total_recaudado' => Cobro::where('jornada_id', $jornada->id)->where('estado', 'pagado')->sum('monto_recibido'),
            'total_pendientes_registrados' => PagoPendiente::where('jornada_id', $jornada->id)->where('estado', 'pendiente')->count(),
        ]);

        return $this->ok($jornada->fresh(), 'Jornada cerrada correctamente.');
    }
}
