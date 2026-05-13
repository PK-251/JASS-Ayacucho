@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'asistencia'])
@endsection

@section('content')
@php
    $estadoBadge = ['programado' => 'badge-soft', 'lista_pendiente' => 'badge-warning-soft', 'realizado' => 'badge-soft', 'cancelado' => 'badge-danger-soft'];
@endphp

<div class="topbar">
    <div>
        <div class="page-subtitle">Administracion / Asistencia</div>
        <h1 class="page-title">Control de Asistencia</h1>
        <div class="page-subtitle">Eventos, reuniones, pase de lista y multas por inasistencia.</div>
    </div>
    <a class="btn btn-aqua" href="{{ route('admin.asistencia.create') }}">+ Crear evento</a>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

@if ($pendiente)
    <section class="panel p-4 mb-4" style="border-color:#f59e0b; background:#fff8dd">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
                <div class="fw-bold text-warning mb-1">{{ $pendiente->titulo }}</div>
                <div class="text-secondary">Lista pendiente por registrar. {{ $pendiente->total_convocados }} usuarios convocados.</div>
            </div>
            <a class="btn btn-aqua" href="{{ route('admin.asistencia.show', $pendiente) }}">Pasar lista ahora</a>
        </div>
    </section>
@endif

<div class="row g-3 mb-4">
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Listas pendientes</div><div class="metric-value" style="color:#f59e0b">{{ $kpis['pendientes'] }}</div><span class="badge badge-warning-soft mt-2">Requieren atencion</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Proximos eventos</div><div class="metric-value">{{ $kpis['proximos'] }}</div><span class="badge badge-soft mt-2">Programados</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Realizados mes</div><div class="metric-value success">{{ $kpis['realizados_mes'] }}</div><span class="badge badge-soft mt-2">Mayo 2026</span></div></div>
    <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Multas activas</div><div class="metric-value danger">{{ $kpis['multas_pendientes'] }}</div><span class="badge badge-danger-soft mt-2">Inasistencia</span></div></div>
</div>

<section class="panel table-panel">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2 class="h5 fw-bold mb-0">Registro de eventos</h2>
    </div>
    <div class="table-responsive">
        <table class="table align-middle">
            <thead><tr><th>Fecha</th><th>Tipo</th><th>Titulo</th><th>Lugar</th><th>Convocados</th><th>Asistencia</th><th>Estado</th><th>Acciones</th></tr></thead>
            <tbody>
            @forelse ($eventos as $evento)
                @php($asistencia = $evento->total_convocados ? round((($evento->presentes_count ?? 0) * 100) / max(1, $evento->total_convocados), 1) : 0)
                <tr>
                    <td>{{ $evento->fecha_evento?->format('d/m/Y') }}<br><span class="text-secondary small">{{ substr($evento->hora_inicio, 0, 5) }}</span></td>
                    <td><span class="badge badge-soft">{{ $evento->tipo?->nombre ?? 'Evento' }}</span></td>
                    <td class="fw-semibold">{{ $evento->titulo }}</td>
                    <td>{{ $evento->lugar }}</td>
                    <td>{{ $evento->total_convocados }}</td>
                    <td>{{ $evento->estado === 'realizado' ? $asistencia.'%' : '-' }}</td>
                    <td><span class="badge {{ $estadoBadge[$evento->estado] ?? 'badge-soft' }}">{{ str_replace('_', ' ', ucfirst($evento->estado)) }}</span></td>
                    <td><a class="btn btn-sm btn-outline-info" href="{{ route('admin.asistencia.show', $evento) }}">Ver</a></td>
                </tr>
            @empty
                <tr><td colspan="8" class="text-center text-secondary py-4">No hay eventos registrados.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="mt-3">{{ $eventos->links() }}</div>
</section>
@endsection
