<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TipoEvento extends Model
{
    protected $table = 'tipos_evento';
    protected $guarded = ['id'];
    protected $casts = [
        'es_obligatorio_default' => 'boolean',
        'genera_multa_default' => 'boolean',
        'activa' => 'boolean',
    ];
}
