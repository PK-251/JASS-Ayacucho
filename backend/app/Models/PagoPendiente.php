<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PagoPendiente extends Model
{
    protected $table = 'pagos_pendientes';
    protected $guarded = ['id'];
    protected $casts = [
        'monto_pendiente' => 'decimal:2',
        'fecha_intento' => 'date',
        'fecha_cobro' => 'date',
    ];

    public function vecino()
    {
        return $this->belongsTo(Vecino::class, 'vecino_id');
    }
}
