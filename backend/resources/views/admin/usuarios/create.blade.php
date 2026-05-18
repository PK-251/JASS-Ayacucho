@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'usuarios'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Padron de Usuarios</div>
            <h1 class="page-title">Nuevo Usuario</h1>
            <div class="page-subtitle">Registra un usuario del servicio de agua.</div>
        </div>
    </div>

    <form method="POST" action="{{ route('admin.usuarios.store') }}" class="panel p-4 form-card">
        @csrf
        @include('admin.usuarios._form', ['buttonText' => 'Guardar Usuario'])
    </form>
@endsection
