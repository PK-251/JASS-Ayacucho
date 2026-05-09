<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ComprobantePdf extends Model
{
    protected $table = 'comprobantes_pdf';
    protected $guarded = ['id'];
    protected $casts = [
        'fecha_generacion' => 'datetime',
        'fecha_entrega' => 'datetime',
        'enviado_email' => 'boolean',
        'fecha_envio_email' => 'datetime',
        'impreso' => 'boolean',
        'fecha_impresion' => 'datetime',
    ];

    public function cobro()
    {
        return $this->belongsTo(Cobro::class, 'cobro_id');
    }
}
