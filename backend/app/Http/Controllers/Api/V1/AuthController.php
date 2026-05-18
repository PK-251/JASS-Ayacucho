<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\LoginLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    use ApiHelpers;

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'username' => ['required', 'string', 'max:50'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:80'],
        ]);

        $user = User::with('role')
            ->where('username', $credentials['username'])
            ->whereNull('deleted_at')
            ->first();

        if (! $user) {
            $this->logAttempt(null, $credentials['username'], $request, 'fallido_credenciales', 'Usuario no encontrado');
            return response()->json(['message' => 'Usuario o contrasena incorrectos.'], 422);
        }

        if ($user->estado === 'bloqueado' || ($user->bloqueado_hasta && $user->bloqueado_hasta->isFuture())) {
            $this->logAttempt($user, $credentials['username'], $request, 'fallido_bloqueado', 'Cuenta bloqueada temporalmente');
            return response()->json(['message' => 'La cuenta esta bloqueada temporalmente.'], 423);
        }

        if ($user->estado !== 'activo') {
            $this->logAttempt($user, $credentials['username'], $request, 'fallido_credenciales', 'Usuario inactivo');
            return response()->json(['message' => 'La cuenta no esta activa.'], 403);
        }

        if (! Hash::check($credentials['password'], $user->password)) {
            $attempts = min(((int) $user->intentos_fallidos) + 1, 3);
            $user->forceFill([
                'intentos_fallidos' => $attempts,
                'estado' => $attempts >= 3 ? 'bloqueado' : $user->estado,
                'bloqueado_hasta' => $attempts >= 3 ? now()->addMinutes(15) : null,
            ])->save();

            $this->logAttempt($user, $credentials['username'], $request, 'fallido_credenciales', 'Contrasena incorrecta');
            return response()->json(['message' => 'Usuario o contrasena incorrectos.'], 422);
        }

        $user->forceFill([
            'intentos_fallidos' => 0,
            'bloqueado_hasta' => null,
            'ultimo_login' => now(),
        ])->save();

        $ability = $user->isAdmin() ? 'role:Administrador' : 'role:Operador';
        $token = $user->createToken($credentials['device_name'] ?? 'api-token', [$ability])->plainTextToken;
        $this->logAttempt($user, $credentials['username'], $request, 'exitoso');

        return $this->ok([
            'token_type' => 'Bearer',
            'access_token' => $token,
            'user' => $this->userPayload($user->fresh('role')),
        ], 'Acceso correcto.');
    }

    public function me(Request $request)
    {
        return $this->ok($this->userPayload($request->user()->load('role')));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->ok(null, 'Sesion API cerrada correctamente.');
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'username' => $user->username,
            'nombres' => $user->nombres,
            'apellidos' => $user->apellidos,
            'nombre_completo' => $user->full_name,
            'email' => $user->email,
            'estado' => $user->estado,
            'rol' => $user->role?->nombre,
            'home' => $user->isOperator() ? '/operador/inicio' : '/admin/inicio',
            'requiere_cambio_password' => $user->requiere_cambio_password,
        ];
    }

    private function logAttempt(?User $user, string $username, Request $request, string $result, ?string $reason = null): void
    {
        LoginLog::create([
            'user_id' => $user?->id,
            'username_intentado' => $username,
            'ip_address' => $request->ip() ?? '127.0.0.1',
            'user_agent' => (string) $request->userAgent(),
            'resultado' => $result,
            'motivo_fallo' => $reason,
        ]);
    }
}
