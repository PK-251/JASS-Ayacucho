<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Evento extends Model
{
    protected $table = 'eventos';
    protected $guarded = ['id'];
    protected $casts = [
        'fecha_evento' => 'date',
        'es_obligatorio' => 'boolean',
        'categorias_convocadas_json' => 'array',
        'notificar_email' => 'boolean',
        'notificar_sms' => 'boolean',
        'fecha_confirmacion' => 'datetime',
        'monto_multas_aplicadas' => 'decimal:2',
        'fecha_cancelacion' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public function tipo()
    {
        return $this->belongsTo(TipoEvento::class, 'tipo_evento_id');
    }

    public function asistencias()
    {
        return $this->hasMany(Asistencia::class, 'evento_id');
    }
}
