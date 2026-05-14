@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'inicio'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <h1 class="page-title">Inicio</h1>
        <div class="page-subtitle">Miercoles, 13 de Mayo 2026</div>
    </div>
    <span class="status-pill">{{ $jornada ? 'Jornada activa' : 'En linea' }}</span>
</div>

@if (session('success'))
    <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
@endif

<section class="panel p-4 mb-4" style="background:linear-gradient(120deg,#ffffff 0%,#e7fbff 100%);">
    <h2 class="h3 fw-bold mb-1">Buenos dias, {{ auth()->user()->nombres }}!</h2>
    <p class="mb-0 text-secondary">Hoy tienes {{ $pendientes }} usuarios por cobrar{{ $jornada ? ' y la jornada esta activa.' : '.' }}</p>
</section>

<div class="row g-3 mb-4">
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Cobros realizados hoy</div><div class="metric-value">{{ $cobrosHoy }}</div><span class="small">S/{{ number_format((float) $recaudadoHoy, 2) }} recaudados</span></div></div>
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Usuarios pendientes</div><div class="metric-value" style="color:#f59e0b">{{ $pendientes }}</div><span class="small">Por cobrar en jornada actual</span></div></div>
    <div class="col-md-4"><div class="metric-card"><div class="metric-label">Proximo evento</div><div class="metric-value fs-4">{{ $proximoEvento?->titulo ?? 'Sin evento' }}</div><span class="small">{{ $proximoEvento?->fecha_evento?->format('d/m/Y') }}</span></div></div>
</div>

<section class="panel p-4 mb-4">
    <h2 class="h5 fw-bold mb-3">Que quieres hacer?</h2>
    <div class="d-flex flex-wrap gap-3 quick-actions">
        @if ($jornada)
            <a class="btn btn-aqua btn-lg px-4" href="{{ route('operator.cobros.index') }}">Continuar cobrando</a>
            <form method="POST" action="{{ route('operator.cobros.cerrar') }}" class="d-inline">
                @csrf
                <button class="btn btn-outline-info btn-lg px-4">Cerrar jornada</button>
            </form>
        @else
            <form method="POST" action="{{ route('operator.cobros.iniciar') }}" class="d-inline">
                @csrf
                <button class="btn btn-aqua btn-lg px-4">Iniciar jornada de cobro</button>
            </form>
        @endif
        <a class="btn btn-outline-info btn-lg px-4" href="{{ route('operator.asistencia.index') }}">Pasar lista de asistencia</a>
    </div>
</section>

<div class="row g-3">
    <div class="col-lg-6">
        <section class="panel p-4 h-100">
            <h2 class="h5 fw-bold mb-3">Mi actividad reciente</h2>
            <p class="text-secondary mb-0">Tus cobros registrados apareceran en el modulo Cobros.</p>
        </section>
    </div>
    <div class="col-lg-6">
        <section class="panel p-4 h-100">
            <h2 class="h5 fw-bold mb-3">Proximos eventos y faenas</h2>
            <p class="fw-semibold mb-1">{{ $proximoEvento?->titulo ?? 'Sin eventos pendientes' }}</p>
            <p class="text-secondary mb-0">{{ $proximoEvento?->lugar }}</p>
        </section>
    </div>
</div>
@endsection
