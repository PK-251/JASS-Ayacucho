@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'asistencia'])
@endsection

@section('content')
@php
    $canEdit = $evento->estado !== 'realizado' && $evento->estado !== 'cancelado';
    $pct = $stats['total'] ? round(($stats['marcados'] * 100) / $stats['total']) : 0;
@endphp

<div class="topbar">
    <div>
        <div class="page-subtitle">Control de Asistencia</div>
        <h1 class="page-title">{{ $evento->titulo }}</h1>
        <div class="page-subtitle">{{ $evento->fecha_evento?->format('d/m/Y') }} · {{ substr($evento->hora_inicio, 0, 5) }} · {{ $evento->lugar }}</div>
    </div>
    <div class="d-flex gap-2 flex-wrap">
        <a class="btn btn-outline-secondary" href="{{ route('admin.asistencia.index') }}">Volver</a>
        @if ($evento->estado === 'programado')
            <form method="POST" action="{{ route('admin.asistencia.generar-lista', $evento) }}">@csrf<button class="btn btn-aqua">Generar lista</button></form>
        @endif
        @if ($canEdit)
            <form method="POST" action="{{ route('admin.asistencia.confirmar', $evento) }}" onsubmit="return confirm('Se confirmara la lista y se aplicaran multas a los ausentes. ¿Continuar?')">@csrf<button class="btn btn-success">Confirmar y aplicar multas</button></form>
        @endif
    </div>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif
@if ($errors->any())
    <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
@endif

<div class="row g-3 mb-4">
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Convocados</div><div class="metric-value">{{ $stats['total'] }}</div></div></div>
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Marcados</div><div class="metric-value">{{ $stats['marcados'] }}</div><span class="badge badge-soft mt-2">{{ $pct }}%</span></div></div>
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Presentes</div><div class="metric-value success">{{ $stats['presentes'] }}</div></div></div>
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Tardes</div><div class="metric-value" style="color:#f59e0b">{{ $stats['tardes'] }}</div></div></div>
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Justificados</div><div class="metric-value">{{ $stats['justificados'] }}</div></div></div>
    <div class="col-xl-2 col-md-4"><div class="metric-card"><div class="metric-label">Ausentes</div><div class="metric-value danger">{{ $stats['ausentes'] }}</div></div></div>
</div>

<section class="panel table-panel">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h2 class="h5 fw-bold mb-0">Detalle de usuarios</h2>
        <span class="badge {{ $evento->estado === 'realizado' ? 'badge-soft' : 'badge-warning-soft' }}">{{ str_replace('_', ' ', ucfirst($evento->estado)) }}</span>
    </div>
    <div class="table-responsive">
        <table class="table align-middle">
            <thead><tr><th>Usuario</th><th>Documento</th><th>Estado</th><th>Detalle</th><th>Acciones</th></tr></thead>
            <tbody>
            @foreach ($asistencias as $asistencia)
                @php
                    $badge = ['presente'=>'badge-soft','tarde'=>'badge-warning-soft','justificado'=>'badge-soft','ausente'=>'badge-danger-soft','no_marcado'=>'badge-warning-soft'][$asistencia->estado] ?? 'badge-soft';
                @endphp
                <tr>
                    <td class="fw-semibold">{{ $asistencia->vecino?->nombres }} {{ $asistencia->vecino?->apellidos }}<br><span class="text-secondary small">{{ $asistencia->vecino?->codigo }}</span></td>
                    <td>{{ $asistencia->vecino?->documento_num }}</td>
                    <td><span class="badge {{ $badge }}">{{ str_replace('_', ' ', ucfirst($asistencia->estado)) }}</span></td>
                    <td>
                        @if ($asistencia->estado === 'tarde') Llegada: {{ substr($asistencia->hora_llegada, 0, 5) }} @endif
                        @if ($asistencia->estado === 'justificado') {{ $asistencia->motivo_justificacion }} @endif
                        @if ($asistencia->multa_aplicada_id) <span class="text-danger fw-semibold">Multa aplicada</span> @endif
                    </td>
                    <td>
                        @if ($canEdit)
                            <div class="d-flex flex-wrap gap-1">
                                @foreach (['presente' => 'P', 'tarde' => 'T', 'justificado' => 'J', 'ausente' => 'A'] as $estado => $label)
                                    <form method="POST" action="{{ route('admin.asistencia.update-attendance', $asistencia) }}">
                                        @csrf @method('PATCH')
                                        <input type="hidden" name="estado" value="{{ $estado }}">
                                        @if ($estado === 'tarde')<input type="hidden" name="hora_llegada" value="{{ now()->format('H:i') }}">@endif
                                        @if ($estado === 'justificado')<input type="hidden" name="motivo_justificacion" value="Justificacion registrada por administrador">@endif
                                        <button class="btn btn-sm {{ $asistencia->estado === $estado ? 'btn-aqua' : 'btn-outline-info' }}" title="{{ ucfirst($estado) }}">{{ $label }}</button>
                                    </form>
                                @endforeach
                            </div>
                        @else
                            <span class="text-secondary">Lista cerrada</span>
                        @endif
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
    </div>
    <div class="mt-3">{{ $asistencias->links() }}</div>
</section>
@endsection
