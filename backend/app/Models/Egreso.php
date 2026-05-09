<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Egreso extends Model
{
    protected $table = 'egresos';
    protected $guarded = ['id'];
    protected $casts = [
        'monto' => 'decimal:2',
        'fecha_egreso' => 'date',
        'requiere_aprobacion' => 'boolean',
        'fecha_aprobacion' => 'datetime',
        'fecha_rechazo' => 'datetime',
        'fecha_anulacion' => 'datetime',
        'devolver_dinero' => 'boolean',
        'fecha_ultima_edicion' => 'datetime',
    ];

    public function categoria()
    {
        return $this->belongsTo(CategoriaEgreso::class, 'categoria_id');
    }

    public function proveedor()
    {
        return $this->belongsTo(Proveedor::class, 'proveedor_id');
    }
}
