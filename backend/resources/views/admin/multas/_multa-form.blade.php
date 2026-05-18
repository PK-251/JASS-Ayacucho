<div class="row g-3">
    <div class="col-md-4">
        <label class="form-label fw-semibold">Codigo</label>
        <input class="form-control" value="{{ $multa->codigo ?? $codigoSugerido ?? '' }}" disabled>
    </div>
    <div class="col-md-4">
        <label class="form-label fw-semibold">Monto (S/)</label>
        <input class="form-control" type="number" min="0.01" step="0.01" name="monto" value="{{ old('monto', isset($multa) && $multa->monto ? number_format((float) $multa->monto, 2, '.', '') : '') }}" required>
    </div>
    <div class="col-md-4">
        <label class="form-label fw-semibold">Tipo de aplicacion</label>
        <select class="form-select" name="tipo_aplicacion" required>
            @foreach (['manual' => 'Manual', 'automatica_mensual' => 'Automatica mensual', 'semi_automatica' => 'Semi automatica'] as $value => $label)
                <option value="{{ $value }}" @selected(old('tipo_aplicacion', $multa->tipo_aplicacion ?? 'manual') === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Nombre</label>
        <input class="form-control" name="nombre" value="{{ old('nombre', $multa->nombre ?? '') }}" placeholder="Ej. Inasistencia a faena" required>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Descripcion</label>
        <textarea class="form-control" name="descripcion" rows="3">{{ old('descripcion', $multa->descripcion ?? '') }}</textarea>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Condicion de aplicacion</label>
        <textarea class="form-control" name="condicion_aplicacion" rows="2">{{ old('condicion_aplicacion', $multa->condicion_aplicacion ?? '') }}</textarea>
    </div>
    <div class="col-12">
        <div class="form-check form-switch">
            <input class="form-check-input" type="checkbox" name="activa" value="1" id="activa" @checked(old('activa', $multa->activa ?? true))>
            <label class="form-check-label fw-semibold" for="activa">Multa activa</label>
        </div>
    </div>
</div>
