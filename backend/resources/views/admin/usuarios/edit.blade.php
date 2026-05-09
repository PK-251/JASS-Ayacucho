@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'usuarios'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">{{ $usuario->codigo }}</div>
            <h1 class="page-title">Editar Usuario</h1>
            <div class="page-subtitle">Modifica los datos del registro actual.</div>
        </div>
    </div>

    <form method="POST" action="{{ route('admin.usuarios.update', $usuario) }}" class="panel p-4">
        @csrf
        @method('PUT')
        @include('admin.usuarios._form', ['buttonText' => 'Guardar Cambios'])
    </form>
@endsection
