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
        <a class="btn btn-outline-secondary" href="{{ route('admin.ingresos.show', $ingreso) }}">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.ingresos.update', $ingreso) }}" class="panel p-4" enctype="multipart/form-data" style="max-width:860px">
        @csrf
        @method('PUT')
        <div class="alert alert-warning border-0">Para mantener la integridad financiera, escribe el motivo de la edicion antes de guardar.</div>
        @include('admin.ingresos._form', ['editing' => true])
        <div class="d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary" href="{{ route('admin.ingresos.show', $ingreso) }}">Cancelar</a>
            <button class="btn btn-aqua px-4">Guardar cambios</button>
        </div>
    </form>
@endsection
