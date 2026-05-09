<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vecino extends Model
{
    protected $table = 'vecinos';
    protected $guarded = ['id'];
    protected $casts = [
        'tiene_medidor' => 'boolean',
        'fecha_registro' => 'date',
        'fecha_corte' => 'date',
        'deleted_at' => 'datetime',
    ];

    public function categoria()
    {
        return $this->belongsTo(CategoriaServicio::class, 'categoria_id');
    }

    public function cobros()
    {
        return $this->hasMany(Cobro::class, 'vecino_id');
    }

    public function multasAplicadas()
    {
        return $this->hasMany(MultaAplicada::class, 'vecino_id');
    }

    public function pagosPendientes()
    {
        return $this->hasMany(PagoPendiente::class, 'vecino_id');
    }

    public function getFullNameAttribute(): string
    {
        return trim($this->nombres.' '.$this->apellidos);
    }
}
