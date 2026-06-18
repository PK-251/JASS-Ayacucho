@extends('layouts.app')

@section('nav')
    @include('operator.partials.nav', ['active' => 'inicio'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <h1 class="page-title">Inicio</h1>
        <div class="page-subtitle">{{ ucfirst(now()->locale('es')->translatedFormat('l, j \\d\\e F Y')) }}</div>
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
    <div class="col-md-4">
        <x-metric-card label="Cobros realizados hoy" icon="receipt">{{ $cobrosHoy }}
            <x-slot:footer><span class="small">S/{{ number_format((float) $recaudadoHoy, 2) }} recaudados</span></x-slot:footer>
        </x-metric-card>
    </div>
    <div class="col-md-4">
        <x-metric-card label="Usuarios pendientes" icon="clock" tone="warning" valueClass="warning">{{ $pendientes }}
            <x-slot:footer><span class="small">Por cobrar en jornada actual</span></x-slot:footer>
        </x-metric-card>
    </div>
    <div class="col-md-4">
        <x-metric-card label="Proximo evento" icon="calendar" valueClass="fs-4">{{ $proximoEvento?->titulo ?? 'Sin evento' }}
            <x-slot:footer><span class="small">{{ $proximoEvento?->fecha_evento?->format('d/m/Y') }}</span></x-slot:footer>
        </x-metric-card>
    </div>
</div>

<section class="panel p-4 mb-4">
    <h2 class="h5 fw-bold mb-3">Que quieres hacer?</h2>
    <div class="d-flex flex-wrap gap-3 quick-actions">
        @if ($jornada)
            <a class="btn btn-aqua btn-icon btn-lg px-4" href="{{ route('operator.cobros.index') }}"><svg viewBox="0 0 24 24"><path d="M19 7V5a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5"/><path d="M16 13h.01"/></svg>Continuar cobrando</a>
            <form method="POST" action="{{ route('operator.cobros.cerrar') }}" class="d-inline">
                @csrf
                <button class="btn btn-outline-info btn-icon btn-lg px-4"><svg viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>Cerrar jornada</button>
            </form>
        @else
            <form method="POST" action="{{ route('operator.cobros.iniciar') }}" class="d-inline">
                @csrf
                <button class="btn btn-aqua btn-icon btn-lg px-4"><svg viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="M12 14v4"/><path d="M10 16h4"/></svg>Iniciar jornada de cobro</button>
            </form>
        @endif
        <a class="btn btn-outline-info btn-icon btn-lg px-4" href="{{ route('operator.asistencia.index') }}"><svg viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg>Pasar lista de asistencia</a>
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
