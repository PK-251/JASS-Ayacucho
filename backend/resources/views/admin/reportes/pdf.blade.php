<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <style>
        @page { margin: 28px; }
        body { font-family: DejaVu Sans, sans-serif; color: #173247; font-size: 11px; }
        .header { background: #e9fbfd; border: 1px solid #b7edf4; border-radius: 10px; padding: 16px; margin-bottom: 14px; }
        .brand { color: #087f95; font-weight: bold; font-size: 22px; margin: 0; }
        .title { color: #102337; font-size: 20px; font-weight: bold; margin: 8px 0 0; }
        .muted { color: #64748b; }
        .badge { display: inline-block; border-radius: 999px; padding: 5px 10px; font-size: 10px; font-weight: bold; }
        .ok { background: #d8f8e8; color: #047857; }
        .warn { background: #fff0c2; color: #b45309; }
        .bad { background: #ffe0e0; color: #be123c; }
        .grid { width: 100%; border-collapse: separate; border-spacing: 10px; margin-left: -10px; }
        .card { border: 1px solid #c9f0f4; background: #fbffff; border-radius: 10px; padding: 12px; }
        .label { color: #64748b; font-size: 10px; text-transform: uppercase; font-weight: bold; }
        .metric { color: #087f95; font-size: 20px; font-weight: bold; margin-top: 4px; }
        .danger { color: #dc2626; }
        .success { color: #059669; }
        h2 { font-size: 14px; color: #087f95; margin: 18px 0 8px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
        th { background: #e9fbfd; color: #087f95; text-align: left; padding: 8px; border-bottom: 1px solid #b7edf4; }
        td { padding: 8px; border-bottom: 1px solid #e0f4f6; }
        .right { text-align: right; }
        .footer { margin-top: 18px; border-top: 1px solid #c9f0f4; padding-top: 10px; color: #64748b; font-size: 10px; }
        .signature { margin-top: 26px; width: 45%; text-align: center; border-top: 1px solid #173247; padding-top: 6px; }
    </style>
</head>
<body>
@php
    $months = [1 => 'Enero', 2 => 'Febrero', 3 => 'Marzo', 4 => 'Abril', 5 => 'Mayo', 6 => 'Junio', 7 => 'Julio', 8 => 'Agosto', 9 => 'Setiembre', 10 => 'Octubre', 11 => 'Noviembre', 12 => 'Diciembre'];
    $periodo = ($months[$reporte->periodo_mes] ?? $reporte->periodo_mes).' '.$reporte->periodo_anio;
    $estadoClass = $reporte->estado === 'aprobado' ? 'ok' : ($reporte->estado === 'rechazado' ? 'bad' : 'warn');
@endphp
<div class="header">
    <p class="brand">J.A.S.S. QUILCATA</p>
    <div class="muted">Sara-Sara, Ayacucho · Sistema de Gestion de Agua Potable</div>
    <p class="title">Reporte Mensual - {{ $periodo }}</p>
    <span class="badge {{ $estadoClass }}">{{ strtoupper(str_replace('_', ' ', $reporte->estado)) }}</span>
    <span class="muted"> Generado: {{ $reporte->fecha_generacion?->format('d/m/Y H:i') }}</span>
</div>

<table class="grid">
    <tr>
        <td class="card" width="25%"><div class="label">Ingresos</div><div class="metric">S/{{ number_format((float) $reporte->total_ingresos, 2) }}</div></td>
        <td class="card" width="25%"><div class="label">Egresos</div><div class="metric danger">S/{{ number_format((float) $reporte->total_egresos, 2) }}</div></td>
        <td class="card" width="25%"><div class="label">Balance</div><div class="metric {{ $reporte->balance_neto < 0 ? 'danger' : 'success' }}">S/{{ number_format((float) $reporte->balance_neto, 2) }}</div></td>
        <td class="card" width="25%"><div class="label">Morosidad</div><div class="metric">{{ number_format((float) $reporte->porcentaje_morosidad, 1) }}%</div></td>
    </tr>
</table>

<h2>Resumen financiero</h2>
<table>
    <thead><tr><th>Ingresos</th><th class="right">Monto</th><th>Egresos</th><th class="right">Monto</th></tr></thead>
    <tbody>
        <tr><td>Cuotas mensuales</td><td class="right">S/{{ number_format((float) $reporte->total_cuotas, 2) }}</td><td>Materiales</td><td class="right">S/{{ number_format((float) $reporte->total_materiales, 2) }}</td></tr>
        <tr><td>Multas cobradas</td><td class="right">S/{{ number_format((float) $reporte->total_multas_cobradas, 2) }}</td><td>Personal</td><td class="right">S/{{ number_format((float) $reporte->total_personal, 2) }}</td></tr>
        <tr><td>Cuotas extraordinarias</td><td class="right">S/{{ number_format((float) $reporte->total_cuotas_extraordinarias, 2) }}</td><td>Mantenimiento</td><td class="right">S/{{ number_format((float) $reporte->total_mantenimiento, 2) }}</td></tr>
        <tr><td>Donaciones</td><td class="right">S/{{ number_format((float) $reporte->total_donaciones, 2) }}</td><td>Combustible</td><td class="right">S/{{ number_format((float) $reporte->total_combustible, 2) }}</td></tr>
        <tr><td>Otros ingresos</td><td class="right">S/{{ number_format((float) $reporte->total_otros_ingresos, 2) }}</td><td>Servicios y otros</td><td class="right">S/{{ number_format((float) ($reporte->total_servicios + $reporte->total_otros_egresos), 2) }}</td></tr>
    </tbody>
</table>

<h2>Morosidad al cierre</h2>
<table>
    <tr><th>Total usuarios</th><td class="right">{{ $reporte->num_vecinos_total }}</td><th>Usuarios al dia</th><td class="right">{{ $reporte->num_vecinos_al_dia }}</td></tr>
    <tr><th>Usuarios morosos</th><td class="right">{{ $reporte->num_vecinos_morosos }}</td><th>Deuda acumulada</th><td class="right">S/{{ number_format((float) $reporte->deuda_acumulada, 2) }}</td></tr>
</table>

<h2>Top morosos</h2>
<table>
    <thead><tr><th>Codigo</th><th>Usuario</th><th class="right">Deuda</th></tr></thead>
    <tbody>
    @forelse (($reporte->top_morosos_json ?? []) as $moroso)
        <tr><td>{{ $moroso['codigo'] ?? '-' }}</td><td>{{ $moroso['nombre'] ?? '-' }}</td><td class="right">S/{{ number_format((float) ($moroso['deuda'] ?? 0), 2) }}</td></tr>
    @empty
        <tr><td colspan="3">No se registran usuarios morosos en este reporte.</td></tr>
    @endforelse
    </tbody>
</table>

@if ($reporte->observaciones_admin)
    <h2>Observaciones del administrador</h2>
    <div class="card">{{ $reporte->observaciones_admin }}</div>
@endif

@if ($reporte->estado === 'aprobado')
    <div class="signature">Administrador J.A.S.S. QUILCATA<br>{{ $reporte->fecha_aprobacion?->format('d/m/Y H:i') }}</div>
@endif

<div class="footer">
    Documento generado por AquaRural/J.A.S.S. QUILCATA. Hash oficial: {{ $reporte->hash_pdf_oficial ?: 'Pendiente de aprobacion' }}
</div>
</body>
</html>