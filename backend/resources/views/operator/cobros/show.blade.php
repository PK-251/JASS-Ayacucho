@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <div class="page-subtitle">Cobro registrado</div>
        <h1 class="page-title">Pago confirmado</h1>
        <div class="page-subtitle">{{ $cobro->numero_serie }} · {{ $cobro->fecha_cobro?->format('d/m/Y') }} {{ substr($cobro->hora_cobro, 0, 5) }}</div>
    </div>
    <a class="btn btn-outline-secondary btn-icon" href="{{ route('operator.cobros.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Continuar cobrando</a>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

<section class="panel p-5 mx-auto" style="max-width:540px; text-align:center">
    <div class="mx-auto mb-3" style="width:74px;height:74px;border-radius:999px;background:#dff9f2;color:#087b62;display:grid;place-items:center;font-size:2.2rem;font-weight:900">✓</div>
    <h2 class="fw-bold mb-2">Pago registrado correctamente</h2>
    <div class="metric-value mb-4">S/{{ number_format((float) $cobro->monto_recibido, 2) }}</div>
    <div class="panel p-3 mb-4" style="box-shadow:none;background:#effbff;text-align:left">
        <div class="d-flex justify-content-between py-2"><span>Usuario</span><strong>{{ $cobro->vecino?->full_name }}</strong></div>
        <div class="d-flex justify-content-between py-2"><span>N. Serie</span><strong>{{ $cobro->numero_serie }}</strong></div>
        <div class="d-flex justify-content-between py-2"><span>Metodo</span><strong>{{ ucfirst($cobro->metodo_pago) }}</strong></div>
    </div>
    <div class="d-grid gap-2">
        <a class="btn btn-aqua btn-icon" href="{{ route('operator.cobros.pdf', $cobro) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6"/></svg></span>Descargar comprobante PDF</a>
        <a class="btn btn-outline-info btn-icon" href="{{ route('operator.cobros.index') }}">Continuar con siguiente usuario</a>
    </div>
</section>
@endsection
