<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CategoriaIngreso extends Model
{
    protected $table = 'categorias_ingreso';
    protected $guarded = ['id'];
    protected $casts = ['es_manual' => 'boolean', 'activa' => 'boolean'];
}
