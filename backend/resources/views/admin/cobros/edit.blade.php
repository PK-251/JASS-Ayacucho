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
        <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.cobros.show', $cobro) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Volver</a>
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

    <form method="POST" action="{{ route('admin.cobros.update', $cobro) }}" class="panel p-4 form-card" style="max-width:760px">
        @csrf
        @method('PUT')
        <div class="alert alert-warning border-0">Toda edicion quedara registrada en auditoria. Indica un motivo claro para el cambio.</div>

        <div class="row g-3">
            <div class="col-md-6">
                <label class="form-label fw-semibold">Monto recibido (S/)</label>
                <input class="form-control" type="number" min="0" step="0.01" name="monto_recibido" value="{{ old('monto_recibido', number_format((float) $cobro->monto_recibido, 2, '.', '')) }}" required>
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

        <div class="form-actions">
            <a class="btn btn-outline-secondary btn-icon" href="{{ route('admin.cobros.show', $cobro) }}"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/><path d="M9 12h12"/></svg></span>Cancelar</a>
            <button class="btn btn-aqua btn-icon px-4"><span class="action-icon-sm"><svg viewBox="0 0 24 24"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2Z"/><path d="M17 21v-8H7v8"/><path d="M7 3v5h8"/></svg></span>Guardar cambios</button>
        </div>
    </form>
@endsection
