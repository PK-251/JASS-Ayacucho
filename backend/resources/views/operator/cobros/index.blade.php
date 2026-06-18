@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <h1 class="page-title">Cobros</h1>
        <div class="page-subtitle">Jornada de recaudacion del operador.</div>
    </div>
    <span class="status-pill">{{ $jornada ? 'Jornada activa' : 'Sin jornada' }}</span>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif
@if ($errors->any())
    <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el cobro.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
@endif

@if (! $jornada)
    <section class="panel p-4 mb-4" style="border-color:#f59e0b; background:#fff8dd">
        <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap">
            <div><strong>Primero inicia tu jornada de cobro.</strong><div class="text-secondary">Asi todos los pagos quedan agrupados para el cierre del dia.</div></div>
            <form method="POST" action="{{ route('operator.cobros.iniciar') }}">@csrf<button class="btn btn-aqua btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg></span>Iniciar jornada</button></form>
        </div>
    </section>
@endif

<div class="row g-3 mb-4">
    <div class="col-md-4"><x-metric-card label="Cobrados hoy" icon="receipt">{{ $stats['cobrados'] }}</x-metric-card></div>
    <div class="col-md-4"><x-metric-card label="Recaudado" icon="wallet">S/{{ number_format((float) $stats['recaudado'], 2) }}</x-metric-card></div>
    <div class="col-md-4"><x-metric-card label="Pendientes" icon="clock" tone="warning" valueClass="warning">{{ $stats['pendientes'] }}</x-metric-card></div>
</div>

<div class="row g-3">
    <div class="col-lg-5">
        <section class="panel p-3 h-100">
            <form class="mb-3" method="GET" action="{{ route('operator.cobros.index') }}">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar usuario, codigo o DNI...">
            </form>
            <div class="d-grid gap-2">
                @foreach ($usuarios as $item)
                    <a class="panel p-3 text-decoration-none {{ $usuario && $usuario->id === $item->id ? 'border-info' : '' }}" style="box-shadow:none" href="{{ route('operator.cobros.index', ['usuario_id' => $item->id, 'buscar' => $buscar]) }}">
                        <div class="d-flex justify-content-between align-items-center">
                            <div><strong>{{ $item->full_name }}</strong><div class="text-secondary small">{{ $item->codigo }} · {{ $item->direccion }}</div></div>
                        </div>
                    </a>
                @endforeach
            </div>
        </section>
    </div>
    <div class="col-lg-7">
        @if ($usuario && $desglose)
            <section class="panel p-4 mb-3">
                <div class="d-flex justify-content-between align-items-start gap-3 flex-wrap">
                    <div>
                        <h2 class="h3 fw-bold mb-1">{{ $usuario->full_name }}</h2>
                        <div class="text-secondary">{{ $usuario->codigo }} · {{ $usuario->direccion }}</div>
                    </div>
                    <span class="badge {{ $usuario->estado === 'activo' ? 'badge-soft' : 'badge-danger-soft' }}">{{ ucfirst($usuario->estado) }}</span>
                </div>
            </section>

            <section class="panel table-panel mb-3">
                <h2 class="h5 fw-bold mb-3">Detalle de cobro</h2>
                <table class="table">
                    <tbody>
                        <tr><td>Cuota {{ ucfirst(now()->locale('es')->translatedFormat('F')) }} {{ now()->year }}</td><td class="text-end">S/{{ number_format((float) $desglose['cuota'], 2) }}</td></tr>
                        <tr><td>Deuda anterior</td><td class="text-end text-danger">S/{{ number_format((float) $desglose['deuda_cuotas'], 2) }}</td></tr>
                        <tr><td>Multas pendientes</td><td class="text-end text-danger">S/{{ number_format((float) $desglose['deuda_multas'], 2) }}</td></tr>
                        <tr><th>Total a cobrar</th><th class="text-end fs-3 text-info">S/{{ number_format((float) $desglose['total'], 2) }}</th></tr>
                    </tbody>
                </table>
            </section>

            <section class="panel p-4">
                <form method="POST" action="{{ route('operator.cobros.store') }}" class="row g-3 mb-3">
                    @csrf
                    <input type="hidden" name="vecino_id" value="{{ $usuario->id }}">
                    <div class="col-md-6"><label class="form-label fw-semibold">Monto recibido</label><input class="form-control" type="number" min="0" step="0.01" name="monto_recibido" value="{{ old('monto_recibido', number_format((float) $desglose['total'], 2, '.', '')) }}"></div>
                    <div class="col-md-6"><label class="form-label fw-semibold">Metodo</label><select class="form-select" name="metodo_pago"><option value="efectivo">Efectivo</option><option value="yape">Yape</option><option value="plin">Plin</option><option value="transferencia">Transferencia</option><option value="otro">Otro</option></select></div>
                    <div class="col-12"><label class="form-label fw-semibold">Observaciones</label><input class="form-control" name="observaciones" placeholder="Opcional"></div>
                    <div class="col-12 d-flex justify-content-end">
                        <button class="btn btn-aqua btn-icon btn-lg" @disabled(! $jornada)><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m20 6-11 11-5-5"/></svg></span>Confirmar pago</button>
                    </div>
                </form>
                <form method="POST" action="{{ route('operator.cobros.pendiente', $usuario) }}" class="d-flex justify-content-end">
                    @csrf
                    <input type="hidden" name="motivo" value="No se encontro al usuario en la jornada">
                    <button class="btn btn-outline-warning btn-icon btn-lg" @disabled(! $jornada)><span class="action-icon-sm"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg></span>Marcar pendiente</button>
                </form>
            </section>
        @else
            <section class="panel p-4"><p class="mb-0 text-secondary">Selecciona un usuario para registrar el pago.</p></section>
        @endif
    </div>
</div>
@endsection
