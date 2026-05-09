<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';

    protected $fillable = [
        'username',
        'nombres',
        'apellidos',
        'email',
        'password',
        'rol_id',
        'estado',
        'intentos_fallidos',
        'bloqueado_hasta',
        'requiere_cambio_password',
        'ultimo_login',
        'created_by',
    ];

    protected $hidden = [
        'password',
    ];

    protected function casts(): array
    {
        return [
            'bloqueado_hasta' => 'datetime',
            'requiere_cambio_password' => 'boolean',
            'ultimo_login' => 'datetime',
            'deleted_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function role()
    {
        return $this->belongsTo(Role::class, 'rol_id');
    }

    public function getFullNameAttribute(): string
    {
        return trim($this->nombres.' '.$this->apellidos);
    }

    public function isAdmin(): bool
    {
        return $this->role?->nombre === 'Administrador';
    }

    public function isOperator(): bool
    {
        return $this->role?->nombre === 'Operador';
    }
}
