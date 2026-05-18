<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <style>
        @page { margin: 28px; }
        body { font-family: DejaVu Sans, sans-serif; color: #173247; font-size: 11px; }
        .header { background: #e9fbfd; border: 1px solid #b7edf4; border-radius: 10px; padding: 16px; margin-bottom: 14px; }
        .brand { color: #087f95; font-size: 22px; font-weight: bold; margin: 0; }
        .title { font-size: 19px; font-weight: bold; margin: 8px 0 2px; }
        .muted { color: #64748b; }
        .grid { width: 100%; border-collapse: separate; border-spacing: 10px; margin-left: -10px; }
        .card { border: 1px solid #c9f0f4; background: #fbffff; border-radius: 10px; padding: 10px; }
        .label { color: #64748b; font-size: 10px; text-transform: uppercase; font-weight: bold; }
        .metric { color: #087f95; font-size: 20px; font-weight: bold; }
        .success { color: #059669; } .warn { color: #d97706; } .danger { color: #dc2626; }
        table.list { width: 100%; border-collapse: collapse; margin-top: 12px; }
        .list th { background: #e9fbfd; color: #087f95; text-align: left; padding: 8px; border-bottom: 1px solid #b7edf4; }
        .list td { padding: 7px 8px; border-bottom: 1px solid #e0f4f6; }
        .badge { border-radius: 999px; padding: 4px 8px; font-size: 9px; font-weight: bold; }
        .b-presente { background: #d8f8e8; color: #047857; }
        .b-tarde { background: #fff0c2; color: #b45309; }
        .b-ausente { background: #ffe0e0; color: #be123c; }
        .b-justificado { background: #dff7ff; color: #087f95; }
        .footer { margin-top: 18px; border-top: 1px solid #c9f0f4; padding-top: 10px; color: #64748b; font-size: 10px; }
    </style>
</head>
<body>
@php
    $badgeClass = ['presente' => 'b-presente', 'tarde' => 'b-tarde', 'ausente' => 'b-ausente', 'justificado' => 'b-justificado', 'no_marcado' => 'b-tarde'];
@endphp
<div class="header">
    <p class="brand">J.A.S.S. QUILCATA</p>
    <div class="muted">Sara-Sara, Ayacucho · Control de Asistencia</div>
    <p class="title">{{ $evento->titulo }}</p>
    <div class="muted">{{ $evento->tipo?->nombre }} · {{ $evento->fecha_evento?->format('d/m/Y') }} {{ substr((string) $evento->hora_inicio, 0, 5) }} · {{ $evento->lugar }}</div>
</div>

<table class="grid">
    <tr>
        <td class="card"><div class="label">Convocados</div><div class="metric">{{ $stats['total'] }}</div></td>
        <td class="card"><div class="label">Presentes</div><div class="metric success">{{ $stats['presentes'] }}</div></td>
        <td class="card"><div class="label">Tardes</div><div class="metric warn">{{ $stats['tardes'] }}</div></td>
        <td class="card"><div class="label">Justificados</div><div class="metric">{{ $stats['justificados'] }}</div></td>
        <td class="card"><div class="label">Ausentes</div><div class="metric danger">{{ $stats['ausentes'] }}</div></td>
    </tr>
</table>

<table class="list">
    <thead>
        <tr><th>Codigo</th><th>Usuario</th><th>Documento</th><th>Estado</th><th>Detalle</th><th>Multa</th></tr>
    </thead>
    <tbody>
    @foreach ($asistencias as $asistencia)
        <tr>
            <td>{{ $asistencia->vecino?->codigo }}</td>
            <td>{{ $asistencia->vecino?->full_name }}</td>
            <td>{{ $asistencia->vecino?->documento_num }}</td>
            <td><span class="badge {{ $badgeClass[$asistencia->estado] ?? 'b-tarde' }}">{{ strtoupper(str_replace('_', ' ', $asistencia->estado)) }}</span></td>
            <td>
                @if ($asistencia->estado === 'tarde') Llegada {{ substr((string) $asistencia->hora_llegada, 0, 5) }} @endif
                @if ($asistencia->estado === 'justificado') {{ $asistencia->motivo_justificacion }} @endif
            </td>
            <td>{{ $asistencia->multa ? 'S/'.number_format((float) $asistencia->multa->monto_aplicado, 2) : '-' }}</td>
        </tr>
    @endforeach
    </tbody>
</table>

<div class="footer">
    Estado del evento: {{ strtoupper(str_replace('_', ' ', $evento->estado)) }}.
    Confirmado por usuario ID {{ $evento->confirmada_por ?: 'pendiente' }}.
    Documento generado por AquaRural/J.A.S.S. QUILCATA.
</div>
</body>
</html>