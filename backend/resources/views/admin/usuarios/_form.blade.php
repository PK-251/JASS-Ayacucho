<div class="row g-3">
    <div class="col-md-3">
        <label class="form-label fw-semibold">Codigo</label>
        <input class="form-control" value="{{ $codigoSugerido ?? $usuario->codigo }}" disabled>
    </div>
    <div class="col-md-3">
        <label class="form-label fw-semibold">Tipo documento</label>
        <select name="documento_tipo" class="form-select" required>
            @foreach (['DNI', 'RUC', 'CE'] as $tipo)
                <option value="{{ $tipo }}" @selected(old('documento_tipo', $usuario->documento_tipo) === $tipo)>{{ $tipo }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Documento</label>
        <input name="documento_num" value="{{ old('documento_num', $usuario->documento_num) }}" class="form-control @error('documento_num') is-invalid @enderror" required maxlength="11">
        @error('documento_num')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-md-6">
        <label class="form-label fw-semibold">Nombres</label>
        <input name="nombres" value="{{ old('nombres', $usuario->nombres) }}" class="form-control @error('nombres') is-invalid @enderror" required>
        @error('nombres')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Apellidos</label>
        <input name="apellidos" value="{{ old('apellidos', $usuario->apellidos) }}" class="form-control @error('apellidos') is-invalid @enderror" required>
        @error('apellidos')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-12">
        <label class="form-label fw-semibold">Direccion</label>
        <input name="direccion" value="{{ old('direccion', $usuario->direccion) }}" class="form-control @error('direccion') is-invalid @enderror" required>
        @error('direccion')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-md-6">
        <label class="form-label fw-semibold">Telefono</label>
        <input name="telefono" value="{{ old('telefono', $usuario->telefono) }}" class="form-control">
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Email</label>
        <input name="email" value="{{ old('email', $usuario->email) }}" class="form-control @error('email') is-invalid @enderror">
        @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-md-6">
        <label class="form-label fw-semibold">Categoria</label>
        <select name="categoria_id" class="form-select" required>
            @foreach ($categorias as $categoria)
                <option value="{{ $categoria->id }}" @selected((int) old('categoria_id', $usuario->categoria_id) === $categoria->id)>{{ $categoria->nombre }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Estado</label>
        <select name="estado" class="form-select" required>
            @foreach (['activo' => 'Activo', 'suspendido' => 'Suspendido', 'cortado' => 'Cortado'] as $value => $label)
                <option value="{{ $value }}" @selected(old('estado', $usuario->estado) === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>

    <div class="col-md-6">
        <div class="form-check form-switch mt-4">
            <input class="form-check-input" type="checkbox" name="tiene_medidor" value="1" id="tiene_medidor" @checked(old('tiene_medidor', $usuario->tiene_medidor))>
            <label class="form-check-label fw-semibold" for="tiene_medidor">Tiene medidor de agua</label>
        </div>
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Numero de medidor</label>
        <input name="numero_medidor" value="{{ old('numero_medidor', $usuario->numero_medidor) }}" class="form-control @error('numero_medidor') is-invalid @enderror">
        @error('numero_medidor')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>

    <div class="col-md-6">
        <label class="form-label fw-semibold">Fecha de corte</label>
        <input type="date" name="fecha_corte" value="{{ old('fecha_corte', optional($usuario->fecha_corte)->format('Y-m-d')) }}" class="form-control @error('fecha_corte') is-invalid @enderror">
        @error('fecha_corte')<div class="invalid-feedback">{{ $message }}</div>@enderror
    </div>
    <div class="col-md-6">
        <label class="form-label fw-semibold">Motivo de estado</label>
        <input name="motivo_estado" value="{{ old('motivo_estado', $usuario->motivo_estado) }}" class="form-control">
    </div>
</div>

<div class="d-flex justify-content-end gap-2 mt-4">
    <a href="{{ route('admin.usuarios.index') }}" class="btn btn-outline-secondary">Cancelar</a>
    <button class="btn btn-aqua px-4">{{ $buttonText }}</button>
</div>
