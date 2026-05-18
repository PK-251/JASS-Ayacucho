@extends('layouts.app')
@section('nav') @include('admin.partials.nav', ['active' => 'multas']) @endsection
@section('content')
<div class="topbar"><div><div class="page-subtitle">Multas y Tarifas</div><h1 class="page-title">Nueva multa</h1><div class="page-subtitle">Crea un tipo de multa configurable.</div></div><a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.multas.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a></div>
@if ($errors->any()) <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div> @endif
<form method="POST" action="{{ route('admin.multas.store') }}" class="panel p-4 form-card" style="max-width:760px">@csrf @include('admin.multas._multa-form')<div class="form-actions"><a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.multas.index') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a><button class="btn btn-aqua btn-icon px-4"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Crear multa</button></div></form>
@endsection
