@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'ingresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Ingreso manual</div>
            <h1 class="page-title">{{ $ingreso->numero_serie }}</h1>
            <div class="page-subtitle">{{ $ingreso->fecha_ingreso?->format('d/m/Y') }} · {{ $ingreso->categoria?->nombre }}</div>
        </div>
        <div class="page-actions">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.ingresos.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
            @if ($ingreso->estado === 'activo')
                <a class="btn btn-aqua btn-icon" href="{{ route('admin.ingresos.edit', $ingreso) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="m16.5 3.5 4 4L8 20H4v-4L16.5 3.5Z"/></svg></span>Editar</a>
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
                        <span class="badge {{ $ingreso->estado === 'activo' ? 'badge-soft' : 'badge-danger-soft' }} mb-3">{{ ucfirst($ingreso->estado) }}</span>
                        <h2 class="h4 fw-bold mb-1">{{ $ingreso->concepto }}</h2>
                        <div class="text-secondary">{{ $ingreso->vecino?->full_name ?? 'Sin usuario relacionado' }}</div>
                    </div>
                    <div class="text-end">
                        <div class="text-secondary">Monto total</div>
                        <div class="metric-value">S/{{ number_format((float) $ingreso->monto, 2) }}</div>
                    </div>
                </div>
            </section>

            <section class="panel p-4 mb-3">
                <h2 class="h5 fw-bold mb-3">Informacion general</h2>
                <dl class="row mb-0">
                    <dt class="col-sm-4">Categoria</dt><dd class="col-sm-8">{{ $ingreso->categoria?->nombre }}</dd>
                    <dt class="col-sm-4">Metodo</dt><dd class="col-sm-8">{{ ucfirst($ingreso->metodo_pago) }}</dd>
                    <dt class="col-sm-4">Fecha</dt><dd class="col-sm-8">{{ $ingreso->fecha_ingreso?->format('d/m/Y') }}</dd>
                    <dt class="col-sm-4">Descripcion</dt><dd class="col-sm-8">{{ $ingreso->descripcion ?: '-' }}</dd>
                    <dt class="col-sm-4">Observaciones</dt><dd class="col-sm-8">{{ $ingreso->observaciones ?: '-' }}</dd>
                </dl>
            </section>

            <section class="panel p-4 form-card">
                <h2 class="h5 fw-bold mb-3">Comprobante</h2>
                @if ($ingreso->comprobante_nombre)
                    <div class="d-flex justify-content-between align-items-center panel p-3" style="box-shadow:none">
                        <div>
                            <div class="fw-bold">{{ $ingreso->comprobante_nombre }}</div>
                            <div class="text-secondary small">Archivo de respaldo</div>
                        </div>
                        <span class="badge badge-soft">Adjunto</span>
                    </div>
                @else
                    <div class="text-secondary">Sin comprobante adjunto.</div>
                @endif
            </section>
        </div>

        <div class="col-lg-5">
            @if ($ingreso->estado === 'activo')
                <section class="panel p-4 border-danger">
                    <h2 class="h5 fw-bold text-danger mb-3">Anular ingreso manual</h2>
                    <div class="alert alert-danger border-0">La anulacion quedara registrada en auditoria y este monto ya no contara como ingreso activo.</div>
                    <form method="POST" action="{{ route('admin.ingresos.destroy', $ingreso) }}" onsubmit="return confirm('Confirmar anulacion del ingreso?')">
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
                    <h2 class="h5 fw-bold text-danger mb-3">Ingreso anulado</h2>
                    <p class="mb-1"><strong>Motivo:</strong> {{ $ingreso->motivo_anulacion }}</p>
                    <p class="mb-0"><strong>Fecha:</strong> {{ $ingreso->fecha_anulacion?->format('d/m/Y H:i') }}</p>
                </section>
            @endif
        </div>
    </div>
@endsection
