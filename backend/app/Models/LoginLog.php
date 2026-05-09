<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoginLog extends Model
{
    protected $table = 'login_logs';
    public $timestamps = false;
    protected $guarded = ['id'];
    protected $casts = ['fecha_intento' => 'datetime'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
