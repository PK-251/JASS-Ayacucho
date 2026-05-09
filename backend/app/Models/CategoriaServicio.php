<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CategoriaServicio extends Model
{
    protected $table = 'categorias_servicio';
    protected $guarded = ['id'];
    protected $casts = ['activa' => 'boolean'];

    public function vecinos()
    {
        return $this->hasMany(Vecino::class, 'categoria_id');
    }

    public function tarifas()
    {
        return $this->hasMany(Tarifa::class, 'categoria_id');
    }
}
