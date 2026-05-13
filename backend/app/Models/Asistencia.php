<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Asistencia extends Model
{
    protected $table = 'asistencias';
    protected $guarded = ['id'];
    protected $casts = [
        'justificacion_aprobada' => 'boolean',
        'fecha_aprobacion' => 'datetime',
        'fecha_registro' => 'datetime',
        'fecha_ultima_edicion' => 'datetime',
    ];

    public function evento()
    {
        return $this->belongsTo(Evento::class, 'evento_id');
    }

    public function vecino()
    {
        return $this->belongsTo(Vecino::class, 'vecino_id');
    }

    public function multa()
    {
        return $this->belongsTo(MultaAplicada::class, 'multa_aplicada_id');
    }
}
