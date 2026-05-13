<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Asistencia;
use App\Models\Evento;
use App\Models\Multa;
use App\Models\MultaAplicada;
use App\Models\TipoEvento;
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
            ->withCount([
                'asistencias as presentes_count' => fn ($q) => $q->whereIn('estado', ['presente', 'tarde']),
                'asistencias as ausentes_count' => fn ($q) => $q->where('estado', 'ausente'),
                'asistencias as justificados_count' => fn ($q) => $q->where('estado', 'justificado'),
            ])
            ->whereNull('deleted_at')
            ->orderByRaw("FIELD(estado, 'lista_pendiente', 'programado', 'realizado', 'cancelado')")
            ->orderByDesc('fecha_evento')
            ->paginate(10);

        $kpis = [
            'pendientes' => Evento::where('estado', 'lista_pendiente')->whereNull('deleted_at')->count(),
            'proximos' => Evento::where('estado', 'programado')->whereNull('deleted_at')->count(),
            'realizados_mes' => Evento::where('estado', 'realizado')->whereYear('fecha_evento', 2026)->whereMonth('fecha_evento', 5)->count(),
            'multas_pendientes' => MultaAplicada::whereNotNull('evento_id')->where('estado', 'pendiente')->count(),
        ];

        return view('admin.asistencia.index', compact('pendiente', 'eventos', 'kpis'));
    }

    public function create(): View
    {
        return view('admin.asistencia.create', [
            'tipos' => TipoEvento::where('activa', true)->orderBy('nombre')->get(),
            'multas' => Multa::where('activa', true)->whereNull('deleted_at')->orderBy('codigo')->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'tipo_evento_id' => ['required', 'exists:tipos_evento,id'],
            'titulo' => ['required', 'string', 'max:150'],
            'descripcion' => ['nullable', 'string', 'max:2000'],
            'fecha_evento' => ['required', 'date'],
            'hora_inicio' => ['required', 'date_format:H:i'],
            'duracion_minutos' => ['required', 'integer', 'min:30', 'max:720'],
            'lugar' => ['required', 'string', 'max:255'],
            'es_obligatorio' => ['nullable', 'boolean'],
            'multa_id' => ['nullable', 'exists:multas,id'],
        ]);

        $data['codigo'] = $this->nextCodigo();
        $data['es_obligatorio'] = (bool) ($data['es_obligatorio'] ?? false);
        $data['convocatoria_tipo'] = 'todos';
        $data['total_convocados'] = Vecino::whereNull('deleted_at')->where('estado', 'activo')->count();
        $data['estado'] = 'programado';
        $data['created_by'] = auth()->id();

        $evento = Evento::create($data);

        return redirect()->route('admin.asistencia.show', $evento)->with('success', 'Evento creado correctamente.');
    }

    public function show(Evento $evento): View
    {
        $evento->load('tipo');
        $this->ensureList($evento);

        $asistencias = Asistencia::with('vecino', 'multa')
            ->where('evento_id', $evento->id)
            ->join('vecinos', 'vecinos.id', '=', 'asistencias.vecino_id')
            ->select('asistencias.*')
            ->orderBy('vecinos.apellidos')
            ->orderBy('vecinos.nombres')
            ->paginate(12);

        $stats = $this->stats($evento);

        return view('admin.asistencia.show', compact('evento', 'asistencias', 'stats'));
    }

    public function generarLista(Evento $evento): RedirectResponse
    {
        $this->ensureList($evento);
        if ($evento->estado === 'programado') {
            $evento->update(['estado' => 'lista_pendiente']);
        }

        return redirect()->route('admin.asistencia.show', $evento)->with('success', 'Lista de asistencia generada.');
    }

    public function updateAttendance(Request $request, Asistencia $asistencia): RedirectResponse
    {
        if ($asistencia->evento?->estado === 'realizado') {
            return back()->with('success', 'La lista ya fue confirmada y no puede modificarse.');
        }

        $data = $request->validate([
            'estado' => ['required', 'in:presente,tarde,justificado,ausente,no_marcado'],
            'hora_llegada' => ['nullable', 'date_format:H:i'],
            'motivo_justificacion' => ['nullable', 'string', 'max:1000'],
        ]);

        $asistencia->update([
            'estado' => $data['estado'],
            'hora_llegada' => $data['estado'] === 'tarde' ? ($data['hora_llegada'] ?? now()->format('H:i')) : null,
            'motivo_justificacion' => $data['estado'] === 'justificado' ? ($data['motivo_justificacion'] ?? 'Justificacion registrada por administrador') : null,
            'registrada_por' => auth()->id(),
            'fecha_registro' => now(),
        ]);

        return back()->with('success', 'Asistencia actualizada.');
    }

    public function confirmar(Evento $evento): RedirectResponse
    {
        if ($evento->estado === 'realizado') {
            return redirect()->route('admin.asistencia.show', $evento)->with('success', 'La lista ya estaba confirmada.');
        }

        DB::transaction(function () use ($evento) {
            $this->ensureList($evento);

            Asistencia::where('evento_id', $evento->id)
                ->where('estado', 'no_marcado')
                ->update([
                    'estado' => 'ausente',
                    'registrada_por' => auth()->id(),
                    'fecha_registro' => now(),
                ]);

            $multa = $evento->multa_id ? Multa::find($evento->multa_id) : null;
            $aplicadas = 0;
            $monto = 0.0;

            if ($evento->es_obligatorio && $multa) {
                $ausentes = Asistencia::where('evento_id', $evento->id)->where('estado', 'ausente')->get();

                foreach ($ausentes as $asistencia) {
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
                    $aplicadas++;
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

        return redirect()->route('admin.asistencia.show', $evento)->with('success', 'Lista confirmada y multas aplicadas.');
    }

    private function ensureList(Evento $evento): void
    {
        $vecinos = Vecino::whereNull('deleted_at')->where('estado', 'activo')->get(['id']);
        foreach ($vecinos as $vecino) {
            Asistencia::firstOrCreate([
                'evento_id' => $evento->id,
                'vecino_id' => $vecino->id,
            ], [
                'estado' => 'no_marcado',
            ]);
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

    private function nextCodigo(): string
    {
        $last = Evento::where('codigo', 'like', 'EVT-'.date('Y').'-%')
            ->selectRaw('MAX(CAST(SUBSTRING(codigo, 10) AS UNSIGNED)) as max_num')
            ->value('max_num');

        return 'EVT-'.date('Y').'-'.str_pad(((int) $last) + 1, 4, '0', STR_PAD_LEFT);
    }
}
