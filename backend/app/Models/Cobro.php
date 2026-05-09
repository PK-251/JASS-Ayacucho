<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cobro extends Model
{
    protected $table = 'cobros';
    protected $guarded = ['id'];
    protected $casts = [
        'monto_cuota' => 'decimal:2',
        'monto_deuda_anterior' => 'decimal:2',
        'monto_multas' => 'decimal:2',
        'monto_total' => 'decimal:2',
        'monto_recibido' => 'decimal:2',
        'fecha_cobro' => 'date',
        'fecha_ultima_edicion' => 'datetime',
        'fecha_anulacion' => 'datetime',
        'devolver_dinero' => 'boolean',
    ];

    public function vecino()
    {
        return $this->belongsTo(Vecino::class, 'vecino_id');
    }

    public function operador()
    {
        return $this->belongsTo(User::class, 'operador_id');
    }

    public function jornada()
    {
        return $this->belongsTo(JornadaCobro::class, 'jornada_id');
    }

    public function comprobante()
    {
        return $this->hasOne(ComprobantePdf::class, 'cobro_id');
    }
}
