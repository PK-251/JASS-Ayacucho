@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'multas'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Multas y Tarifas</div>
            <h1 class="page-title">Modificar cuota base</h1>
            <div class="page-subtitle">Registra una nueva tarifa vigente por categoria.</div>
        </div>
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.multas.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.tarifas.store') }}" class="panel p-4 form-card" style="max-width:760px">
        @csrf
        <div class="alert alert-warning border-0">Este cambio afectara los cobros futuros de la categoria seleccionada.</div>
        <div class="row g-3">
            <div class="col-md-6">
                <label class="form-label fw-semibold">Categoria</label>
                <select class="form-select" name="categoria_id" required>
                    <option value="">Selecciona una categoria</option>
                    @foreach ($categorias as $categoria)
                        <option value="{{ $categoria->id }}" @selected(old('categoria_id') == $categoria->id)>{{ $categoria->nombre }} · Actual S/{{ number_format((float) ($vigentes[$categoria->id] ?? 0), 2) }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label fw-semibold">Nuevo valor (S/)</label>
                <input class="form-control" type="number" min="0.01" step="0.01" name="monto" value="{{ old('monto') }}" placeholder="0.00" required>
            </div>
            <div class="col-md-6">
                <label class="form-label fw-semibold">Fecha de vigencia</label>
                <input class="form-control" type="date" name="fecha_vigencia_inicio" value="{{ old('fecha_vigencia_inicio', now()->format('Y-m-d')) }}" required>
            </div>
            <div class="col-12">
                <label class="form-label fw-semibold">Motivo del cambio</label>
                <textarea class="form-control" name="motivo_cambio" rows="3" required>{{ old('motivo_cambio') }}</textarea>
            </div>
            <div class="col-12">
                <label class="form-label fw-semibold">Descripcion</label>
                <textarea class="form-control" name="descripcion" rows="2">{{ old('descripcion') }}</textarea>
            </div>
        </div>
        <div class="form-actions"><a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.multas.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a><button class="btn btn-aqua btn-icon px-4">Aplicar cambio</button></div>
    </form>
@endsection
