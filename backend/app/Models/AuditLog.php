<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    protected $table = 'audit_logs';
    public $timestamps = false;
    protected $guarded = ['id'];
    protected $casts = [
        'datos_anteriores_json' => 'array',
        'datos_nuevos_json' => 'array',
        'campos_modificados' => 'array',
        'timestamp' => 'datetime',
    ];
}
