@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'ingresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Finanzas</div>
            <h1 class="page-title">Ingresos</h1>
            <div class="page-subtitle">Resumen y gestion de ingresos registrados.</div>
        </div>
        <a class="btn btn-aqua btn-icon px-4" href="{{ route('admin.ingresos.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Registrar ingreso manual</a>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><x-metric-card label="Total ingresos" icon="trending-up" tone="success" :badge="'Mayo ' . $anio">S/{{ number_format((float) $totalIngresos, 2) }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Transacciones" icon="hash" :badge="$deCobros . ' de cobros'">{{ $totalTransacciones }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Ticket promedio" icon="calculator" :badge="$manuales . ' manuales'">S/{{ number_format((float) $ticketPromedio, 2) }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Pendiente de cobro" icon="alert-triangle" tone="danger" valueClass="danger" badge="Padron" badgeClass="badge-danger-soft">S/{{ number_format((float) $pendienteCobro, 2) }}</x-metric-card></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-4">
            <section class="panel p-4 h-100">
                <h2 class="h5 fw-bold mb-3">Distribucion por concepto</h2>
                @php($baseTotal = max((float) $totalIngresos, 0.01))
                @forelse ($categorias as $cat)
                    @php($pct = round(((float) $cat->total) * 100 / $baseTotal, 1))
                    <div class="mb-3">
                        <div class="d-flex justify-content-between small fw-semibold"><span>{{ $cat->categoria }}</span><span>{{ $pct }}%</span></div>
                        <div class="progress" style="height:8px"><div class="progress-bar bg-info" style="width: {{ $pct }}%"></div></div>
                        <div class="small text-secondary mt-1">S/{{ number_format((float) $cat->total, 2) }} · {{ $cat->cantidad }} mov.</div>
                    </div>
                @empty
                    <div class="text-secondary">Sin movimientos para este periodo.</div>
                @endforelse
            </section>
        </div>
        <div class="col-lg-8">
            <section class="panel p-4 h-100">
                <h2 class="h5 fw-bold mb-3">Regla del modulo</h2>
                <div class="alert alert-info border-0 mb-0">
                    Los ingresos por cobros se administran desde <strong>Cobros</strong>. Aqui solo se registran y modifican ingresos manuales como donaciones, cuotas extraordinarias, ventas o reintegros.
                </div>
            </section>
        </div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <h2 class="h5 fw-bold mb-0">Movimientos recientes</h2>
            <form method="GET" action="{{ route('admin.ingresos.index') }}" class="d-flex flex-wrap gap-2">
                <input type="hidden" name="anio" value="{{ $anio }}">
                <input type="hidden" name="mes" value="{{ $mes }}">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar usuario o recibo...">
                <select class="form-select" name="origen" style="max-width:150px">
                    <option value="">Origen</option>
                    <option value="cobro" @selected($origen === 'cobro')>Cobro</option>
                    <option value="manual" @selected($origen === 'manual')>Manual</option>
                </select>
                <select class="form-select" name="estado" style="max-width:150px">
                    <option value="">Estado</option>
                    <option value="pagado" @selected($estado === 'pagado')>Pagado</option>
                    <option value="activo" @selected($estado === 'activo')>Activo</option>
                    <option value="anulado" @selected($estado === 'anulado')>Anulado</option>
                </select>
                <button class="btn btn-outline-info btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M3 5h18"/><path d="M6 12h12"/><path d="M10 19h4"/></svg></span>Filtrar</button>
            </form>
        </div>

        <div class="table-responsive">
            <table class="table align-middle">
                <thead>
                    <tr>
                        <th>N. Serie</th>
                        <th>Fecha</th>
                        <th>Origen</th>
                        <th>Usuario</th>
                        <th>Concepto</th>
                        <th>Metodo</th>
                        <th>Monto</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($movimientos as $mov)
                        <tr>
                            <td class="series-link">{{ $mov->numero_serie }}</td>
                            <td>{{ \Carbon\Carbon::parse($mov->fecha_ingreso)->format('d/m/Y') }}</td>
                            <td><span class="badge {{ $mov->origen === 'cobro' ? 'badge-soft' : 'badge-warning-soft' }}">{{ ucfirst($mov->origen) }}</span></td>
                            <td>{{ $mov->vecino_nombre }}</td>
                            <td>{{ $mov->concepto }}</td>
                            <td>{{ ucfirst($mov->metodo_pago) }}</td>
                            <td class="fw-bold">S/{{ number_format((float) $mov->monto, 2) }}</td>
                            <td><span class="badge {{ in_array($mov->estado, ['pagado','activo']) ? 'badge-soft' : 'badge-danger-soft' }}">{{ ucfirst($mov->estado) }}</span></td>
                            <td>
                                @if ($mov->origen === 'manual')
                                    <a class="btn btn-sm btn-outline-info btn-icon" href="{{ route('admin.ingresos.show', $mov->id) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></span>Ver</a>
                                @else
                                    <a class="btn btn-sm btn-outline-secondary btn-icon" href="{{ route('admin.cobros.show', $mov->id) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6"/></svg></span>Ir a Cobros</a>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="9" class="text-center text-secondary py-4">No se encontraron ingresos.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-3">
            <div class="text-secondary small">Mostrando {{ $movimientos->firstItem() }} a {{ $movimientos->lastItem() }} de {{ $movimientos->total() }} registros</div>
            {{ $movimientos->links() }}
        </div>
    </section>
@endsection
