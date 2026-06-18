@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'asistencia'])
@endsection

@section('content')
@php($canEdit = $evento->estado !== 'realizado')
<div class="topbar">
    <div>
        <h1 class="page-title">{{ $evento->titulo }}</h1>
        <div class="page-subtitle">{{ $evento->fecha_evento?->format('d/m/Y') }} · {{ substr($evento->hora_inicio, 0, 5) }} · {{ $evento->lugar }}</div>
    </div>
    <div class="page-actions">
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('operator.asistencia.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
        @if ($canEdit)
            <form method="POST" action="{{ route('operator.asistencia.confirmar', $evento) }}" onsubmit="return confirm('Se cerrara la lista y se aplicaran multas a ausentes. ¿Continuar?')">@csrf<button class="btn btn-success btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m20 6-11 11-5-5"/></svg></span>Confirmar y aplicar multas</button></form>
        @endif
    </div>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

<div class="row g-3 mb-4">
    <div class="col-md-2"><x-metric-card label="Convocados" icon="users">{{ $stats['total'] }}</x-metric-card></div>
    <div class="col-md-2"><x-metric-card label="Marcados" icon="file-text">{{ $stats['marcados'] }}</x-metric-card></div>
    <div class="col-md-2"><x-metric-card label="Presentes" icon="user-check" tone="success" valueClass="success">{{ $stats['presentes'] }}</x-metric-card></div>
    <div class="col-md-2"><x-metric-card label="Tardes" icon="clock" tone="warning" valueClass="warning">{{ $stats['tardes'] }}</x-metric-card></div>
    <div class="col-md-2"><x-metric-card label="Justif." icon="clipboard-list">{{ $stats['justificados'] }}</x-metric-card></div>
    <div class="col-md-2"><x-metric-card label="Ausentes" icon="user-x" tone="danger" valueClass="danger">{{ $stats['ausentes'] }}</x-metric-card></div>
</div>

<section class="panel table-panel">
    <h2 class="h5 fw-bold mb-3">Lista de usuarios</h2>
    <div class="table-responsive">
        <table class="table align-middle">
            <thead><tr><th>Usuario</th><th>Estado</th><th>Detalle</th><th>Marcar</th></tr></thead>
            <tbody>
            @foreach ($asistencias as $asistencia)
                @php($badge = ['presente'=>'badge-soft','tarde'=>'badge-warning-soft','justificado'=>'badge-soft','ausente'=>'badge-danger-soft','no_marcado'=>'badge-warning-soft'][$asistencia->estado] ?? 'badge-soft')
                <tr>
                    <td class="fw-semibold">{{ $asistencia->vecino?->full_name }}<br><span class="text-secondary small">{{ $asistencia->vecino?->codigo }} · {{ $asistencia->vecino?->direccion }}</span></td>
                    <td><span class="badge {{ $badge }}">{{ str_replace('_', ' ', ucfirst($asistencia->estado)) }}</span></td>
                    <td>{{ $asistencia->motivo_justificacion ?: '-' }}</td>
                    <td>
                        @if ($canEdit)
                            <div class="d-flex flex-wrap gap-1">
                            @foreach (['presente' => 'P', 'tarde' => 'T', 'justificado' => 'J', 'ausente' => 'A'] as $estado => $label)
                                <form method="POST" action="{{ route('operator.asistencia.update', $asistencia) }}">
                                    @csrf @method('PATCH')
                                    <input type="hidden" name="estado" value="{{ $estado }}">
                                    @if ($estado === 'tarde')<input type="hidden" name="hora_llegada" value="{{ now()->format('H:i') }}">@endif
                                    @if ($estado === 'justificado')<input type="hidden" name="motivo_justificacion" value="Justificacion registrada por operador">@endif
                                    <button class="btn btn-sm {{ $asistencia->estado === $estado ? 'btn-aqua' : 'btn-outline-info' }}">{{ $label }}</button>
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
