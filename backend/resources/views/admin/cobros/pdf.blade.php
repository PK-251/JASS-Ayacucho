<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <style>
        @page { margin: 22px; }
        body { font-family: DejaVu Sans, sans-serif; color: #183247; font-size: 12px; }
        .receipt { border: 1px solid #88dfe8; border-radius: 12px; padding: 20px; }
        .header { background: #e9fbfd; border: 1px solid #b7edf4; border-radius: 10px; padding: 14px 16px; }
        .brand { font-size: 22px; font-weight: bold; color: #087f95; letter-spacing: .5px; margin: 0; }
        .subtitle { color: #5f7284; margin: 3px 0 0; }
        .status { float: right; background: #d8f8e8; color: #047857; border-radius: 999px; padding: 6px 12px; font-weight: bold; font-size: 11px; }
        .meta { width: 100%; margin-top: 14px; border-collapse: collapse; }
        .meta td { border: 0; padding: 4px 0; vertical-align: top; }
        .label { color: #6b7f90; font-size: 10px; text-transform: uppercase; font-weight: bold; }
        .value { font-weight: bold; color: #153247; }
        .grid { width: 100%; margin-top: 14px; border-collapse: separate; border-spacing: 0 10px; }
        .card { border: 1px solid #d7f4f7; border-radius: 10px; padding: 12px; background: #fbffff; }
        .section-title { color: #087f95; font-weight: bold; margin: 0 0 8px; font-size: 13px; }
        .items { width: 100%; border-collapse: collapse; margin-top: 14px; }
        .items th { background: #e9fbfd; color: #087f95; text-align: left; padding: 9px; border-bottom: 1px solid #b7edf4; }
        .items td { padding: 10px 9px; border-bottom: 1px solid #e0f4f6; }
        .right { text-align: right; }
        .total-row th { padding: 12px 9px; border-top: 2px solid #087f95; }
        .total { font-size: 24px; color: #087f95; font-weight: bold; }
        .note { margin-top: 14px; padding: 10px; border-radius: 8px; background: #f3fbfc; color: #5f7284; font-size: 11px; }
        .footer { margin-top: 16px; color: #74879a; font-size: 10px; text-align: center; }
    </style>
</head>
<body>
@php
    $usuario = $cobro->vecino;
    $operador = $cobro->operador;
    $fecha = $cobro->fecha_cobro?->format('d/m/Y') ?? '';
    $hora = substr((string) $cobro->hora_cobro, 0, 5);
@endphp
<div class="receipt">
    <div class="header">
        <span class="status">{{ strtoupper($cobro->estado) }}</span>
        <p class="brand">J.A.S.S. QUILCATA</p>
        <p class="subtitle">Sara-Sara, Ayacucho · Comprobante de pago del servicio de agua potable</p>
        <table class="meta">
            <tr>
                <td width="50%"><div class="label">N. de serie</div><div class="value">{{ $cobro->numero_serie }}</div></td>
                <td width="50%"><div class="label">Fecha y hora</div><div class="value">{{ $fecha }} {{ $hora }}</div></td>
            </tr>
            <tr>
                <td><div class="label">Periodo cobrado</div><div class="value">{{ str_pad($cobro->periodo_mes, 2, '0', STR_PAD_LEFT) }}/{{ $cobro->periodo_anio }}</div></td>
                <td><div class="label">Metodo de pago</div><div class="value">{{ ucfirst($cobro->metodo_pago) }}</div></td>
            </tr>
        </table>
    </div>

    <table class="grid">
        <tr>
            <td width="50%" class="card">
                <p class="section-title">Usuario</p>
                <div class="label">Nombre completo</div>
                <div class="value">{{ $usuario?->full_name }}</div>
                <br>
                <div class="label">Codigo / Documento</div>
                <div>{{ $usuario?->codigo }} · {{ $usuario?->documento_tipo }} {{ $usuario?->documento_num }}</div>
                <br>
                <div class="label">Direccion</div>
                <div>{{ $usuario?->direccion }}</div>
            </td>
            <td width="50%" class="card">
                <p class="section-title">Servicio</p>
                <div class="label">Categoria</div>
                <div class="value">{{ $usuario?->categoria?->nombre ?? 'Sin categoria' }}</div>
                <br>
                <div class="label">Medidor</div>
                <div>{{ $usuario?->tiene_medidor ? ($usuario?->numero_medidor ?: 'Con medidor') : 'Sin medidor' }}</div>
                <br>
                <div class="label">Registrado por</div>
                <div>{{ $operador?->full_name ?? 'Sistema' }}</div>
            </td>
        </tr>
    </table>

    <table class="items">
        <thead>
            <tr><th>Concepto</th><th class="right">Monto</th></tr>
        </thead>
        <tbody>
            <tr><td>Cuota mensual</td><td class="right">S/{{ number_format((float) $cobro->monto_cuota, 2) }}</td></tr>
            <tr><td>Deuda anterior regularizada</td><td class="right">S/{{ number_format((float) $cobro->monto_deuda_anterior, 2) }}</td></tr>
            <tr><td>Multas cobradas</td><td class="right">S/{{ number_format((float) $cobro->monto_multas, 2) }}</td></tr>
            <tr class="total-row"><th>Total pagado</th><th class="right total">S/{{ number_format((float) $cobro->monto_recibido, 2) }}</th></tr>
        </tbody>
    </table>

    @if ($cobro->observaciones)
        <div class="note"><strong>Observaciones:</strong> {{ $cobro->observaciones }}</div>
    @endif

    <div class="note">
        Este comprobante fue generado automaticamente por el sistema J.A.S.S. QUILCATA. Conserve este documento como constancia de pago.
    </div>
    <div class="footer">
        {{ $cobro->comprobante?->codigo_qr_url ? 'Verificacion: '.$cobro->comprobante->codigo_qr_url : 'Documento interno de cobranza' }}
    </div>
</div>
</body>
</html>
