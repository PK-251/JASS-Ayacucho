@extends('layouts.app')

@section('nav')
    @include('admin.partials.nav', ['active' => 'cobros'])
@endsection

@section('content')
    <div class="topbar">
        <div>
            <div class="page-subtitle">Cobros</div>
            <h1 class="page-title">Editar cobro</h1>
            <div class="page-subtitle">{{ $cobro->numero_serie }} · {{ $cobro->vecino?->full_name }}</div>
        </div>
        <a class="btn btn-outline-secondary" href="{{ route('admin.cobros.show', $cobro) }}">Volver</a>
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

    <form method="POST" action="{{ route('admin.cobros.update', $cobro) }}" class="panel p-4" style="max-width:760px">
        @csrf
        @method('PUT')
        <div class="alert alert-warning border-0">Toda edicion quedara registrada en auditoria. Indica un motivo claro para el cambio.</div>

        <div class="row g-3">
            <div class="col-md-6">
                <label class="form-label fw-semibold">Monto recibido (S/)</label>
                <input class="form-control" name="monto_recibido" value="{{ old('monto_recibido', number_format((float) $cobro->monto_recibido, 2, '.', '')) }}" required>
                <div class="form-text">Monto total calculado: S/{{ number_format((float) $cobro->monto_total, 2) }}</div>
            </div>
            <div class="col-md-6">
                <label class="form-label fw-semibold">Metodo de pago</label>
                <select class="form-select" name="metodo_pago" required>
                    @foreach (['efectivo' => 'Efectivo', 'transferencia' => 'Transferencia', 'yape' => 'Yape', 'plin' => 'Plin', 'otro' => 'Otro'] as $value => $label)
                        <option value="{{ $value }}" @selected(old('metodo_pago', $cobro->metodo_pago) === $value)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-12">
                <label class="form-label fw-semibold">Observaciones</label>
                <textarea class="form-control" name="observaciones" rows="3">{{ old('observaciones', $cobro->observaciones) }}</textarea>
            </div>
            <div class="col-12">
                <label class="form-label fw-semibold">Motivo de la edicion</label>
                <textarea class="form-control" name="motivo_ultima_edicion" rows="3" required placeholder="Explica brevemente por que se modifica el cobro...">{{ old('motivo_ultima_edicion') }}</textarea>
            </div>
        </div>

        <div class="d-flex justify-content-end gap-2 mt-4">
            <a class="btn btn-outline-secondary" href="{{ route('admin.cobros.show', $cobro) }}">Cancelar</a>
            <button class="btn btn-aqua px-4">Guardar cambios</button>
        </div>
    </form>
@endsection
