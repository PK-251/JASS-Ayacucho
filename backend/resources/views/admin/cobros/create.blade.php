@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Cobros</div>
            <h1 class="page-title">Registrar Pago</h1>
            <div class="page-subtitle">Selecciona un usuario y procesa el cobro del periodo.</div>
        </div>
        <a class="btn btn-outline-secondary" href="{{ route('admin.cobros.index') }}">Volver</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger border-0 shadow-sm">
            <strong>Revisa el formulario.</strong>
            <ul class="mb-0 mt-2">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="row g-3">
        <div class="col-lg-5">
            <section class="panel table-panel h-100">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="h5 fw-bold mb-0">Padron de usuarios</h2>
                    <span class="badge badge-soft">{{ $usuarios->count() }} visibles</span>
                </div>
                <form method="GET" action="{{ route('admin.cobros.create') }}" class="d-flex gap-2 mb-3">
                    <input class="form-control" name="buscar" value="{{ $buscar }}" placeholder="Buscar por codigo, DNI o nombre...">
                    <button class="btn btn-outline-info">Buscar</button>
                </form>

                <div class="d-grid gap-2">
                    @forelse ($usuarios as $item)
                        <a class="text-decoration-none" href="{{ route('admin.cobros.create', ['usuario_id' => $item->id, 'anio' => $anio, 'mes' => $mes]) }}">
                            <div class="panel p-3 {{ $usuario?->id === $item->id ? 'border-info' : '' }}" style="box-shadow:none">
                                <div class="d-flex justify-content-between gap-3">
                                    <div>
                                        <div class="fw-bold text-dark">{{ $item->full_name }}</div>
                                        <div class="small text-secondary">{{ $item->codigo }} · {{ $item->documento_num }}</div>
                                    </div>
                                    <span class="badge {{ $item->estado === 'activo' ? 'badge-soft' : 'badge-warning-soft' }} align-self-start">{{ ucfirst($item->estado) }}</span>
                                </div>
                            </div>
                        </a>
                    @empty
                        <div class="text-center text-secondary py-4">No se encontraron usuarios.</div>
                    @endforelse
                </div>
            </section>
        </div>

        <div class="col-lg-7">
            @if ($usuario)
                <section class="panel p-4 mb-3">
                    <div class="d-flex align-items-center gap-3">
                        <div class="user-avatar text-white" style="background:#12acc2; width:62px; height:62px;">{{ strtoupper(substr($usuario->nombres,0,1).substr($usuario->apellidos,0,1)) }}</div>
                        <div>
                            <h2 class="h4 fw-bold mb-1">{{ $usuario->full_name }}</h2>
                            <div class="text-secondary">{{ $usuario->codigo }} · {{ $usuario->categoria?->nombre }} · {{ $usuario->direccion }}</div>
                        </div>
                    </div>
                </section>

                <form method="POST" action="{{ route('admin.cobros.store') }}" class="panel p-4">
                    @csrf
                    <input type="hidden" name="vecino_id" value="{{ $usuario->id }}">
                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Periodo anio</label>
                            <input class="form-control" type="number" name="periodo_anio" value="{{ old('periodo_anio', $anio) }}" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Periodo mes</label>
                            <input class="form-control" type="number" name="periodo_mes" min="1" max="12" value="{{ old('periodo_mes', $mes) }}" required>
                        </div>
                    </div>

                    <h3 class="h6 fw-bold text-uppercase text-secondary mb-3">Desglose a pagar</h3>
                    <div class="table-responsive mb-4">
                        <table class="table">
                            <tbody>
                                <tr><td>Cuota mensual</td><td class="text-end fw-semibold">S/{{ number_format($desglose['cuota'], 2) }}</td></tr>
                                <tr><td>Deuda anterior</td><td class="text-end fw-semibold text-danger">S/{{ number_format($desglose['deuda_cuotas'], 2) }}</td></tr>
                                <tr><td>Multas pendientes</td><td class="text-end fw-semibold text-danger">S/{{ number_format($desglose['deuda_multas'], 2) }}</td></tr>
                                <tr><th>Total a cobrar</th><th class="text-end fs-4 text-info">S/{{ number_format($desglose['total'], 2) }}</th></tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Monto recibido (S/)</label>
                            <input class="form-control" name="monto_recibido" value="{{ old('monto_recibido', number_format($desglose['total'], 2, '.', '')) }}" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Metodo de pago</label>
                            <select class="form-select" name="metodo_pago" required>
                                @foreach (['efectivo' => 'Efectivo', 'transferencia' => 'Transferencia', 'yape' => 'Yape', 'plin' => 'Plin', 'otro' => 'Otro'] as $value => $label)
                                    <option value="{{ $value }}" @selected(old('metodo_pago', 'efectivo') === $value)>{{ $label }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-12">
                            <label class="form-label fw-semibold">Observaciones</label>
                            <textarea class="form-control" name="observaciones" rows="3" placeholder="Ej. Pago realizado por familiar...">{{ old('observaciones') }}</textarea>
                        </div>
                    </div>

                    <div class="d-flex justify-content-end gap-2 mt-4">
                        <a class="btn btn-outline-secondary" href="{{ route('admin.cobros.index') }}">Cancelar</a>
                        <button class="btn btn-aqua px-4">Confirmar pago</button>
                    </div>
                </form>
            @else
                <section class="panel p-5 text-center h-100 d-flex flex-column justify-content-center">
                    <h2 class="h4 fw-bold">Selecciona un usuario</h2>
                    <p class="text-secondary mb-0">El detalle de deuda y el formulario de pago apareceran aqui.</p>
                </section>
            @endif
        </div>
    </div>
@endsection
