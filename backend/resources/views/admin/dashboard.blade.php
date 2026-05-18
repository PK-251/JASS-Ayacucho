@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'inicio'])
@endsection

@section('content')
    @php($balanceEsDeficit = $balanceMes < 0)
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
                <div class="metric-value {{ $balanceEsDeficit ? 'danger' : '' }}">S/{{ number_format(abs($balanceMes), 2) }}</div>
                <span class="badge {{ $balanceEsDeficit ? 'badge-danger-soft' : 'badge-soft' }} mt-2">{{ $balanceEsDeficit ? 'Deficit' : 'Neto' }}</span>
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
                        <td><a class="series-link" href="{{ route('admin.cobros.show', $cobro) }}">{{ $cobro->numero_serie }}</a></td>
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
        <div class="d-flex flex-wrap gap-3 quick-actions">
            <a class="btn btn-outline-info btn-icon px-4 py-2" href="{{ route('admin.cobros.create') }}">
                <span class="action-icon"><svg viewBox="0 0 24 24"><path d="M19 7V5a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5"/><path d="M16 13h.01"/></svg></span>
                Registrar pago
            </a>
            <a class="btn btn-aqua btn-icon px-4 py-2" href="{{ route('admin.usuarios.create') }}">
                <span class="action-icon"><svg viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6"/><path d="M22 11h-6"/></svg></span>
                Nuevo Usuario
            </a>
            <a class="btn btn-aqua btn-icon px-4 py-2" href="{{ route('admin.egresos.create') }}">
                <span class="action-icon"><svg viewBox="0 0 24 24"><path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M8 8h8"/><path d="M8 12h8"/><path d="M8 16h5"/></svg></span>
                Registrar Egreso
            </a>
            <a class="btn btn-aqua btn-icon px-4 py-2" href="{{ route('admin.reportes.index') }}">
                <span class="action-icon"><svg viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="M7 16v-5"/><path d="M12 16V7"/><path d="M17 16v-3"/></svg></span>
                Ver Reporte
            </a>
        </div>
    </section>
@endsection


@push('styles')
<style>
.quick-actions .btn { display:inline-flex; align-items:center; gap:10px; min-width:154px; justify-content:center; font-weight:800; }
.action-icon { width:20px; height:20px; display:inline-grid; place-items:center; }
.action-icon svg { width:19px; height:19px; stroke:currentColor; stroke-width:2.2; fill:none; stroke-linecap:round; stroke-linejoin:round; }
@media (max-width: 640px) { .quick-actions .btn { width:100%; } }
</style>
@endpush
