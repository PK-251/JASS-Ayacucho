@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'reportes'])
@endsection

@section('content')
@php
    $months = [1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril', 5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto', 9 => 'Setiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'];
    $periodoResumen = ($months[$resumen->periodo_mes] ?? $resumen->periodo_mes).' '.$resumen->periodo_anio;
@endphp

<div class="topbar">
    <div>
        <div class="page-subtitle">Administracion / Reportes</div>
        <h1 class="page-title">Reportes Mensuales</h1>
        <div class="page-subtitle">Cierre financiero, morosidad y aprobacion oficial.</div>
    </div>
    <form method="POST" action="{{ route('admin.reportes.parcial') }}" class="d-flex gap-2 align-items-center">
        @csrf
        <input type="hidden" name="periodo_anio" value="2026">
        <input type="hidden" name="periodo_mes" value="5">
        <button class="btn btn-aqua">+ Generar reporte parcial</button>
    </form>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

@if ($pendiente)
    <section class="panel p-4 mb-4" style="border-color:#f59e0b; background:#fff7d8">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
                <div class="fw-bold text-warning mb-1">Reporte pendiente: {{ $months[$pendiente->periodo_mes] ?? $pendiente->periodo_mes }} {{ $pendiente->periodo_anio }}</div>
                <div class="text-secondary">El reporte ya fue generado y necesita revision antes de publicarse como oficial.</div>
            </div>
            <div class="d-flex gap-2">
                <a class="btn btn-outline-warning bg-white" href="{{ route('admin.reportes.show', $pendiente) }}">Ver detalle</a>
                <a class="btn btn-aqua" href="{{ route('admin.reportes.show', $pendiente) }}">Revisar y aprobar</a>
            </div>
        </div>
    </section>
@endif

<div class="row g-3 mb-4">
    <div class="col-xl-3 col-md-6">
        <div class="metric-card">
            <div class="metric-label">Ingresos totales</div>
            <div class="metric-value">S/{{ number_format((float) $resumen->total_ingresos, 2) }}</div>
            <span class="badge badge-soft mt-2">{{ $periodoResumen }}</span>
        </div>
    </div>
    <div class="col-xl-3 col-md-6">
        <div class="metric-card">
            <div class="metric-label">Egresos operativos</div>
            <div class="metric-value danger">S/{{ number_format((float) $resumen->total_egresos, 2) }}</div>
            <span class="badge badge-danger-soft mt-2">{{ $resumen->num_egresos }} registros</span>
        </div>
    </div>
    <div class="col-xl-3 col-md-6">
        <div class="metric-card">
            <div class="metric-label">Balance neto</div>
            <div class="metric-value {{ $resumen->balance_neto < 0 ? 'danger' : 'success' }}">S/{{ number_format((float) $resumen->balance_neto, 2) }}</div>
            <span class="badge badge-soft mt-2">Ingresos - egresos</span>
        </div>
    </div>
    <div class="col-xl-3 col-md-6">
        <div class="metric-card">
            <div class="metric-label">Indice de morosidad</div>
            <div class="metric-value" style="color:#f59e0b">{{ number_format((float) $resumen->porcentaje_morosidad, 1) }}%</div>
            <span class="badge badge-warning-soft mt-2">{{ $resumen->num_vecinos_morosos }} usuarios</span>
        </div>
    </div>
</div>

<div class="row g-3 mb-4">
    <div class="col-lg-8">
        <section class="panel p-4 h-100">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h2 class="h5 fw-bold mb-0">Ingresos vs Egresos</h2>
                <span class="badge badge-soft">Ultimos 6 meses</span>
            </div>
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead><tr><th>Periodo</th><th>Ingresos</th><th>Egresos</th><th>Balance</th><th>Estado</th></tr></thead>
                    <tbody>
                    @forelse ($tendencia as $rep)
                        <tr>
                            <td>{{ $months[$rep->periodo_mes] ?? $rep->periodo_mes }} {{ $rep->periodo_anio }}</td>
                            <td>S/{{ number_format((float) $rep->total_ingresos, 2) }}</td>
                            <td>S/{{ number_format((float) $rep->total_egresos, 2) }}</td>
                            <td class="fw-bold {{ $rep->balance_neto < 0 ? 'text-danger' : 'text-success' }}">S/{{ number_format((float) $rep->balance_neto, 2) }}</td>
                            <td><span class="badge {{ $rep->estado === 'aprobado' ? 'badge-soft' : 'badge-warning-soft' }}">{{ str_replace('_', ' ', ucfirst($rep->estado)) }}</span></td>
                        </tr>
                    @empty
                        <tr><td colspan="5" class="text-center text-secondary">Todavia no hay tendencia para mostrar.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
        </section>
    </div>
    <div class="col-lg-4">
        <section class="panel p-4 h-100">
            <h2 class="h5 fw-bold mb-3">Resumen del periodo</h2>
            <div class="d-flex justify-content-between border-bottom py-3"><span>Usuarios al dia</span><strong class="text-success">{{ $resumen->num_vecinos_al_dia }}</strong></div>
            <div class="d-flex justify-content-between border-bottom py-3"><span>Usuarios morosos</span><strong class="text-danger">{{ $resumen->num_vecinos_morosos }}</strong></div>
            <div class="d-flex justify-content-between border-bottom py-3"><span>Deuda acumulada</span><strong>S/{{ number_format((float) $resumen->deuda_acumulada, 2) }}</strong></div>
            <div class="d-flex justify-content-between py-3"><span>Reportes oficiales</span><strong>{{ $historico->total() }}</strong></div>
        </section>
    </div>
</div>

<section class="panel table-panel">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2 class="h5 fw-bold mb-0">Historico de reportes</h2>
    </div>
    <div class="table-responsive">
        <table class="table align-middle">
            <thead><tr><th>Periodo</th><th>Generado</th><th>Ingresos</th><th>Egresos</th><th>Balance</th><th>Estado</th><th>Acciones</th></tr></thead>
            <tbody>
            @forelse ($historico as $reporte)
                <tr>
                    <td class="fw-semibold">{{ $months[$reporte->periodo_mes] ?? $reporte->periodo_mes }} {{ $reporte->periodo_anio }}</td>
                    <td>{{ $reporte->fecha_generacion?->format('d/m/Y') }}</td>
                    <td>S/{{ number_format((float) $reporte->total_ingresos, 2) }}</td>
                    <td>S/{{ number_format((float) $reporte->total_egresos, 2) }}</td>
                    <td class="fw-bold {{ $reporte->balance_neto < 0 ? 'text-danger' : 'text-success' }}">S/{{ number_format((float) $reporte->balance_neto, 2) }}</td>
                    <td><span class="badge {{ $reporte->estado === 'aprobado' ? 'badge-soft' : ($reporte->estado === 'pendiente_aprobacion' ? 'badge-warning-soft' : 'badge-danger-soft') }}">{{ str_replace('_', ' ', ucfirst($reporte->estado)) }}</span></td>
                    <td>
                        <a class="btn btn-sm btn-outline-info" href="{{ route('admin.reportes.show', $reporte) }}">Ver</a>
                        <a class="btn btn-sm btn-outline-secondary" href="{{ route('admin.reportes.pdf', $reporte) }}">PDF</a>
                    </td>
                </tr>
            @empty
                <tr><td colspan="7" class="text-center text-secondary py-4">No hay reportes registrados.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="mt-3">{{ $historico->links() }}</div>
</section>
@endsection
