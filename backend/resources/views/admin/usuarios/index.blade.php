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
        <div class="page-actions">
            <a class="btn btn-outline-info btn-icon" href="#"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></svg></span>Exportar</a>
            <a class="btn btn-aqua btn-icon px-4" href="{{ route('admin.usuarios.create') }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span>Nuevo Usuario</a>
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-xl-3 col-md-6"><x-metric-card label="Total usuarios" icon="users" badge="Registrados">{{ $totalUsuarios }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Al dia" icon="user-check" tone="success" valueClass="success" :badge="($totalUsuarios ? round($activos * 100 / $totalUsuarios, 1) : 0) . '% del total'">{{ $activos }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Suspendidos" icon="ban" tone="warning" valueClass="danger" badge="Revisar" badgeClass="badge-warning-soft">{{ $suspendidos }}</x-metric-card></div>
        <div class="col-xl-3 col-md-6"><x-metric-card label="Cortados" icon="user-x" tone="danger" valueClass="danger" badge="Requieren atencion" badgeClass="badge-danger-soft">{{ $cortados }}</x-metric-card></div>
    </div>

    <section class="panel table-panel">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <h2 class="h5 fw-bold mb-0">Usuarios registrados</h2>
            <form method="GET" action="{{ route('admin.usuarios.index') }}" class="page-actions">
                <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar por DNI o nombre...">
                <button class="btn btn-outline-info btn-icon"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m21 21-4.3-4.3"/><circle cx="11" cy="11" r="7"/></svg></span>Buscar</button>
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
                            <div class="page-actions">
                                <a class="btn btn-sm btn-outline-info btn-icon" href="{{ route('admin.usuarios.show', $usuario) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg></span>Ver</a>
                                <a class="btn btn-sm btn-outline-secondary btn-icon" href="{{ route('admin.usuarios.edit', $usuario) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="m16.5 3.5 4 4L8 20H4v-4L16.5 3.5Z"/></svg></span>Editar</a>
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
