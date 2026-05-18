@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'ingresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Ingresos</div>
            <h1 class="page-title">Editar ingreso manual</h1>
            <div class="page-subtitle">{{ $ingreso->numero_serie }} · Toda edicion queda auditada.</div>
        </div>
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.ingresos.show', $ingreso) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.ingresos.update', $ingreso) }}" class="panel p-4 form-card" enctype="multipart/form-data" style="max-width:860px">
        @csrf
        @method('PUT')
        <div class="alert alert-warning border-0">Para mantener la integridad financiera, escribe el motivo de la edicion antes de guardar.</div>
        @include('admin.ingresos._form', ['editing' => true])
        <div class="form-actions">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.ingresos.show', $ingreso) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a>
            <button class="btn btn-aqua btn-icon px-4"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2Z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/></svg></span>Guardar cambios</button>
        </div>
    </form>
@endsection
