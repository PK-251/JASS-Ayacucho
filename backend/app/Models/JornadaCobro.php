<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JornadaCobro extends Model
{
    protected $table = 'jornadas_cobro';
    protected $guarded = ['id'];
    protected $casts = [
        'fecha_inicio' => 'datetime',
        'fecha_cierre' => 'datetime',
        'total_recaudado' => 'decimal:2',
    ];

    public function operador()
    {
        return $this->belongsTo(User::class, 'operador_id');
    }

    public function cobros()
    {
        return $this->hasMany(Cobro::class, 'jornada_id');
    }
}
