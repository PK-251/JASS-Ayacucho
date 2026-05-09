<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReporteMensual extends Model
{
    protected $table = 'reportes_mensuales';
    protected $guarded = ['id'];
    protected $casts = [
        'fecha_inicio_periodo' => 'date',
        'fecha_fin_periodo' => 'date',
        'fecha_generacion' => 'datetime',
        'fecha_aprobacion' => 'datetime',
        'fecha_rechazo' => 'datetime',
        'generado_por_sistema' => 'boolean',
        'es_reporte_parcial' => 'boolean',
        'desglose_ingresos_json' => 'array',
        'desglose_egresos_json' => 'array',
        'top_morosos_json' => 'array',
        'proyeccion_siguiente_mes_json' => 'array',
        'areas_revisar_json' => 'array',
    ];
}
