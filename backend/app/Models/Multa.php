<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Multa extends Model
{
    protected $table = 'multas';
    protected $guarded = ['id'];
    protected $casts = ['monto' => 'decimal:2', 'activa' => 'boolean', 'deleted_at' => 'datetime'];

    public function aplicaciones()
    {
        return $this->hasMany(MultaAplicada::class, 'multa_id');
    }
}
