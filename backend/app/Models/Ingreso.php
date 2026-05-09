<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ingreso extends Model
{
    protected $table = 'ingresos';
    protected $guarded = ['id'];
    protected $casts = [
        'monto' => 'decimal:2',
        'fecha_ingreso' => 'date',
        'fecha_anulacion' => 'datetime',
        'devolver_dinero' => 'boolean',
        'fecha_ultima_edicion' => 'datetime',
    ];

    public function categoria()
    {
        return $this->belongsTo(CategoriaIngreso::class, 'categoria_id');
    }

    public function vecino()
    {
        return $this->belongsTo(Vecino::class, 'vecino_id');
    }
}
