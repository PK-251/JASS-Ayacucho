@extends('layouts.app')
@section('nav') @include('admin.partials.nav', ['active' => 'multas']) @endsection
@section('content')
<div class="topbar"><div><div class="page-subtitle">Multas y Tarifas</div><h1 class="page-title">Editar multa</h1><div class="page-subtitle">{{ $multa->codigo }} · {{ $multa->nombre }}</div></div><a class="btn btn-outline-secondary" href="{{ route('admin.multas.index') }}">Volver</a></div>
@if ($errors->any()) <div class="alert alert-danger border-0 shadow-sm"><strong>Revisa el formulario.</strong><ul class="mb-0 mt-2">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div> @endif
<form method="POST" action="{{ route('admin.multas.update', $multa) }}" class="panel p-4" style="max-width:760px">@csrf @method('PUT') @include('admin.multas._multa-form')<div class="d-flex justify-content-end gap-2 mt-4"><a class="btn btn-outline-secondary" href="{{ route('admin.multas.index') }}">Cancelar</a><button class="btn btn-aqua px-4">Guardar cambios</button></div></form>
@endsection
