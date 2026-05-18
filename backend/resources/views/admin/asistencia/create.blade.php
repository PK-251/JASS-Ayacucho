@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'asistencia'])
@endsection

@section('content')
<div class="topbar">
    <div>
        <div class="page-subtitle">Control de Asistencia</div>
        <h1 class="page-title">Nuevo evento</h1>
        <div class="page-subtitle">Programa asambleas, faenas o capacitaciones.</div>
    </div>
    <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.asistencia.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
</div>

@if ($errors->any())
    <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa los datos.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
@endif

<section class="panel p-4 form-card">
    <form method="POST" action="{{ route('admin.asistencia.store') }}" class="row g-3">
        @csrf
        <div class="col-md-6">
            <label class="form-label fw-semibold">Tipo de evento</label>
            <select class="form-select" name="tipo_evento_id" required>
                <option value="">Seleccione un tipo</option>
                @foreach ($tipos as $tipo)
                    <option value="{{ $tipo->id }}" @selected(old('tipo_evento_id') == $tipo->id)>{{ $tipo->nombre }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label fw-semibold">Multa por inasistencia</label>
            <select class="form-select" name="multa_id">
                <option value="">Sin multa</option>
                @foreach ($multas as $multa)
                    <option value="{{ $multa->id }}" @selected(old('multa_id') == $multa->id)>{{ $multa->codigo }} - {{ $multa->nombre }} (S/{{ number_format((float) $multa->monto, 2) }})</option>
                @endforeach
            </select>
        </div>
        <div class="col-md-8">
            <label class="form-label fw-semibold">Titulo</label>
            <input class="form-control" name="titulo" value="{{ old('titulo') }}" required placeholder="Ej. Asamblea Ordinaria de Mayo">
        </div>
        <div class="col-md-4">
            <label class="form-label fw-semibold">Lugar</label>
            <input class="form-control" name="lugar" value="{{ old('lugar') }}" required placeholder="Casa comunal">
        </div>
        <div class="col-md-4">
            <label class="form-label fw-semibold">Fecha</label>
            <input type="date" class="form-control" name="fecha_evento" value="{{ old('fecha_evento', '2026-05-15') }}" required>
        </div>
        <div class="col-md-4">
            <label class="form-label fw-semibold">Hora</label>
            <input type="time" class="form-control" name="hora_inicio" value="{{ old('hora_inicio', '19:00') }}" required>
        </div>
        <div class="col-md-4">
            <label class="form-label fw-semibold">Duracion</label>
            <select class="form-select" name="duracion_minutos">
                <option value="60">1 hora</option>
                <option value="120" selected>2 horas</option>
                <option value="180">3 horas</option>
                <option value="240">4 horas</option>
            </select>
        </div>
        <div class="col-12">
            <label class="form-label fw-semibold">Descripcion</label>
            <textarea class="form-control" name="descripcion" rows="4" placeholder="Agenda u objetivo del evento...">{{ old('descripcion') }}</textarea>
        </div>
        <div class="col-12">
            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" role="switch" name="es_obligatorio" value="1" id="obligatorio" checked>
                <label class="form-check-label fw-semibold" for="obligatorio">Asistencia obligatoria</label>
            </div>
            <div class="form-text">Si es obligatoria, al confirmar la lista se podran generar multas a los ausentes.</div>
        </div>
        <div class="col-12 d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.asistencia.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a>
            <button class="btn btn-aqua"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Crear evento</button>
        </div>
    </form>
</section>
@endsection
