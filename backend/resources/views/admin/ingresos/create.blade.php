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
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.ingresos.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
    @endif

    <form method="POST" action="{{ route('admin.ingresos.store') }}" class="panel p-4 form-card" enctype="multipart/form-data" style="max-width:860px">
        @csrf
        <div class="alert alert-info border-0">Para cobrar cuotas mensuales, usa el modulo Cobros. Este formulario es solo para ingresos manuales.</div>
        @include('admin.ingresos._form', ['ingreso' => new \App\Models\Ingreso(), 'editing' => false])
        <div class="form-actions">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.ingresos.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a>
            <button class="btn btn-aqua btn-icon px-4"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Registrar ingreso</button>
        </div>
    </form>
@endsection
