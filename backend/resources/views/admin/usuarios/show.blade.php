@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'usuarios'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">{{ $usuario->codigo }}</div>
            <h1 class="page-title">{{ $usuario->full_name }}</h1>
            <div class="page-subtitle">Detalle del usuario del padron.</div>
        </div>
        <div class="d-flex gap-2">
            <a class="btn btn-outline-secondary" href="{{ route('admin.usuarios.index') }}">Volver</a>
            <a class="btn btn-aqua" href="{{ route('admin.usuarios.edit', $usuario) }}">Editar</a>
        </div>
    </div>

    @if (session('success'))
        <div class="alert alert-success border-0 shadow-sm">{{ session('success') }}</div>
    @endif

    <div class="row g-3">
        <div class="col-lg-5">
            <section class="panel p-4 mb-3">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <div class="user-avatar text-white" style="background:#12acc2; width:58px; height:58px;">{{ strtoupper(substr($usuario->nombres,0,1).substr($usuario->apellidos,0,1)) }}</div>
                    <div>
                        <h2 class="h4 fw-bold mb-1">{{ $usuario->full_name }}</h2>
                        <span class="badge {{ $usuario->estado === 'activo' ? 'badge-soft' : ($usuario->estado === 'suspendido' ? 'badge-warning-soft' : 'badge-danger-soft') }}">{{ ucfirst($usuario->estado) }}</span>
                    </div>
                </div>
                <dl class="row mb-0">
                    <dt class="col-sm-5">Documento</dt><dd class="col-sm-7">{{ $usuario->documento_tipo }} {{ $usuario->documento_num }}</dd>
                    <dt class="col-sm-5">Direccion</dt><dd class="col-sm-7">{{ $usuario->direccion }}</dd>
                    <dt class="col-sm-5">Telefono</dt><dd class="col-sm-7">{{ $usuario->telefono ?? '-' }}</dd>
                    <dt class="col-sm-5">Categoria</dt><dd class="col-sm-7">{{ $usuario->categoria?->nombre }}</dd>
                    <dt class="col-sm-5">Medidor</dt><dd class="col-sm-7">{{ $usuario->tiene_medidor ? ($usuario->numero_medidor ?? 'Si') : 'No' }}</dd>
                    <dt class="col-sm-5">Registro</dt><dd class="col-sm-7">{{ $usuario->fecha_registro?->format('d/m/Y') }}</dd>
                </dl>
            </section>

            <section class="panel p-4">
                <h2 class="h5 fw-bold mb-3 text-danger">Dar de baja</h2>
                <form method="POST" action="{{ route('admin.usuarios.destroy', $usuario) }}" onsubmit="return confirm('Confirmar baja del usuario?')">
                    @csrf
                    @method('DELETE')
                    <label class="form-label fw-semibold">Motivo de baja</label>
                    <textarea name="motivo_baja" class="form-control mb-3" rows="3" required placeholder="Escribe el motivo..."></textarea>
                    <button class="btn btn-danger">Confirmar baja</button>
                </form>
            </section>
        </div>

        <div class="col-lg-7">
            <section class="panel table-panel mb-3">
                <h2 class="h5 fw-bold mb-3">Deudas pendientes</h2>
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Tipo</th><th>Concepto</th><th>Monto</th></tr></thead>
                        <tbody>
                            @foreach ($usuario->pagosPendientes as $pendiente)
                                <tr><td>Cuota</td><td>{{ $pendiente->periodo_mes }}/{{ $pendiente->periodo_anio }}</td><td>S/{{ number_format((float) $pendiente->monto_pendiente, 2) }}</td></tr>
                            @endforeach
                            @foreach ($usuario->multasAplicadas as $multa)
                                <tr><td>Multa</td><td>{{ $multa->multa?->nombre }}</td><td>S/{{ number_format((float) $multa->monto_aplicado, 2) }}</td></tr>
                            @endforeach
                            @if ($usuario->pagosPendientes->isEmpty() && $usuario->multasAplicadas->isEmpty())
                                <tr><td colspan="3" class="text-center text-secondary">Sin deudas pendientes.</td></tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="panel table-panel">
                <h2 class="h5 fw-bold mb-3">Ultimos cobros</h2>
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Serie</th><th>Periodo</th><th>Monto</th><th>Estado</th></tr></thead>
                        <tbody>
                            @forelse ($usuario->cobros as $cobro)
                                <tr><td class="series-link">{{ $cobro->numero_serie }}</td><td>{{ $cobro->periodo_mes }}/{{ $cobro->periodo_anio }}</td><td>S/{{ number_format((float) $cobro->monto_recibido, 2) }}</td><td>{{ ucfirst($cobro->estado) }}</td></tr>
                            @empty
                                <tr><td colspan="4" class="text-center text-secondary">Sin cobros registrados.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </section>
        </div>
    </div>
@endsection
