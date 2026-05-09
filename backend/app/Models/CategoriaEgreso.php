<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CategoriaEgreso extends Model
{
    protected $table = 'categorias_egreso';
    protected $guarded = ['id'];
    protected $casts = ['activa' => 'boolean'];
}
