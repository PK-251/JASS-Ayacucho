<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\ReporteMensual;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReporteController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $reportes = ReporteMensual::query()
            ->when($request->query('anio'), fn ($q, $anio) => $q->where('periodo_anio', $anio))
            ->when($request->query('estado'), fn ($q, $estado) => $q->where('estado', $estado))
            ->where('es_reporte_parcial', $request->boolean('parcial', false))
            ->orderByDesc('periodo_anio')->orderByDesc('periodo_mes')
            ->paginate((int) $request->query('per_page', 10));

        return $this->paginated($reportes);
    }

    public function show(ReporteMensual $reporte)
    {
        return $this->ok($reporte);
    }

    public function parcial(Request $request)
    {
        $data = $request->validate([
            'anio' => ['nullable', 'integer', 'between:2020,2100'],
            'mes' => ['nullable', 'integer', 'between:1,12'],
        ]);
        $anio = (int) ($data['anio'] ?? 2026);
        $mes = (int) ($data['mes'] ?? 5);

        try {
            DB::statement('CALL sp_generar_reporte_mensual(?, ?, ?, ?, @sp_reporte_id)', [$anio, $mes, true, $request->user()->id]);
            $result = DB::selectOne('SELECT @sp_reporte_id AS reporte_id');
            $reporte = ReporteMensual::findOrFail((int) $result->reporte_id);
        } catch (QueryException $e) {
            return response()->json(['message' => $this->procedureError($e)], 422);
        }

        return $this->created($reporte, 'Reporte parcial generado correctamente.');
    }

    public function aprobar(Request $request, ReporteMensual $reporte)
    {
        $data = $request->validate(['observaciones_admin' => ['nullable', 'string', 'max:2000']]);
        abort_if(! in_array($reporte->estado, ['pendiente_aprobacion', 'en_proceso'], true), 422, 'El reporte no esta pendiente de aprobacion.');
        $reporte->update([
            'estado' => 'aprobado',
            'aprobado_por' => $request->user()->id,
            'fecha_aprobacion' => now(),
            'observaciones_admin' => $data['observaciones_admin'] ?? 'Reporte aprobado desde API.',
            'ruta_pdf_oficial' => '/storage/reportes/'.$reporte->periodo_anio.'/oficial_'.$reporte->periodo_anio.'_'.str_pad($reporte->periodo_mes, 2, '0', STR_PAD_LEFT).'.pdf',
            'hash_pdf_oficial' => hash('sha256', $reporte->id.'-'.$reporte->updated_at),
        ]);

        return $this->ok($reporte->fresh(), 'Reporte aprobado correctamente.');
    }

    public function rechazar(Request $request, ReporteMensual $reporte)
    {
        $data = $request->validate([
            'motivo_rechazo' => ['required', 'string', 'max:2000'],
            'areas_revisar' => ['nullable', 'array'],
            'areas_revisar.*' => ['string', 'max:60'],
        ]);
        $reporte->update([
            'estado' => 'rechazado',
            'rechazado_por' => $request->user()->id,
            'fecha_rechazo' => now(),
            'motivo_rechazo' => $data['motivo_rechazo'],
            'areas_revisar_json' => $data['areas_revisar'] ?? [],
        ]);

        return $this->ok($reporte->fresh(), 'Reporte rechazado correctamente.');
    }
}
