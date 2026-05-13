<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ReporteMensual;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\Response;

class ReporteController extends Controller
{
    public function index(): View
    {
        $pendiente = ReporteMensual::where('estado', 'pendiente_aprobacion')
            ->where('es_reporte_parcial', false)
            ->orderByDesc('periodo_anio')
            ->orderByDesc('periodo_mes')
            ->first();

        $historico = ReporteMensual::where('es_reporte_parcial', false)
            ->orderByDesc('periodo_anio')
            ->orderByDesc('periodo_mes')
            ->paginate(8);

        $actual = ReporteMensual::where('periodo_anio', 2026)->where('periodo_mes', 5)->where('es_reporte_parcial', false)->first();
        $resumen = $actual ?: (object) $this->buildSnapshot(2026, 5);

        $tendencia = ReporteMensual::whereIn('estado', ['aprobado', 'pendiente_aprobacion'])
            ->where('es_reporte_parcial', false)
            ->orderByDesc('periodo_anio')
            ->orderByDesc('periodo_mes')
            ->limit(6)
            ->get()
            ->reverse();

        return view('admin.reportes.index', [
            'pendiente' => $pendiente,
            'historico' => $historico,
            'resumen' => $resumen,
            'tendencia' => $tendencia,
        ]);
    }

    public function show(ReporteMensual $reporte): View
    {
        return view('admin.reportes.show', [
            'reporte' => $reporte,
            'comparativo' => $this->previousReport($reporte),
        ]);
    }

    public function parcial(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'periodo_anio' => ['nullable', 'integer', 'between:2020,2100'],
            'periodo_mes' => ['nullable', 'integer', 'between:1,12'],
        ]);

        $anio = (int) ($data['periodo_anio'] ?? 2026);
        $mes = (int) ($data['periodo_mes'] ?? 5);
        $snapshot = $this->buildSnapshot($anio, $mes, true);
        $snapshot['version'] = 1;

        $reporte = ReporteMensual::updateOrCreate(
            [
                'periodo_anio' => $anio,
                'periodo_mes' => $mes,
                'es_reporte_parcial' => true,
            ],
            $snapshot
        );

        return redirect()->route('admin.reportes.show', $reporte)->with('success', 'Reporte parcial generado correctamente.');
    }

    public function aprobar(Request $request, ReporteMensual $reporte): RedirectResponse
    {
        if (! in_array($reporte->estado, ['pendiente_aprobacion', 'en_proceso'], true)) {
            return redirect()->route('admin.reportes.show', $reporte)->with('success', 'El reporte no esta pendiente de aprobacion.');
        }

        $data = $request->validate([
            'observaciones_admin' => ['nullable', 'string', 'max:2000'],
        ]);

        $reporte->update([
            'estado' => 'aprobado',
            'aprobado_por' => auth()->id(),
            'fecha_aprobacion' => now(),
            'observaciones_admin' => $data['observaciones_admin'] ?? 'Reporte aprobado.',
            'ruta_pdf_oficial' => '/storage/reportes/'.$reporte->periodo_anio.'/oficial_'.$reporte->periodo_anio.'_'.str_pad($reporte->periodo_mes, 2, '0', STR_PAD_LEFT).'.pdf',
            'hash_pdf_oficial' => hash('sha256', $reporte->id.'-'.$reporte->updated_at),
        ]);

        return redirect()->route('admin.reportes.show', $reporte)->with('success', 'Reporte aprobado correctamente.');
    }

    public function rechazar(Request $request, ReporteMensual $reporte): RedirectResponse
    {
        $data = $request->validate([
            'motivo_rechazo' => ['required', 'string', 'max:2000'],
            'areas_revisar' => ['nullable', 'array'],
            'areas_revisar.*' => ['string', 'max:60'],
        ]);

        $reporte->update([
            'estado' => 'rechazado',
            'rechazado_por' => auth()->id(),
            'fecha_rechazo' => now(),
            'motivo_rechazo' => $data['motivo_rechazo'],
            'areas_revisar_json' => $data['areas_revisar'] ?? [],
        ]);

        return redirect()->route('admin.reportes.index')->with('success', 'Reporte rechazado correctamente.');
    }

    public function pdf(ReporteMensual $reporte): Response
    {
        $pdf = Pdf::loadView('admin.reportes.pdf', ['reporte' => $reporte])->setPaper('a4');
        return $pdf->download('reporte_'.$reporte->periodo_anio.'_'.str_pad($reporte->periodo_mes, 2, '0', STR_PAD_LEFT).'.pdf');
    }

    private function buildSnapshot(int $anio, int $mes, bool $parcial = false): array
    {
        $inicio = sprintf('%04d-%02d-01', $anio, $mes);
        $fin = date('Y-m-t', strtotime($inicio));

        $cobros = DB::table('cobros')->whereYear('fecha_cobro', $anio)->whereMonth('fecha_cobro', $mes)->where('estado', 'pagado');
        $ingresosManual = DB::table('ingresos')->whereYear('fecha_ingreso', $anio)->whereMonth('fecha_ingreso', $mes)->where('estado', 'activo');
        $egresos = DB::table('egresos')->whereYear('fecha_egreso', $anio)->whereMonth('fecha_egreso', $mes)->where('estado', 'aprobado');

        $totalCobros = (float) (clone $cobros)->sum('monto_recibido');
        $totalManual = (float) (clone $ingresosManual)->sum('monto');
        $totalIngresos = $totalCobros + $totalManual;
        $totalEgresos = (float) (clone $egresos)->sum('monto');
        $balance = $totalIngresos - $totalEgresos;

        $vecinosTotal = DB::table('vecinos')->whereNull('deleted_at')->count();
        $deudaPendiente = (float) DB::table('pagos_pendientes')->where('estado', 'pendiente')->sum('monto_pendiente') + (float) DB::table('multas_aplicadas')->where('estado', 'pendiente')->sum('monto_aplicado');
        $morosos = DB::table('vecinos')
            ->whereNull('deleted_at')
            ->where(function ($q) {
                $q->whereExists(fn ($sq) => $sq->selectRaw(1)->from('pagos_pendientes')->whereColumn('pagos_pendientes.vecino_id', 'vecinos.id')->where('estado', 'pendiente'))
                  ->orWhereExists(fn ($sq) => $sq->selectRaw(1)->from('multas_aplicadas')->whereColumn('multas_aplicadas.vecino_id', 'vecinos.id')->where('estado', 'pendiente'));
            })
            ->count();

        $topMorosos = DB::table('vecinos as v')
            ->select('v.codigo', DB::raw("CONCAT(v.nombres,' ',v.apellidos) as nombre"), DB::raw('COALESCE(pp.deuda,0)+COALESCE(ma.deuda,0) as deuda'))
            ->leftJoin(DB::raw('(SELECT vecino_id, SUM(monto_pendiente) deuda FROM pagos_pendientes WHERE estado="pendiente" GROUP BY vecino_id) pp'), 'pp.vecino_id', '=', 'v.id')
            ->leftJoin(DB::raw('(SELECT vecino_id, SUM(monto_aplicado) deuda FROM multas_aplicadas WHERE estado="pendiente" GROUP BY vecino_id) ma'), 'ma.vecino_id', '=', 'v.id')
            ->whereNull('v.deleted_at')
            ->having('deuda', '>', 0)
            ->orderByDesc('deuda')
            ->limit(5)
            ->get()
            ->toArray();

        return [
            'periodo_anio' => $anio,
            'periodo_mes' => $mes,
            'fecha_inicio_periodo' => $inicio,
            'fecha_fin_periodo' => $fin,
            'estado' => $parcial ? 'en_proceso' : 'pendiente_aprobacion',
            'total_ingresos' => $totalIngresos,
            'num_cobros' => (clone $cobros)->count(),
            'num_ingresos_manuales' => (clone $ingresosManual)->count(),
            'total_cuotas' => (float) DB::table('cobros')->whereYear('fecha_cobro', $anio)->whereMonth('fecha_cobro', $mes)->where('estado', 'pagado')->sum('monto_cuota'),
            'total_multas_cobradas' => (float) DB::table('cobros')->whereYear('fecha_cobro', $anio)->whereMonth('fecha_cobro', $mes)->where('estado', 'pagado')->sum('monto_multas'),
            'total_cuotas_extraordinarias' => (float) DB::table('ingresos')->whereYear('fecha_ingreso', $anio)->whereMonth('fecha_ingreso', $mes)->where('estado', 'activo')->where('concepto', 'like', '%extraordinaria%')->sum('monto'),
            'total_donaciones' => (float) DB::table('ingresos')->whereYear('fecha_ingreso', $anio)->whereMonth('fecha_ingreso', $mes)->where('estado', 'activo')->where('concepto', 'like', '%don%')->sum('monto'),
            'total_otros_ingresos' => max(0, $totalManual),
            'total_egresos' => $totalEgresos,
            'num_egresos' => (clone $egresos)->count(),
            'total_materiales' => $this->sumEgresoCategoria($anio, $mes, 'Materiales'),
            'total_personal' => $this->sumEgresoCategoria($anio, $mes, 'Personal'),
            'total_mantenimiento' => $this->sumEgresoCategoria($anio, $mes, 'Mantenimiento'),
            'total_combustible' => $this->sumEgresoCategoria($anio, $mes, 'Combustible'),
            'total_servicios' => $this->sumEgresoCategoria($anio, $mes, 'Servicios'),
            'total_otros_egresos' => $this->sumEgresoCategoria($anio, $mes, 'Otros'),
            'balance_neto' => $balance,
            'num_vecinos_total' => $vecinosTotal,
            'num_vecinos_al_dia' => max(0, $vecinosTotal - $morosos),
            'num_vecinos_morosos' => $morosos,
            'deuda_acumulada' => $deudaPendiente,
            'porcentaje_morosidad' => $vecinosTotal ? round($morosos * 100 / $vecinosTotal, 2) : 0,
            'desglose_ingresos_json' => ['cobros' => $totalCobros, 'manuales' => $totalManual],
            'desglose_egresos_json' => ['total' => $totalEgresos],
            'top_morosos_json' => json_decode(json_encode($topMorosos), true),
            'proyeccion_siguiente_mes_json' => ['ingresos_esperados' => $totalIngresos, 'deudas_a_cobrar' => $deudaPendiente],
            'fecha_generacion' => now(),
            'generado_por_sistema' => false,
            'es_reporte_parcial' => $parcial,
            'ruta_pdf_borrador' => '/storage/reportes/'.$anio.'/borrador_'.$anio.'_'.str_pad($mes, 2, '0', STR_PAD_LEFT).'.pdf',
        ];
    }

    private function sumEgresoCategoria(int $anio, int $mes, string $categoria): float
    {
        return (float) DB::table('egresos as e')
            ->join('categorias_egreso as c', 'c.id', '=', 'e.categoria_id')
            ->whereYear('e.fecha_egreso', $anio)
            ->whereMonth('e.fecha_egreso', $mes)
            ->where('e.estado', 'aprobado')
            ->where('c.nombre', $categoria)
            ->sum('e.monto');
    }

    private function previousReport(ReporteMensual $reporte): ?ReporteMensual
    {
        $date = strtotime(sprintf('%04d-%02d-01 -1 month', $reporte->periodo_anio, $reporte->periodo_mes));
        return ReporteMensual::where('periodo_anio', (int) date('Y', $date))
            ->where('periodo_mes', (int) date('m', $date))
            ->where('es_reporte_parcial', false)
            ->first();
    }
}
