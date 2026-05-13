@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'egresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Egresos</div>
            <h1 class="page-title">Editar egreso</h1>
            <div class="page-subtitle">{{ $egreso->numero_serie }} · Toda edicion queda auditada.</div>
        </div>
        <a class="btn btn-outline-secondary" href="{{ route('admin.egresos.show', $egreso) }}">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.egresos.update', $egreso) }}" class="panel p-4" enctype="multipart/form-data" style="max-width:900px">
        @csrf
        @method('PUT')
        <div class="alert alert-warning border-0">Si el nuevo monto supera S/{{ number_format((float) $umbral, 2) }}, el egreso volvera a quedar pendiente de aprobacion.</div>
        @include('admin.egresos._form')
        <div class="d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary" href="{{ route('admin.egresos.show', $egreso) }}">Cancelar</a>
            <button class="btn btn-aqua px-4">Guardar cambios</button>
        </div>
    </form>
@endsection
