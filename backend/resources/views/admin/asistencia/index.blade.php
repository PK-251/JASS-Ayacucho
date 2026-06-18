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
    <a class="btn btn-aqua btn-icon" href="{{ route('admin.asistencia.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Crear evento</a>
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
            <a class="btn btn-aqua btn-icon" href="{{ route('admin.asistencia.show', $pendiente) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m20 6-11 11-5-5"/></svg></span>Pasar lista ahora</a>
        </div>
    </section>
@endif

<div class="row g-3 mb-4">
    <div class="col-xl-3 col-md-6"><x-metric-card label="Listas pendientes" icon="clipboard-list" tone="warning" valueClass="warning" badge="Requieren atencion" badgeClass="badge-warning-soft">{{ $kpis['pendientes'] }}</x-metric-card></div>
    <div class="col-xl-3 col-md-6"><x-metric-card label="Proximos eventos" icon="calendar" badge="Programados">{{ $kpis['proximos'] }}</x-metric-card></div>
    <div class="col-xl-3 col-md-6"><x-metric-card label="Realizados mes" icon="calendar-check" tone="success" valueClass="success" :badge="ucfirst(now()->locale('es')->translatedFormat('F Y'))">{{ $kpis['realizados_mes'] }}</x-metric-card></div>
    <div class="col-xl-3 col-md-6"><x-metric-card label="Multas activas" icon="gavel" tone="danger" valueClass="danger" badge="Inasistencia" badgeClass="badge-danger-soft">{{ $kpis['multas_pendientes'] }}</x-metric-card></div>
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
                    <td><a class="btn btn-sm btn-outline-info btn-icon" href="{{ route('admin.asistencia.show', $evento) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></span>Ver</a></td>
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
