<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MultaAplicada extends Model
{
    protected $table = 'multas_aplicadas';
    protected $guarded = ['id'];
    protected $casts = [
        'monto_aplicado' => 'decimal:2',
        'fecha_aplicacion' => 'date',
        'fecha_cobro' => 'date',
        'fecha_anulacion' => 'datetime',
    ];

    public function vecino()
    {
        return $this->belongsTo(Vecino::class, 'vecino_id');
    }

    public function multa()
    {
        return $this->belongsTo(Multa::class, 'multa_id');
    }

    public function cobro()
    {
        return $this->belongsTo(Cobro::class, 'cobro_id');
    }

    public function evento()
    {
        return $this->belongsTo(Evento::class, 'evento_id');
    }
}
