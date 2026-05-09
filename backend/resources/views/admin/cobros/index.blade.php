@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Gestion</div>
            <h1 class="page-title">Cobros</h1>
            <div class="page-subtitle">Registro, seguimiento y anulacion de pagos.</div>
        </div>
        <a class="btn btn-aqua px-4" href="{{ route('admin.cobros.create') }}">Nuevo Cobro</a>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Cobros mes</div><div class="metric-value">{{ $cobrosMes }}</div><span class="badge badge-soft mt-2">Pagados</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Total recaudado</div><div class="metric-value">S/{{ number_format((float) $totalRecaudado, 2) }}</div><span class="badge badge-soft mt-2">Mayo {{ $anio }}</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Anulados</div><div class="metric-value danger">{{ $anulados }}</div><span class="badge badge-danger-soft mt-2">Auditoria</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Pendientes</div><div class="metric-value" style="color:#f59e0b">{{ $pendientes }}</div><span class="badge badge-warning-soft mt-2">Por cobrar</span></div></div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <h2 class="h5 fw-bold mb-0">Historial de cobros</h2>
            <form method="GET" action="{{ route('admin.cobros.index') }}" class="d-flex flex-wrap gap-2">
                <input type="hidden" name="anio" value="{{ $anio }}">
                <input type="hidden" name="mes" value="{{ $mes }}">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar usuario o serie...">
                <select class="form-select" name="estado" style="max-width:160px">
                    <option value="">Todos</option>
                    <option value="pagado" @selected($estado === 'pagado')>Pagados</option>
                    <option value="anulado" @selected($estado === 'anulado')>Anulados</option>
                </select>
                <button class="btn btn-outline-info">Filtrar</button>
            </form>
        </div>

        <div class="table-responsive">
            <table class="table align-middle">
                <thead>
                    <tr>
                        <th>N. Serie</th>
                        <th>Fecha/Hora</th>
                        <th>Usuario</th>
                        <th>Concepto</th>
                        <th>Metodo</th>
                        <th>Monto</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                @forelse ($cobros as $cobro)
                    <tr>
                        <td><a class="series-link" href="{{ route('admin.cobros.show', $cobro) }}">{{ $cobro->numero_serie }}</a></td>
                        <td>{{ $cobro->fecha_cobro?->format('d/m/Y') }}<br><span class="text-secondary small">{{ substr((string) $cobro->hora_cobro, 0, 5) }}</span></td>
                        <td class="fw-semibold">{{ $cobro->vecino?->full_name }}</td>
                        <td>Cuota {{ str_pad($cobro->periodo_mes, 2, '0', STR_PAD_LEFT) }}/{{ $cobro->periodo_anio }}</td>
                        <td>{{ ucfirst($cobro->metodo_pago) }}</td>
                        <td class="fw-bold">S/{{ number_format((float) $cobro->monto_recibido, 2) }}</td>
                        <td><span class="badge {{ $cobro->estado === 'pagado' ? 'badge-soft' : 'badge-danger-soft' }}">{{ ucfirst($cobro->estado) }}</span></td>
                        <td>
                            <div class="d-flex gap-2">
                                <a class="btn btn-sm btn-outline-info" href="{{ route('admin.cobros.show', $cobro) }}">Ver</a>
                                @if ($cobro->estado === 'pagado')
                                    <a class="btn btn-sm btn-outline-secondary" href="{{ route('admin.cobros.edit', $cobro) }}">Editar</a>
                                @endif
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="text-center text-secondary py-4">No se encontraron cobros.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-3">
            <div class="text-secondary small">Mostrando {{ $cobros->firstItem() }} a {{ $cobros->lastItem() }} de {{ $cobros->total() }} registros</div>
            {{ $cobros->links() }}
        </div>
    </section>
@endsection
