@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'reportes'])
@endsection

@section('content')
@php
    $months = [1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril', 5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto', 9 => 'Setiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'];
    $estadoClass = $reporte->estado === 'aprobado' ? 'badge-soft' : ($reporte->estado === 'rechazado' ? 'badge-danger-soft' : 'badge-warning-soft');
@endphp

<div class="topbar">
    <div>
        <div class="page-subtitle">Reportes / Detalle</div>
        <h1 class="page-title">Reporte {{ $months[$reporte->periodo_mes] ?? $reporte->periodo_mes }} {{ $reporte->periodo_anio }}</h1>
        <div class="page-subtitle"><span class="badge {{ $estadoClass }}">{{ str_replace('_', ' ', ucfirst($reporte->estado)) }}</span> · Generado {{ $reporte->fecha_generacion?->format('d/m/Y H:i') }}</div>
    </div>
    <div class="page-actions">
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.reportes.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
        <a class="btn btn-outline-info btn-icon" href="{{ route('admin.reportes.pdf', $reporte) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6"/></svg></span>Exportar PDF</a>
    </div>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif
@if ($errors->any())
    <div class="alert alert-danger border-0 shadow-sm">
        <strong>Revisa el formulario.</strong>
        <ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul>
    </div>
@endif

<div class="row g-3 mb-4">
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Total ingresos</div><div class="metric-value">S/{{ number_format((float) $reporte->total_ingresos, 2) }}</div><span class="badge badge-soft mt-2">{{ $reporte->num_cobros }} cobros</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Total egresos</div><div class="metric-value danger">S/{{ number_format((float) $reporte->total_egresos, 2) }}</div><span class="badge badge-danger-soft mt-2">{{ $reporte->num_egresos }} egresos</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Balance neto</div><div class="metric-value {{ $reporte->balance_neto < 0 ? 'danger' : 'success' }}">S/{{ number_format((float) $reporte->balance_neto, 2) }}</div><span class="badge badge-soft mt-2">Final</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Morosidad</div><div class="metric-value" style="color:#f59e0b">{{ number_format((float) $reporte->porcentaje_morosidad, 1) }}%</div><span class="badge badge-warning-soft mt-2">{{ $reporte->num_vecinos_morosos }}/{{ $reporte->num_vecinos_total }}</span></div></div>
</div>

<div class="row g-3">
    <div class="col-lg-8">
        <section class="panel table-panel mb-3">
            <h2 class="h5 fw-bold mb-3">Resumen financiero</h2>
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead><tr><th>Ingresos</th><th class="text-end">Monto</th><th>Egresos</th><th class="text-end">Monto</th></tr></thead>
                    <tbody>
                        <tr><td>Cuotas mensuales</td><td class="text-end">S/{{ number_format((float) $reporte->total_cuotas, 2) }}</td><td>Materiales</td><td class="text-end">S/{{ number_format((float) $reporte->total_materiales, 2) }}</td></tr>
                        <tr><td>Multas cobradas</td><td class="text-end">S/{{ number_format((float) $reporte->total_multas_cobradas, 2) }}</td><td>Personal</td><td class="text-end">S/{{ number_format((float) $reporte->total_personal, 2) }}</td></tr>
                        <tr><td>Cuotas extraordinarias</td><td class="text-end">S/{{ number_format((float) $reporte->total_cuotas_extraordinarias, 2) }}</td><td>Mantenimiento</td><td class="text-end">S/{{ number_format((float) $reporte->total_mantenimiento, 2) }}</td></tr>
                        <tr><td>Donaciones</td><td class="text-end">S/{{ number_format((float) $reporte->total_donaciones, 2) }}</td><td>Combustible</td><td class="text-end">S/{{ number_format((float) $reporte->total_combustible, 2) }}</td></tr>
                        <tr><td>Otros ingresos</td><td class="text-end">S/{{ number_format((float) $reporte->total_otros_ingresos, 2) }}</td><td>Servicios y otros</td><td class="text-end">S/{{ number_format((float) ($reporte->total_servicios + $reporte->total_otros_egresos), 2) }}</td></tr>
                    </tbody>
                </table>
            </div>
        </section>

        @if ($comparativo)
            <section class="panel table-panel mb-3">
                <h2 class="h5 fw-bold mb-3">Comparativa con {{ $months[$comparativo->periodo_mes] ?? $comparativo->periodo_mes }} {{ $comparativo->periodo_anio }}</h2>
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead><tr><th>Indicador</th><th>Anterior</th><th>Actual</th><th>Diferencia</th></tr></thead>
                        <tbody>
                            <tr><td>Ingresos</td><td>S/{{ number_format((float) $comparativo->total_ingresos, 2) }}</td><td>S/{{ number_format((float) $reporte->total_ingresos, 2) }}</td><td class="fw-bold">S/{{ number_format((float) ($reporte->total_ingresos - $comparativo->total_ingresos), 2) }}</td></tr>
                            <tr><td>Egresos</td><td>S/{{ number_format((float) $comparativo->total_egresos, 2) }}</td><td>S/{{ number_format((float) $reporte->total_egresos, 2) }}</td><td class="fw-bold">S/{{ number_format((float) ($reporte->total_egresos - $comparativo->total_egresos), 2) }}</td></tr>
                            <tr><td>Balance</td><td>S/{{ number_format((float) $comparativo->balance_neto, 2) }}</td><td>S/{{ number_format((float) $reporte->balance_neto, 2) }}</td><td class="fw-bold">S/{{ number_format((float) ($reporte->balance_neto - $comparativo->balance_neto), 2) }}</td></tr>
                        </tbody>
                    </table>
                </div>
            </section>
        @endif

        <section class="panel table-panel">
            <h2 class="h5 fw-bold mb-3">Top morosos</h2>
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead><tr><th>Codigo</th><th>Usuario</th><th class="text-end">Deuda</th></tr></thead>
                    <tbody>
                    @forelse (($reporte->top_morosos_json ?? []) as $moroso)
                        <tr><td>{{ $moroso['codigo'] ?? '-' }}</td><td>{{ $moroso['nombre'] ?? '-' }}</td><td class="text-end fw-bold text-danger">S/{{ number_format((float) ($moroso['deuda'] ?? 0), 2) }}</td></tr>
                    @empty
                        <tr><td colspan="3" class="text-center text-secondary">Sin morosos registrados.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
        </section>
    </div>

    <div class="col-lg-4">
        <section class="panel p-4 mb-3">
            <h2 class="h5 fw-bold mb-3">Estado del reporte</h2>
            <div class="d-flex justify-content-between border-bottom py-2"><span>Periodo</span><strong>{{ $months[$reporte->periodo_mes] ?? $reporte->periodo_mes }} {{ $reporte->periodo_anio }}</strong></div>
            <div class="d-flex justify-content-between border-bottom py-2"><span>Tipo</span><strong>{{ $reporte->es_reporte_parcial ? 'Parcial' : 'Oficial' }}</strong></div>
            <div class="d-flex justify-content-between py-2"><span>Deuda acumulada</span><strong>S/{{ number_format((float) $reporte->deuda_acumulada, 2) }}</strong></div>
        </section>

        @if (in_array($reporte->estado, ['pendiente_aprobacion', 'en_proceso']))
            <section class="panel p-4 mb-3" style="border-color:#10b981">
                <h2 class="h5 fw-bold mb-3">Aprobar reporte</h2>
                <form method="POST" action="{{ route('admin.reportes.aprobar', $reporte) }}">
                    @csrf
                    <label class="form-label fw-semibold">Observaciones del administrador</label>
                    <textarea class="form-control mb-3" name="observaciones_admin" rows="3" placeholder="Notas finales para el acta o asamblea..."></textarea>
                    <button class="btn btn-success w-100">Aprobar y firmar</button>
                </form>
            </section>

            <section class="panel p-4 form-card" style="border-color:#ef4444">
                <h2 class="h5 fw-bold text-danger mb-3">Rechazar reporte</h2>
                <form method="POST" action="{{ route('admin.reportes.rechazar', $reporte) }}">
                    @csrf
                    <label class="form-label fw-semibold">Motivo de rechazo</label>
                    <textarea class="form-control mb-3" name="motivo_rechazo" rows="3" required placeholder="Explica que debe corregirse..."></textarea>
                    @foreach (['Ingresos','Egresos','Morosidad','Comprobantes'] as $area)
                        <div class="form-check"><input class="form-check-input" type="checkbox" name="areas_revisar[]" value="{{ $area }}" id="area{{ $loop->index }}"><label class="form-check-label" for="area{{ $loop->index }}">{{ $area }}</label></div>
                    @endforeach
                    <button class="btn btn-danger w-100 mt-3">Rechazar reporte</button>
                </form>
            </section>
        @elseif ($reporte->estado === 'aprobado')
            <section class="panel p-4 form-card">
                <h2 class="h5 fw-bold text-success mb-2">Reporte aprobado</h2>
                <p class="mb-1">{{ $reporte->observaciones_admin ?: 'Sin observaciones.' }}</p>
                <p class="text-secondary mb-0">{{ $reporte->fecha_aprobacion?->format('d/m/Y H:i') }}</p>
            </section>
        @else
            <section class="panel p-4 form-card">
                <h2 class="h5 fw-bold text-danger mb-2">Reporte rechazado</h2>
                <p class="mb-1">{{ $reporte->motivo_rechazo }}</p>
                <p class="text-secondary mb-0">{{ $reporte->fecha_rechazo?->format('d/m/Y H:i') }}</p>
            </section>
        @endif
    </div>
</div>
@endsection
