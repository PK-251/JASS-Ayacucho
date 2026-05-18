@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'egresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Finanzas</div>
            <h1 class="page-title">Egresos</h1>
            <div class="page-subtitle">Gestion de gastos, proveedores, aprobaciones y comprobantes.</div>
        </div>
        <a class="btn btn-aqua btn-icon px-4" href="{{ route('admin.egresos.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Registrar egreso</a>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Total egresos</div><div class="metric-value danger">S/{{ number_format((float) $totalEgresos, 2) }}</div><span class="badge badge-danger-soft mt-2">Mayo {{ $anio }}</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">N. de egresos</div><div class="metric-value">{{ $numEgresos }}</div><span class="badge badge-soft mt-2">Este mes</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Gasto promedio</div><div class="metric-value">S/{{ number_format((float) $gastoPromedio, 2) }}</div><span class="badge badge-soft mt-2">Por movimiento</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Pendientes</div><div class="metric-value" style="color:#f59e0b">{{ $pendientesAprobacion }}</div><span class="badge badge-warning-soft mt-2">Por aprobar</span></div></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-4">
            <section class="panel p-4 h-100">
                <h2 class="h5 fw-bold mb-3">Distribucion por categoria</h2>
                @php($baseTotal = max((float) $distribucion->sum('total'), 0.01))
                @foreach ($distribucion as $item)
                    @php($pct = round(((float) $item->total) * 100 / $baseTotal, 1))
                    <div class="mb-3">
                        <div class="d-flex justify-content-between small fw-semibold"><span>{{ $item->nombre }}</span><span>{{ $pct }}%</span></div>
                        <div class="progress" style="height:8px"><div class="progress-bar bg-info" style="width: {{ $pct }}%"></div></div>
                        <div class="small text-secondary mt-1">S/{{ number_format((float) $item->total, 2) }} · {{ $item->cantidad }} mov.</div>
                    </div>
                @endforeach
            </section>
        </div>
        <div class="col-lg-8">
            <section class="panel p-4 h-100">
                <h2 class="h5 fw-bold mb-3">Control de aprobacion</h2>
                <div class="alert alert-warning border-0 mb-0">Los egresos mayores al umbral configurado o de categorias sensibles quedan como <strong>pendientes de aprobacion</strong> antes de afectar reportes oficiales.</div>
            </section>
        </div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <h2 class="h5 fw-bold mb-0">Movimientos de egreso</h2>
            <form method="GET" action="{{ route('admin.egresos.index') }}" class="d-flex flex-wrap gap-2">
                <input type="hidden" name="anio" value="{{ $anio }}">
                <input type="hidden" name="mes" value="{{ $mes }}">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar concepto, proveedor o serie...">
                <select class="form-select" name="estado" style="max-width:180px">
                    <option value="">Estado</option>
                    <option value="aprobado" @selected($estado === 'aprobado')>Aprobado</option>
                    <option value="pendiente_aprobacion" @selected($estado === 'pendiente_aprobacion')>Pendiente</option>
                    <option value="rechazado" @selected($estado === 'rechazado')>Rechazado</option>
                    <option value="anulado" @selected($estado === 'anulado')>Anulado</option>
                </select>
                <select class="form-select" name="categoria_id" style="max-width:190px">
                    <option value="">Categoria</option>
                    @foreach ($categorias as $categoria)
                        <option value="{{ $categoria->id }}" @selected((string) $categoriaId === (string) $categoria->id)>{{ $categoria->nombre }}</option>
                    @endforeach
                </select>
                <button class="btn btn-outline-info btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M3 5h18"/><path d="M6 12h12"/><path d="M10 19h4"/></svg></span>Filtrar</button>
            </form>
        </div>

        <div class="table-responsive">
            <table class="table align-middle">
                <thead><tr><th>N. Serie</th><th>Fecha</th><th>Concepto</th><th>Categoria</th><th>Proveedor</th><th>Monto</th><th>Estado</th><th>Acciones</th></tr></thead>
                <tbody>
                @forelse ($egresos as $egreso)
                    <tr>
                        <td><a class="series-link" href="{{ route('admin.egresos.show', $egreso) }}">{{ $egreso->numero_serie }}</a></td>
                        <td>{{ $egreso->fecha_egreso?->format('d/m/Y') }}</td>
                        <td class="fw-semibold">{{ $egreso->concepto }}</td>
                        <td>{{ $egreso->categoria?->nombre }}</td>
                        <td>{{ $egreso->proveedor?->nombre ?? 'Sin proveedor' }}</td>
                        <td class="fw-bold text-danger">-S/{{ number_format((float) $egreso->monto, 2) }}</td>
                        <td>
                            <span class="badge {{ $egreso->estado === 'aprobado' ? 'badge-soft' : ($egreso->estado === 'pendiente_aprobacion' ? 'badge-warning-soft' : 'badge-danger-soft') }}">{{ str_replace('_', ' ', ucfirst($egreso->estado)) }}</span>
                        </td>
                        <td><a class="btn btn-sm btn-outline-info btn-icon" href="{{ route('admin.egresos.show', $egreso) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></span>Ver</a></td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="text-center text-secondary py-4">No se encontraron egresos.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-3">
            <div class="text-secondary small">Mostrando {{ $egresos->firstItem() }} a {{ $egresos->lastItem() }} de {{ $egresos->total() }} registros</div>
            {{ $egresos->links() }}
        </div>
    </section>
@endsection
