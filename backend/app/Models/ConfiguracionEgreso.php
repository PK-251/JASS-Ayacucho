<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConfiguracionEgreso extends Model
{
    protected $table = 'configuracion_egresos';
    protected $primaryKey = 'clave';
    public $incrementing = false;
    protected $keyType = 'string';
    protected $guarded = ['clave'];
}
