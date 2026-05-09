@extends('layouts.app')

@section('nav')
    <div class="nav-section">OPERADOR</div>
    <a class="nav-link-app active" href="{{ route('operator.dashboard') }}">
        <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="m3 10 9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/></svg></span>
        Inicio
    </a>
    <a class="nav-link-app" href="#">
        <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M19 7V5a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5"/><path d="M16 13h.01"/></svg></span>
        Cobros
    </a>
    <a class="nav-link-app" href="#">
        <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg></span>
        Asistencia
    </a>
@endsection

@section('content')
    <div class="panel p-4 mb-4">
        <h1 class="h3 fw-bold">Buenos dias, {{ auth()->user()->nombres }}</h1>
        <p class="mb-0 text-secondary">Hoy tienes {{ $pendientes }} usuarios por cobrar{{ $jornada ? ' y la jornada esta activa.' : '.' }}</p>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-4"><div class="metric-card"><div class="text-secondary">Cobros realizados hoy</div><div class="metric-value">{{ $cobrosHoy }}</div><span class="small">S/{{ number_format((float) $recaudadoHoy, 2) }} recaudados</span></div></div>
        <div class="col-md-4"><div class="metric-card"><div class="text-secondary">Usuarios pendientes</div><div class="metric-value">{{ $pendientes }}</div><span class="small">Por cobrar en jornada actual</span></div></div>
        <div class="col-md-4"><div class="metric-card"><div class="text-secondary">Proximo evento</div><div class="metric-value fs-4">{{ $proximoEvento?->titulo ?? 'Sin evento' }}</div><span class="small">{{ $proximoEvento?->fecha_evento?->format('d/m/Y') }}</span></div></div>
    </div>

    <section class="panel p-4">
        <h2 class="h5 fw-bold mb-3">Que quieres hacer?</h2>
        <button class="btn btn-aqua btn-lg me-2">Iniciar jornada de cobro</button>
        <button class="btn btn-outline-info btn-lg">Pasar lista de asistencia</button>
    </section>
@endsection
