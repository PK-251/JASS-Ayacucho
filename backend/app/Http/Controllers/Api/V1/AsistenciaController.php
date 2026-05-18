<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\Asistencia;
use App\Models\Evento;
use App\Models\MultaAplicada;
use App\Models\Vecino;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AsistenciaController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $eventos = Evento::with('tipo')
            ->whereNull('deleted_at')
            ->when($request->query('estado'), fn ($q, $estado) => $q->where('estado', $estado))
            ->orderByDesc('fecha_evento')
            ->paginate((int) $request->query('per_page', 10));

        return $this->paginated($eventos);
    }

    public function show(Evento $evento)
    {
        return $this->ok($evento->load(['tipo', 'asistencias.vecino', 'asistencias.multa']));
    }

    public function generarLista(Request $request, Evento $evento)
    {
        abort_if($evento->estado === 'cancelado', 422, 'No se puede generar lista de un evento cancelado.');
        $creadas = 0;
        Vecino::whereNull('deleted_at')->where('estado', 'activo')->chunkById(100, function ($vecinos) use ($evento, &$creadas) {
            foreach ($vecinos as $vecino) {
                $row = Asistencia::firstOrCreate([
                    'evento_id' => $evento->id,
                    'vecino_id' => $vecino->id,
                ], [
                    'estado' => 'no_marcado',
                ]);
                if ($row->wasRecentlyCreated) {
                    $creadas++;
                }
            }
        });
        $evento->update(['estado' => 'lista_pendiente', 'total_convocados' => Asistencia::where('evento_id', $evento->id)->count()]);

        return $this->ok(['creadas' => $creadas, 'evento' => $evento->fresh()], 'Lista generada correctamente.');
    }

    public function update(Request $request, Asistencia $asistencia)
    {
        $data = $request->validate([
            'estado' => ['required', Rule::in(['no_marcado', 'presente', 'tarde', 'justificado', 'ausente'])],
            'hora_llegada' => ['nullable', 'date_format:H:i'],
            'motivo_justificacion' => ['nullable', 'string', 'max:1000'],
            'observaciones' => ['nullable', 'string', 'max:500'],
        ]);
        $asistencia->update([...$data, 'registrada_por' => $request->user()->id, 'fecha_registro' => now()]);

        return $this->ok($asistencia->fresh(['vecino', 'multa']), 'Asistencia actualizada correctamente.');
    }

    public function confirmar(Request $request, Evento $evento)
    {
        abort_if($evento->estado === 'realizado', 422, 'La lista ya fue confirmada.');

        DB::transaction(function () use ($evento, $request) {
            $ausentes = Asistencia::where('evento_id', $evento->id)->where('estado', 'ausente')->get();
            $count = 0;
            $total = 0;
            foreach ($ausentes as $asistencia) {
                if (! $evento->multa_id || $asistencia->multa_aplicada_id) {
                    continue;
                }
                $multa = MultaAplicada::create([
                    'vecino_id' => $asistencia->vecino_id,
                    'multa_id' => $evento->multa_id,
                    'monto_aplicado' => 10.00,
                    'estado' => 'pendiente',
                    'fecha_aplicacion' => now()->toDateString(),
                    'aplicada_por' => $request->user()->id,
                    'motivo_aplicacion' => 'Inasistencia a '.$evento->titulo,
                    'evento_id' => $evento->id,
                ]);
                $asistencia->update(['multa_aplicada_id' => $multa->id]);
                $count++;
                $total += 10.00;
            }
            $evento->update([
                'estado' => 'realizado',
                'confirmada_por' => $request->user()->id,
                'fecha_confirmacion' => now(),
                'multas_aplicadas_count' => $count,
                'monto_multas_aplicadas' => $total,
            ]);
        });

        return $this->ok($evento->fresh(['tipo', 'asistencias']), 'Lista confirmada correctamente.');
    }
}
