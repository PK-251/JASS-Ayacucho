<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Proveedor extends Model
{
    protected $table = 'proveedores';
    protected $guarded = ['id'];
    protected $casts = ['activo' => 'boolean', 'deleted_at' => 'datetime'];
}
