@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Detalle de Cobro</div>
            <h1 class="page-title">{{ $cobro->numero_serie }}</h1>
            <div class="page-subtitle">{{ $cobro->fecha_cobro?->format('d/m/Y') }} · {{ substr((string) $cobro->hora_cobro, 0, 5) }}</div>
        </div>
        <div class="page-actions">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.cobros.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
            <a class="btn btn-outline-info btn-icon" href="{{ route('admin.cobros.pdf', $cobro) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6"/></svg></span>Descargar PDF</a>
            @if ($cobro->estado === 'pagado')
                <a class="btn btn-aqua btn-icon" href="{{ route('admin.cobros.edit', $cobro) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="m16.5 3.5 4 4L8 20H4v-4L16.5 3.5Z"/></svg></span>Editar</a>
            @endif
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3">
        <div class="col-lg-7">
            <section class="panel p-4 mb-3">
                <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                        <span class="badge {{ $cobro->estado === 'pagado' ? 'badge-soft' : 'badge-danger-soft' }} mb-3">{{ ucfirst($cobro->estado) }}</span>
                        <h2 class="h4 fw-bold mb-1">{{ $cobro->vecino?->full_name }}</h2>
                        <div class="text-secondary">{{ $cobro->vecino?->codigo }} · {{ $cobro->vecino?->categoria?->nombre }}</div>
                    </div>
                    <div class="text-end">
                        <div class="text-secondary">Monto total</div>
                        <div class="metric-value">S/{{ number_format((float) $cobro->monto_recibido, 2) }}</div>
                    </div>
                </div>
            </section>

            <section class="panel table-panel mb-3">
                <h2 class="h5 fw-bold mb-3">Desglose del monto</h2>
                <div class="table-responsive">
                    <table class="table">
                        <tbody>
                            <tr><td>Cuota {{ str_pad($cobro->periodo_mes, 2, '0', STR_PAD_LEFT) }}/{{ $cobro->periodo_anio }}</td><td class="text-end">S/{{ number_format((float) $cobro->monto_cuota, 2) }}</td></tr>
                            <tr><td>Deuda anterior</td><td class="text-end">S/{{ number_format((float) $cobro->monto_deuda_anterior, 2) }}</td></tr>
                            <tr><td>Multas cobradas</td><td class="text-end">S/{{ number_format((float) $cobro->monto_multas, 2) }}</td></tr>
                            <tr><th>Total</th><th class="text-end fs-4 text-info">S/{{ number_format((float) $cobro->monto_total, 2) }}</th></tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="panel table-panel">
                <h2 class="h5 fw-bold mb-3">Pagos y multas vinculadas</h2>
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Tipo</th><th>Concepto</th><th>Monto</th></tr></thead>
                        <tbody>
                            @foreach ($pendientesCobrados as $pendiente)
                                <tr><td>Cuota pendiente</td><td>{{ str_pad($pendiente->periodo_mes, 2, '0', STR_PAD_LEFT) }}/{{ $pendiente->periodo_anio }}</td><td>S/{{ number_format((float) $pendiente->monto_pendiente, 2) }}</td></tr>
                            @endforeach
                            @foreach ($multasCobradas as $multa)
                                <tr><td>Multa</td><td>{{ $multa->multa?->nombre ?? 'Multa aplicada' }}</td><td>S/{{ number_format((float) $multa->monto_aplicado, 2) }}</td></tr>
                            @endforeach
                            @if ($pendientesCobrados->isEmpty() && $multasCobradas->isEmpty())
                                <tr><td colspan="3" class="text-center text-secondary">Sin deudas adicionales en este cobro.</td></tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </section>
        </div>

        <div class="col-lg-5">
            <section class="panel p-4 mb-3">
                <h2 class="h5 fw-bold mb-3">Datos del pago</h2>
                <dl class="row mb-0">
                    <dt class="col-5">Metodo</dt><dd class="col-7">{{ ucfirst($cobro->metodo_pago) }}</dd>
                    <dt class="col-5">Registrado por</dt><dd class="col-7">{{ $cobro->operador?->full_name ?? $cobro->operador?->username }}</dd>
                    <dt class="col-5">Observaciones</dt><dd class="col-7">{{ $cobro->observaciones ?: '-' }}</dd>
                    <dt class="col-5">Comprobante</dt><dd class="col-7">{{ $cobro->comprobante?->nombre_archivo ?? 'Pendiente' }}</dd>
                </dl>
            </section>

            @if ($cobro->estado === 'pagado')
                <section class="panel p-4 border-danger">
                    <h2 class="h5 fw-bold text-danger mb-3">Anular cobro</h2>
                    <div class="alert alert-danger border-0">La anulacion restaurara las deudas vinculadas para que puedan cobrarse nuevamente.</div>
                    <form method="POST" action="{{ route('admin.cobros.destroy', $cobro) }}" onsubmit="return confirm('Confirmar anulacion del cobro?')">
                        @csrf
                        @method('DELETE')
                        <label class="form-label fw-semibold">Motivo de anulacion</label>
                        <textarea class="form-control mb-3" name="motivo_anulacion" rows="3" required placeholder="Especifica la razon..."></textarea>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" name="devolver_dinero" value="1" id="devolver_dinero">
                            <label class="form-check-label" for="devolver_dinero">Se devolvio el dinero</label>
                        </div>
                        <button class="btn btn-danger">Confirmar anulacion</button>
                    </form>
                </section>
            @else
                <section class="panel p-4 form-card">
                    <h2 class="h5 fw-bold text-danger mb-3">Cobro anulado</h2>
                    <p class="mb-1"><strong>Motivo:</strong> {{ $cobro->motivo_anulacion }}</p>
                    <p class="mb-0"><strong>Fecha:</strong> {{ $cobro->fecha_anulacion?->format('d/m/Y H:i') }}</p>
                </section>
            @endif
        </div>
    </div>
@endsection
