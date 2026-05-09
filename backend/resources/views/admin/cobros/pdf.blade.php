<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: DejaVu Sans, sans-serif; color: #183247; }
        .box { border: 1px solid #8be4ef; border-radius: 8px; padding: 22px; }
        .title { color: #087f95; font-size: 24px; font-weight: bold; margin: 0; }
        .muted { color: #74879a; font-size: 12px; }
        table { width: 100%; border-collapse: collapse; margin-top: 16px; }
        td, th { padding: 8px; border-bottom: 1px solid #d9f2f6; text-align: left; }
        .right { text-align: right; }
        .total { font-size: 22px; color: #087f95; font-weight: bold; }
    </style>
</head>
<body>
    <div class="box">
        <p class="title">J.A.S.S. QUILCATA</p>
        <p class="muted">Comprobante de pago del servicio de agua potable</p>
        <hr>
        <table>
            <tr><th>N. Serie</th><td>{{ $cobro->numero_serie }}</td></tr>
            <tr><th>Usuario</th><td>{{ $cobro->vecino?->full_name }}</td></tr>
            <tr><th>Codigo</th><td>{{ $cobro->vecino?->codigo }}</td></tr>
            <tr><th>Fecha</th><td>{{ $cobro->fecha_cobro?->format('d/m/Y') }} {{ substr((string) $cobro->hora_cobro, 0, 5) }}</td></tr>
            <tr><th>Metodo</th><td>{{ ucfirst($cobro->metodo_pago) }}</td></tr>
        </table>
        <table>
            <tr><td>Cuota mensual</td><td class="right">S/{{ number_format((float) $cobro->monto_cuota, 2) }}</td></tr>
            <tr><td>Deuda anterior</td><td class="right">S/{{ number_format((float) $cobro->monto_deuda_anterior, 2) }}</td></tr>
            <tr><td>Multas</td><td class="right">S/{{ number_format((float) $cobro->monto_multas, 2) }}</td></tr>
            <tr><th>Total pagado</th><th class="right total">S/{{ number_format((float) $cobro->monto_recibido, 2) }}</th></tr>
        </table>
        <p class="muted">Generado por el sistema AquaRural/J.A.S.S. QUILCATA.</p>
    </div>
</body>
</html>
