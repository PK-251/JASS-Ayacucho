<div class="row g-3">
    <div class="col-md-6">
        <label class="form-label fw-semibold">N. Serie</label>
        <input class="form-control" value="{{ $ingreso->numero_serie ?? $serieSugerida ?? '' }}" disabled>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Fecha</label>
        <input class="form-control" type="date" name="fecha_ingreso" value="{{ old('fecha_ingreso', optional($ingreso->fecha_ingreso ?? null)->format('Y-m-d') ?? now()->format('Y-m-d')) }}" required>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Categoria</label>
        <select class="form-select" name="categoria_id" required>
            <option value="">Selecciona una categoria</option>
            @foreach ($categorias as $categoria)
                <option value="{{ $categoria->id }}" @selected((string) old('categoria_id', $ingreso->categoria_id ?? '') === (string) $categoria->id)>{{ $categoria->nombre }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Monto (S/)</label>
        <input class="form-control" name="monto" value="{{ old('monto', isset($ingreso) ? number_format((float) $ingreso->monto, 2, '.', '') : '') }}" placeholder="0.00" required>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Concepto</label>
        <input class="form-control" name="concepto" value="{{ old('concepto', $ingreso->concepto ?? '') }}" placeholder="Ej. Donacion para reparacion de bomba" required>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Descripcion</label>
        <textarea class="form-control" name="descripcion" rows="2">{{ old('descripcion', $ingreso->descripcion ?? '') }}</textarea>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Usuario relacionado <span class="text-secondary">(opcional)</span></label>
        <select class="form-select" name="vecino_id">
            <option value="">Sin usuario</option>
            @foreach ($usuarios as $usuario)
                <option value="{{ $usuario->id }}" @selected((string) old('vecino_id', $ingreso->vecino_id ?? '') === (string) $usuario->id)>{{ $usuario->codigo }} · {{ $usuario->full_name }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Metodo de pago</label>
        <select class="form-select" name="metodo_pago" required>
            @foreach (['efectivo' => 'Efectivo', 'transferencia' => 'Transferencia', 'yape' => 'Yape', 'plin' => 'Plin', 'otro' => 'Otro'] as $value => $label)
                <option value="{{ $value }}" @selected(old('metodo_pago', $ingreso->metodo_pago ?? 'efectivo') === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Comprobante <span class="text-secondary">(PDF/JPG/PNG hasta 5MB)</span></label>
        <input class="form-control" type="file" name="comprobante" accept=".pdf,.jpg,.jpeg,.png">
        @if (!empty($ingreso?->comprobante_nombre))
            <div class="form-text">Actual: {{ $ingreso->comprobante_nombre }}</div>
        @endif
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Observaciones</label>
        <textarea class="form-control" name="observaciones" rows="3">{{ old('observaciones', $ingreso->observaciones ?? '') }}</textarea>
    </div>
    @if (!empty($editing))
        <div class="col-12">
            <label class="form-label fw-semibold">Motivo de la edicion</label>
            <textarea class="form-control" name="motivo_ultima_edicion" rows="3" required placeholder="Explica por que se modifica este ingreso...">{{ old('motivo_ultima_edicion') }}</textarea>
        </div>
    @endif
</div>
