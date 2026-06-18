@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'multas'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Administracion</div>
            <h1 class="page-title">Multas y Tarifas</h1>
            <div class="page-subtitle">Configura cuotas mensuales, historial tarifario y tipos de multa.</div>
        </div>
        <div class="page-actions">
            <a class="btn btn-outline-info btn-icon" href="{{ route('admin.tarifas.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="m16.5 3.5 4 4L8 20H4v-4L16.5 3.5Z"/></svg></span>Actualizar tarifa</a>
            <a class="btn btn-aqua btn-icon" href="{{ route('admin.multas.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Nueva multa</a>
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><x-metric-card label="Tarifas vigentes" icon="tag" badge="Por categoria">{{ $tarifasActivas }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Multas activas" icon="gavel" badge="Configuradas">{{ $multasActivas }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Multas aplicadas" icon="gavel" tone="danger" valueClass="danger" badge="Historico" badgeClass="badge-warning-soft">{{ $multasAplicadas }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Inactivas" icon="alert-triangle" tone="warning" valueClass="warning" badge="Sin uso" badgeClass="badge-danger-soft">{{ $multasInactivas }}</x-metric-card></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-8">
            <section class="panel p-4 h-100">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="h5 fw-bold mb-0">Tarifas por categoria</h2>
                    <a class="btn btn-sm btn-outline-info btn-icon" href="{{ route('admin.tarifas.create') }}">Modificar cuota</a>
                </div>
                <div class="row g-3">
                    @foreach ($tarifasVigentes as $tarifa)
                        <div class="col-md-4">
                            <div class="panel p-3 h-100" style="box-shadow:none">
                                <div class="text-secondary small">{{ $tarifa->categoria?->nombre }}</div>
                                <div class="metric-value">S/{{ number_format((float) $tarifa->monto, 2) }}</div>
                                <div class="small text-secondary">Desde {{ $tarifa->fecha_vigencia_inicio?->format('d/m/Y') }}</div>
                                <div class="small mt-2">{{ $tarifa->motivo_cambio }}</div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </section>
        </div>
        <div class="col-lg-4">
            <section class="panel p-4 h-100">
                <h2 class="h5 fw-bold mb-3">Historial reciente</h2>
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Fecha</th><th>Categoria</th><th>Monto</th></tr></thead>
                        <tbody>
                            @foreach ($historialTarifas as $tarifa)
                                <tr><td>{{ $tarifa->fecha_vigencia_inicio?->format('d/m/Y') }}</td><td>{{ $tarifa->categoria?->nombre }}</td><td class="fw-bold">S/{{ number_format((float) $tarifa->monto, 2) }}</td></tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </section>
        </div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2 class="h5 fw-bold mb-0">Tipos de multa configurados</h2>
            <a class="btn btn-aqua btn-icon" href="{{ route('admin.multas.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Nueva multa</a>
        </div>
        <div class="table-responsive">
            <table class="table align-middle">
                <thead><tr><th>Codigo</th><th>Nombre</th><th>Descripcion</th><th>Monto</th><th>Aplicacion</th><th>Estado</th><th>Aplicadas</th><th>Acciones</th></tr></thead>
                <tbody>
                    @forelse ($multas as $multa)
                        <tr>
                            <td class="series-link">{{ $multa->codigo }}</td>
                            <td class="fw-semibold">{{ $multa->nombre }}</td>
                            <td>{{ Str::limit($multa->descripcion, 45) }}</td>
                            <td class="fw-bold">S/{{ number_format((float) $multa->monto, 2) }}</td>
                            <td>{{ str_replace('_', ' ', ucfirst($multa->tipo_aplicacion)) }}</td>
                            <td><span class="badge {{ $multa->activa ? 'badge-soft' : 'badge-danger-soft' }}">{{ $multa->activa ? 'Activa' : 'Inactiva' }}</span></td>
                            <td>{{ $multa->aplicadas_count }}</td>
                            <td>
                                <div class="page-actions">
                                    <a class="btn btn-sm btn-outline-secondary btn-icon" href="{{ route('admin.multas.edit', $multa) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="m16.5 3.5 4 4L8 20H4v-4L16.5 3.5Z"/></svg></span>Editar</a>
                                    @if ($multa->activa)
                                        <form method="POST" action="{{ route('admin.multas.destroy', $multa) }}" onsubmit="return confirm('Desactivar esta multa?')">
                                            @csrf
                                            @method('DELETE')
                                            <button class="btn btn-sm btn-outline-danger btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/></svg></span>Desactivar</button>
                                        </form>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="8" class="text-center text-secondary py-4">No hay multas configuradas.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </section>
@endsection
