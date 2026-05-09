@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'usuarios'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Gestion</div>
            <h1 class="page-title">Padron de Usuarios</h1>
            <div class="page-subtitle">Gestion y registro de usuarios del sistema de agua.</div>
        </div>
        <div class="d-flex gap-2">
            <a class="btn btn-outline-info" href="#">Exportar</a>
            <a class="btn btn-aqua px-4" href="{{ route('admin.usuarios.create') }}">Nuevo Usuario</a>
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Total usuarios</div><div class="metric-value">{{ $totalUsuarios }}</div><span class="badge badge-soft mt-2">Registrados</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Al dia</div><div class="metric-value success">{{ $activos }}</div><span class="badge badge-soft mt-2">{{ $totalUsuarios ? round($activos * 100 / $totalUsuarios, 1) : 0 }}% del total</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Suspendidos</div><div class="metric-value danger">{{ $suspendidos }}</div><span class="badge badge-warning-soft mt-2">Revisar</span></div></div>
        <div class="col-xl-3 col-md-6"><div class="metric-card"><div class="metric-label">Cortados</div><div class="metric-value danger">{{ $cortados }}</div><span class="badge badge-danger-soft mt-2">Requieren atencion</span></div></div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <h2 class="h5 fw-bold mb-0">Usuarios registrados</h2>
            <form method="GET" action="{{ route('admin.usuarios.index') }}" class="d-flex gap-2">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar por DNI o nombre...">
                <button class="btn btn-outline-info">Buscar</button>
            </form>
        </div>

        <div class="table-responsive">
            <table class="table align-middle">
                <thead>
                    <tr>
                        <th>Codigo</th>
                        <th>Documento</th>
                        <th>Nombre</th>
                        <th>Direccion</th>
                        <th>Categoria</th>
                        <th>Estado</th>
                        <th>Deuda</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                @forelse ($usuarios as $usuario)
                    @php($deuda = (float) ($usuario->deuda_cuotas ?? 0) + (float) ($usuario->deuda_multas ?? 0))
                    <tr>
                        <td><a class="series-link" href="{{ route('admin.usuarios.show', $usuario) }}">{{ $usuario->codigo }}</a></td>
                        <td>{{ $usuario->documento_tipo }} {{ $usuario->documento_num }}</td>
                        <td class="fw-semibold">{{ $usuario->full_name }}</td>
                        <td>{{ $usuario->direccion }}</td>
                        <td>{{ $usuario->categoria?->nombre }}</td>
                        <td>
                            <span class="badge {{ $usuario->estado === 'activo' ? 'badge-soft' : ($usuario->estado === 'suspendido' ? 'badge-warning-soft' : 'badge-danger-soft') }}">
                                {{ ucfirst($usuario->estado) }}
                            </span>
                        </td>
                        <td class="{{ $deuda > 0 ? 'text-danger fw-bold' : 'text-secondary' }}">S/{{ number_format($deuda, 2) }}</td>
                        <td>
                            <div class="d-flex gap-2">
                                <a class="btn btn-sm btn-outline-info" href="{{ route('admin.usuarios.show', $usuario) }}">Ver</a>
                                <a class="btn btn-sm btn-outline-secondary" href="{{ route('admin.usuarios.edit', $usuario) }}">Editar</a>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="text-center text-secondary py-4">No se encontraron usuarios.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-3">
            <div class="text-secondary small">Mostrando {{ $usuarios->firstItem() }} a {{ $usuarios->lastItem() }} de {{ $usuarios->total() }} registros</div>
            {{ $usuarios->links() }}
        </div>
    </section>
@endsection
