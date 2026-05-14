<?php

namespace App\Http\Controllers\Operator;

use App\Http\Controllers\Controller;
use App\Models\Asistencia;
use App\Models\Evento;
use App\Models\Multa;
use App\Models\MultaAplicada;
use App\Models\Vecino;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AsistenciaController extends Controller
{
    public function index(): View
    {
        $pendiente = Evento::with('tipo')
            ->where('estado', 'lista_pendiente')
            ->whereNull('deleted_at')
            ->orderBy('fecha_evento')
            ->first();

        $eventos = Evento::with('tipo')
            ->whereIn('estado', ['lista_pendiente', 'programado', 'realizado'])
            ->whereNull('deleted_at')
            ->orderByRaw("FIELD(estado, 'lista_pendiente', 'programado', 'realizado')")
            ->orderBy('fecha_evento')
            ->paginate(8);

        $kpis = [
            'pendientes' => Evento::where('estado', 'lista_pendiente')->whereNull('deleted_at')->count(),
            'proximos' => Evento::where('estado', 'programado')->whereNull('deleted_at')->count(),
            'pasados' => Evento::where('estado', 'realizado')->whereNull('deleted_at')->count(),
        ];

        return view('operator.asistencia.index', compact('pendiente', 'eventos', 'kpis'));
    }

    public function show(Evento $evento): View
    {
        $evento->load('tipo');
        if (! in_array($evento->estado, ['realizado', 'cancelado'], true)) {
            $this->ensureList($evento);
        }

        $asistencias = Asistencia::with('vecino')
            ->where('evento_id', $evento->id)
            ->join('vecinos', 'vecinos.id', '=', 'asistencias.vecino_id')
            ->select('asistencias.*')
            ->orderBy('vecinos.apellidos')
            ->orderBy('vecinos.nombres')
            ->paginate(12);

        $stats = $this->stats($evento);

        return view('operator.asistencia.show', compact('evento', 'asistencias', 'stats'));
    }

    public function update(Request $request, Asistencia $asistencia): RedirectResponse
    {
        if ($asistencia->evento?->estado === 'realizado') {
            return back()->with('success', 'La lista ya esta cerrada.');
        }

        $data = $request->validate([
            'estado' => ['required', 'in:presente,tarde,justificado,ausente,no_marcado'],
            'hora_llegada' => ['nullable', 'date_format:H:i'],
            'motivo_justificacion' => ['nullable', 'string', 'max:1000'],
        ]);

        $asistencia->update([
            'estado' => $data['estado'],
            'hora_llegada' => $data['estado'] === 'tarde' ? ($data['hora_llegada'] ?? now()->format('H:i')) : null,
            'motivo_justificacion' => $data['estado'] === 'justificado' ? ($data['motivo_justificacion'] ?? 'Justificacion registrada por operador') : null,
            'registrada_por' => auth()->id(),
            'fecha_registro' => now(),
        ]);

        return back()->with('success', 'Asistencia marcada.');
    }

    public function confirmar(Evento $evento): RedirectResponse
    {
        if ($evento->estado === 'realizado') {
            return redirect()->route('operator.asistencia.show', $evento)->with('success', 'La lista ya estaba confirmada.');
        }

        DB::transaction(function () use ($evento) {
            $this->ensureList($evento);
            Asistencia::where('evento_id', $evento->id)->where('estado', 'no_marcado')->update([
                'estado' => 'ausente',
                'registrada_por' => auth()->id(),
                'fecha_registro' => now(),
            ]);

            $multa = $evento->multa_id ? Multa::find($evento->multa_id) : null;
            $monto = 0.0;
            if ($evento->es_obligatorio && $multa) {
                foreach (Asistencia::where('evento_id', $evento->id)->where('estado', 'ausente')->get() as $asistencia) {
                    if ($asistencia->multa_aplicada_id) {
                        continue;
                    }
                    $ma = MultaAplicada::create([
                        'vecino_id' => $asistencia->vecino_id,
                        'multa_id' => $multa->id,
                        'monto_aplicado' => $multa->monto,
                        'estado' => 'pendiente',
                        'fecha_aplicacion' => $evento->fecha_evento,
                        'aplicada_por' => auth()->id(),
                        'motivo_aplicacion' => 'Inasistencia a '.$evento->titulo.' ('.$evento->codigo.')',
                        'evento_id' => $evento->id,
                    ]);
                    $asistencia->update(['multa_aplicada_id' => $ma->id]);
                    $monto += (float) $multa->monto;
                }
            }

            $stats = $this->stats($evento);
            $evento->update([
                'estado' => 'realizado',
                'confirmada_por' => auth()->id(),
                'fecha_confirmacion' => now(),
                'multas_aplicadas_count' => $stats['ausentes'],
                'monto_multas_aplicadas' => $monto,
            ]);
        });

        return redirect()->route('operator.asistencia.show', $evento)->with('success', 'Lista confirmada correctamente.');
    }

    private function ensureList(Evento $evento): void
    {
        $vecinos = Vecino::whereNull('deleted_at')->where('estado', 'activo')->get(['id']);
        foreach ($vecinos as $vecino) {
            Asistencia::firstOrCreate(['evento_id' => $evento->id, 'vecino_id' => $vecino->id], ['estado' => 'no_marcado']);
        }
        if ($evento->total_convocados === 0) {
            $evento->update(['total_convocados' => $vecinos->count()]);
        }
    }

    private function stats(Evento $evento): array
    {
        $base = Asistencia::where('evento_id', $evento->id);
        $total = (clone $base)->count();
        $presentes = (clone $base)->where('estado', 'presente')->count();
        $tardes = (clone $base)->where('estado', 'tarde')->count();
        $justificados = (clone $base)->where('estado', 'justificado')->count();
        $ausentes = (clone $base)->where('estado', 'ausente')->count();
        $marcados = $presentes + $tardes + $justificados + $ausentes;
        return compact('total', 'presentes', 'tardes', 'justificados', 'ausentes', 'marcados');
    }
}
