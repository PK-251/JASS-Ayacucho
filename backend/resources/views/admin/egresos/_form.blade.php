<div class="row g-3">
    <div class="col-md-6">
        <label class="form-label fw-semibold">N. Serie</label>
        <input class="form-control" value="{{ $egreso->numero_serie ?? $serieSugerida ?? '' }}" disabled>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Fecha</label>
        <input class="form-control" type="date" name="fecha_egreso" value="{{ old('fecha_egreso', optional($egreso->fecha_egreso ?? null)->format('Y-m-d') ?? now()->format('Y-m-d')) }}" required>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Concepto</label>
        <input class="form-control" name="concepto" value="{{ old('concepto', $egreso->concepto ?? '') }}" placeholder="Ej. Compra de cloro" required>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Categoria</label>
        <select class="form-select" name="categoria_id" required>
            <option value="">Selecciona una categoria</option>
            @foreach ($categorias as $categoria)
                <option value="{{ $categoria->id }}" @selected((string) old('categoria_id', $egreso->categoria_id ?? '') === (string) $categoria->id)>{{ $categoria->nombre }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Proveedor</label>
        <select class="form-select" name="proveedor_id">
            <option value="">Sin proveedor</option>
            @foreach ($proveedores as $proveedor)
                <option value="{{ $proveedor->id }}" @selected((string) old('proveedor_id', $egreso->proveedor_id ?? '') === (string) $proveedor->id)>{{ $proveedor->nombre }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Monto (S/)</label>
        <input class="form-control" type="number" min="0.01" step="0.01" name="monto" value="{{ old('monto', isset($egreso) ? number_format((float) $egreso->monto, 2, '.', '') : '') }}" placeholder="0.00" required>
        <div class="form-text">Mayor a S/{{ number_format((float) $umbral, 2) }} requiere aprobacion.</div>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Metodo de pago</label>
        <select class="form-select" name="metodo_pago" required>
            @foreach (['efectivo' => 'Efectivo', 'transferencia' => 'Transferencia', 'yape' => 'Yape', 'plin' => 'Plin', 'otro' => 'Otro'] as $value => $label)
                <option value="{{ $value }}" @selected(old('metodo_pago', $egreso->metodo_pago ?? 'efectivo') === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Tipo de comprobante</label>
        <select class="form-select" name="comprobante_tipo" required>
            @foreach (['boleta' => 'Boleta', 'factura' => 'Factura', 'recibo' => 'Recibo', 'ticket' => 'Ticket', 'sin_comprobante' => 'Sin comprobante', 'otro' => 'Otro'] as $value => $label)
                <option value="{{ $value }}" @selected(old('comprobante_tipo', $egreso->comprobante_tipo ?? 'sin_comprobante') === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Numero de comprobante</label>
        <input class="form-control" name="comprobante_numero" value="{{ old('comprobante_numero', $egreso->comprobante_numero ?? '') }}" placeholder="Ej. B001-1234">
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Archivo de comprobante</label>
        <input class="form-control" type="file" name="comprobante" accept=".pdf,.jpg,.jpeg,.png">
        @if (!empty($egreso?->comprobante_nombre))
            <div class="form-text">Actual: {{ $egreso->comprobante_nombre }}</div>
        @endif
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Descripcion</label>
        <textarea class="form-control" name="descripcion" rows="2">{{ old('descripcion', $egreso->descripcion ?? '') }}</textarea>
    </div>
    <div class="col-12">
        <label class="form-label fw-semibold">Observaciones</label>
        <textarea class="form-control" name="observaciones" rows="3">{{ old('observaciones', $egreso->observaciones ?? '') }}</textarea>
    </div>
    @if (!empty($editing))
        <div class="col-12">
            <label class="form-label fw-semibold">Motivo de la edicion</label>
            <textarea class="form-control" name="motivo_ultima_edicion" rows="3" required placeholder="Explica por que se modifica este egreso...">{{ old('motivo_ultima_edicion') }}</textarea>
        </div>
    @endif
</div>
