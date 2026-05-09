@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'inicio'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <h1 class="page-title">Dashboard</h1>
            <div class="page-subtitle">Mayo 2026 · Periodo activo</div>
        </div>
        <span class="status-pill">Sistema activo</span>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6">
            <div class="metric-card">
                <div class="metric-label">Total Usuarios</div>
                <div class="metric-value">{{ $totalUsuarios }}</div>
                <span class="badge badge-soft mt-2">Activos</span>
            </div>
        </div>
        <div class="col-xl-3 col-md-6">
            <div class="metric-card">
                <div class="metric-label">Al Dia</div>
                <div class="metric-value success">{{ $alDia }}</div>
                <span class="badge badge-soft mt-2">{{ $totalUsuarios ? round($alDia * 100 / $totalUsuarios, 1) : 0 }}%</span>
            </div>
        </div>
        <div class="col-xl-3 col-md-6">
            <div class="metric-card">
                <div class="metric-label">Morosos</div>
                <div class="metric-value danger">{{ $morosos }}</div>
                <span class="badge badge-danger-soft mt-2">Requieren atencion</span>
            </div>
        </div>
        <div class="col-xl-3 col-md-6">
            <div class="metric-card">
                <div class="metric-label">Balance Mayo</div>
                <div class="metric-value">S/{{ number_format($balanceMes, 2) }}</div>
                <span class="badge badge-soft mt-2">Neto</span>
            </div>
        </div>
    </div>

    <section class="panel table-panel mb-4">
        <h2 class="h5 fw-bold mb-3">Ultimos movimientos</h2>
        <div class="table-responsive">
            <table class="table align-middle">
                <thead>
                    <tr>
                        <th>N. Serie</th>
                        <th>Usuario</th>
                        <th>Monto</th>
                        <th>Fecha</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                @foreach ($movimientos as $cobro)
                    <tr>
                        <td><a class="series-link" href="#">{{ $cobro->numero_serie }}</a></td>
                        <td>{{ $cobro->vecino?->full_name }}</td>
                        <td>S/{{ number_format((float) $cobro->monto_recibido, 2) }}</td>
                        <td>{{ $cobro->fecha_cobro?->format('d/m') }}</td>
                        <td>
                            <span class="badge {{ $cobro->estado === 'pagado' ? 'badge-soft' : 'badge-danger-soft' }}">
                                {{ ucfirst($cobro->estado) }}
                            </span>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    </section>

    <section>
        <h2 class="h5 fw-bold mb-3">Acciones rapidas</h2>
        <div class="d-flex flex-wrap gap-3">
            <button class="btn btn-outline-info px-4 py-2">Registrar pago</button>
            <button class="btn btn-aqua px-4 py-2">Nuevo Usuario</button>
            <button class="btn btn-aqua px-4 py-2">Registrar Egreso</button>
            <button class="btn btn-aqua px-4 py-2">Ver Reporte</button>
        </div>
    </section>
@endsection
