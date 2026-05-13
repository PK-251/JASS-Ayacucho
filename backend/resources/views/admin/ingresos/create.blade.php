@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'ingresos'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Ingresos</div>
            <h1 class="page-title">Registrar ingreso manual</h1>
            <div class="page-subtitle">Para donaciones, cuotas extraordinarias, ventas, reintegros u otros ingresos no provenientes de cobros.</div>
        </div>
        <a class="btn btn-outline-secondary" href="{{ route('admin.ingresos.index') }}">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.ingresos.store') }}" class="panel p-4" enctype="multipart/form-data" style="max-width:860px">
        @csrf
        <div class="alert alert-info border-0">Para cobrar cuotas mensuales, usa el modulo Cobros. Este formulario es solo para ingresos manuales.</div>
        @include('admin.ingresos._form', ['ingreso' => new \App\Models\Ingreso(), 'editing' => false])
        <div class="d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary" href="{{ route('admin.ingresos.index') }}">Cancelar</a>
            <button class="btn btn-aqua px-4">Registrar ingreso</button>
        </div>
    </form>
@endsection
