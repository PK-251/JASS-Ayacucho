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
        <div class="d-flex gap-2">
            <a class="btn btn-outline-info" href="{{ route('admin.tarifas.create') }}">Actualizar tarifa</a>
            <a class="btn btn-aqua" href="{{ route('admin.multas.create') }}">Nueva multa</a>
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Tarifas vigentes</div><div class="metric-value">{{ $tarifasActivas }}</div><span class="badge badge-soft mt-2">Por categoria</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Multas activas</div><div class="metric-value">{{ $multasActivas }}</div><span class="badge badge-soft mt-2">Configuradas</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Multas aplicadas</div><div class="metric-value danger">{{ $multasAplicadas }}</div><span class="badge badge-warning-soft mt-2">Historico</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Inactivas</div><div class="metric-value" style="color:#f59e0b">{{ $multasInactivas }}</div><span class="badge badge-danger-soft mt-2">Sin uso</span></div></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-8">
            <section class="panel p-4 h-100">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="h5 fw-bold mb-0">Tarifas por categoria</h2>
                    <a class="btn btn-sm btn-outline-info" href="{{ route('admin.tarifas.create') }}">Modificar cuota</a>
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
            <a class="btn btn-aqua" href="{{ route('admin.multas.create') }}">Nueva multa</a>
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
                                <div class="d-flex gap-2">
                                    <a class="btn btn-sm btn-outline-secondary" href="{{ route('admin.multas.edit', $multa) }}">Editar</a>
                                    @if ($multa->activa)
                                        <form method="POST" action="{{ route('admin.multas.destroy', $multa) }}" onsubmit="return confirm('Desactivar esta multa?')">
                                            @csrf
                                            @method('DELETE')
                                            <button class="btn btn-sm btn-outline-danger">Desactivar</button>
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
