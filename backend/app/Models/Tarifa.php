<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tarifa extends Model
{
    protected $table = 'tarifas';
    protected $guarded = ['id'];
    protected $casts = [
        'monto' => 'decimal:2',
        'activa' => 'boolean',
        'fecha_vigencia_inicio' => 'date',
        'fecha_vigencia_fin' => 'date',
    ];

    public function categoria()
    {
        return $this->belongsTo(CategoriaServicio::class, 'categoria_id');
    }
}
