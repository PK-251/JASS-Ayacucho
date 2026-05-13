@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'egresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Detalle de egreso</div>
            <h1 class="page-title">{{ $egreso->numero_serie }}</h1>
            <div class="page-subtitle">{{ $egreso->fecha_egreso?->format('d/m/Y') }} · {{ $egreso->categoria?->nombre }}</div>
        </div>
        <div class="d-flex gap-2">
            <a class="btn btn-outline-secondary" href="{{ route('admin.egresos.index') }}">Volver</a>
            @if (in_array($egreso->estado, ['aprobado', 'pendiente_aprobacion']))
                <a class="btn btn-aqua" href="{{ route('admin.egresos.edit', $egreso) }}">Editar</a>
            @endif
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif
    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <div class="row g-3">
        <div class="col-lg-7">
            <section class="panel p-4 mb-3">
                <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                        <span class="badge {{ $egreso->estado === 'aprobado' ? 'badge-soft' : ($egreso->estado === 'pendiente_aprobacion' ? 'badge-warning-soft' : 'badge-danger-soft') }} mb-3">{{ str_replace('_', ' ', ucfirst($egreso->estado)) }}</span>
                        <h2 class="h4 fw-bold mb-1">{{ $egreso->concepto }}</h2>
                        <div class="text-secondary">{{ $egreso->proveedor?->nombre ?? 'Sin proveedor' }}</div>
                    </div>
                    <div class="text-end">
                        <div class="text-secondary">Monto</div>
                        <div class="metric-value danger">S/{{ number_format((float) $egreso->monto, 2) }}</div>
                    </div>
                </div>
            </section>

            <section class="panel p-4 mb-3">
                <h2 class="h5 fw-bold mb-3">Informacion general</h2>
                <dl class="row mb-0">
                    <dt class="col-sm-4">Categoria</dt><dd class="col-sm-8">{{ $egreso->categoria?->nombre }}</dd>
                    <dt class="col-sm-4">Metodo</dt><dd class="col-sm-8">{{ ucfirst($egreso->metodo_pago) }}</dd>
                    <dt class="col-sm-4">Comprobante</dt><dd class="col-sm-8">{{ ucfirst(str_replace('_', ' ', $egreso->comprobante_tipo)) }} {{ $egreso->comprobante_numero ? '· '.$egreso->comprobante_numero : '' }}</dd>
                    <dt class="col-sm-4">Descripcion</dt><dd class="col-sm-8">{{ $egreso->descripcion ?: '-' }}</dd>
                    <dt class="col-sm-4">Observaciones</dt><dd class="col-sm-8">{{ $egreso->observaciones ?: '-' }}</dd>
                </dl>
            </section>

            <section class="panel p-4">
                <h2 class="h5 fw-bold mb-3">Proveedor y respaldo</h2>
                <dl class="row mb-0">
                    <dt class="col-sm-4">Proveedor</dt><dd class="col-sm-8">{{ $egreso->proveedor?->nombre ?? 'Sin proveedor' }}</dd>
                    <dt class="col-sm-4">RUC/DNI</dt><dd class="col-sm-8">{{ $egreso->proveedor?->ruc ?? $egreso->proveedor?->dni ?? '-' }}</dd>
                    <dt class="col-sm-4">Archivo</dt><dd class="col-sm-8">{{ $egreso->comprobante_nombre ?: 'Sin archivo adjunto' }}</dd>
                </dl>
            </section>
        </div>

        <div class="col-lg-5">
            @if ($egreso->estado === 'pendiente_aprobacion')
                <section class="panel p-4 mb-3 border-warning">
                    <h2 class="h5 fw-bold mb-3">Pendiente de aprobacion</h2>
                    <div class="alert alert-warning border-0">Este egreso supera el umbral de S/{{ number_format((float) $umbral, 2) }} o requiere revision manual.</div>
                    <form method="POST" action="{{ route('admin.egresos.approve', $egreso) }}" class="mb-3">
                        @csrf
                        <button class="btn btn-success w-100">Aprobar egreso</button>
                    </form>
                    <form method="POST" action="{{ route('admin.egresos.reject', $egreso) }}">
                        @csrf
                        <label class="form-label fw-semibold">Motivo de rechazo</label>
                        <textarea class="form-control mb-3" name="motivo_rechazo" rows="3" required></textarea>
                        <button class="btn btn-outline-danger w-100">Rechazar egreso</button>
                    </form>
                </section>
            @endif

            @if (in_array($egreso->estado, ['aprobado', 'pendiente_aprobacion']))
                <section class="panel p-4 border-danger">
                    <h2 class="h5 fw-bold text-danger mb-3">Anular egreso</h2>
                    <div class="alert alert-danger border-0">La anulacion recalcula reportes y queda en auditoria.</div>
                    <form method="POST" action="{{ route('admin.egresos.destroy', $egreso) }}" onsubmit="return confirm('Confirmar anulacion del egreso?')">
                        @csrf
                        @method('DELETE')
                        <label class="form-label fw-semibold">Motivo de anulacion</label>
                        <textarea class="form-control mb-3" name="motivo_anulacion" rows="3" required></textarea>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" name="devolver_dinero" value="1" id="devolver_dinero">
                            <label class="form-check-label" for="devolver_dinero">Se recupero/devolvio el dinero</label>
                        </div>
                        <button class="btn btn-danger w-100">Confirmar anulacion</button>
                    </form>
                </section>
            @elseif ($egreso->estado === 'rechazado')
                <section class="panel p-4">
                    <h2 class="h5 fw-bold text-danger mb-3">Egreso rechazado</h2>
                    <p class="mb-1"><strong>Motivo:</strong> {{ $egreso->motivo_rechazo }}</p>
                    <p class="mb-0"><strong>Fecha:</strong> {{ $egreso->fecha_rechazo?->format('d/m/Y H:i') }}</p>
                </section>
            @else
                <section class="panel p-4">
                    <h2 class="h5 fw-bold text-danger mb-3">Egreso anulado</h2>
                    <p class="mb-1"><strong>Motivo:</strong> {{ $egreso->motivo_anulacion }}</p>
                    <p class="mb-0"><strong>Fecha:</strong> {{ $egreso->fecha_anulacion?->format('d/m/Y H:i') }}</p>
                </section>
            @endif
        </div>
    </div>
@endsection
