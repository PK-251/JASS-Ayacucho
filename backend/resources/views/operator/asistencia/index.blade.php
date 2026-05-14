@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'asistencia'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <h1 class="page-title">Asistencia</h1>
        <div class="page-subtitle">Eventos y listas por registrar.</div>
    </div>
    <span class="status-pill">Jornada activa</span>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

@if ($pendiente)
    <section class="panel p-4 mb-4" style="border-color:#f59e0b;background:#fff1dc">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div>
                <h2 class="h4 fw-bold mb-1">{{ $pendiente->titulo }}</h2>
                <div class="text-secondary">{{ $pendiente->fecha_evento?->format('d/m/Y') }} · {{ $pendiente->lugar }} · {{ $pendiente->total_convocados }} convocados</div>
            </div>
            <a class="btn btn-aqua btn-lg" href="{{ route('operator.asistencia.show', $pendiente) }}">Pasar lista ahora</a>
        </div>
    </section>
@endif

<div class="row g-3 mb-4">
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Pendientes</div><div class="metric-value" style="color:#f59e0b">{{ $kpis['pendientes'] }}</div></div></div>
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Proximos</div><div class="metric-value">{{ $kpis['proximos'] }}</div></div></div>
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Pasados</div><div class="metric-value success">{{ $kpis['pasados'] }}</div></div></div>
</div>

<section class="panel table-panel">
    <h2 class="h5 fw-bold mb-3">Eventos</h2>
    <div class="table-responsive">
        <table class="table align-middle">
            <thead><tr><th>Fecha</th><th>Tipo</th><th>Titulo</th><th>Lugar</th><th>Convocados</th><th>Estado</th><th>Accion</th></tr></thead>
            <tbody>
            @foreach ($eventos as $evento)
                <tr>
                    <td>{{ $evento->fecha_evento?->format('d/m/Y') }}<br><span class="text-secondary small">{{ substr($evento->hora_inicio, 0, 5) }}</span></td>
                    <td><span class="badge badge-soft">{{ $evento->tipo?->nombre }}</span></td>
                    <td class="fw-semibold">{{ $evento->titulo }}</td>
                    <td>{{ $evento->lugar }}</td>
                    <td>{{ $evento->total_convocados }}</td>
                    <td><span class="badge {{ $evento->estado === 'realizado' ? 'badge-soft' : 'badge-warning-soft' }}">{{ str_replace('_', ' ', ucfirst($evento->estado)) }}</span></td>
                    <td><a class="btn btn-sm btn-outline-info" href="{{ route('operator.asistencia.show', $evento) }}">Ver lista</a></td>
                </tr>
            @endforeach
            </tbody>
        </table>
    </div>
    <div class="mt-3">{{ $eventos->links() }}</div>
</section>
@endsection
