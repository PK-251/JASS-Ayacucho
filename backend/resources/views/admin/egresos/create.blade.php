@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'egresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Egresos</div>
            <h1 class="page-title">Registrar nuevo egreso</h1>
            <div class="page-subtitle">Los gastos mayores al umbral pasan por aprobacion.</div>
        </div>
        <a class="btn btn-outline-secondary" href="{{ route('admin.egresos.index') }}">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.egresos.store') }}" class="panel p-4" enctype="multipart/form-data" style="max-width:900px">
        @csrf
        <div class="alert alert-info border-0">Umbral de aprobacion actual: <strong>S/{{ number_format((float) $umbral, 2) }}</strong>.</div>
        @include('admin.egresos._form')
        <div class="d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary" href="{{ route('admin.egresos.index') }}">Cancelar</a>
            <button class="btn btn-aqua px-4">Registrar egreso</button>
        </div>
    </form>
@endsection
