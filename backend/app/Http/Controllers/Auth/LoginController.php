<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\LoginLog;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\View\View;

class LoginController extends Controller
{
    public function show(): View
    {
        return view('auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'username' => ['required', 'string', 'max:50'],
            'password' => ['required', 'string'],
        ]);

        $user = User::with('role')
            ->where('username', $credentials['username'])
            ->whereNull('deleted_at')
            ->first();

        if (! $user) {
            $this->logAttempt(null, $credentials['username'], $request, 'fallido_credenciales', 'Usuario no encontrado');
            return back()->withErrors(['username' => 'Usuario o contrasena incorrectos.'])->onlyInput('username');
        }

        if ($user->estado === 'bloqueado' || ($user->bloqueado_hasta && $user->bloqueado_hasta->isFuture())) {
            $this->logAttempt($user, $credentials['username'], $request, 'fallido_bloqueado', 'Cuenta bloqueada temporalmente');
            return back()->withErrors(['username' => 'La cuenta esta bloqueada temporalmente.'])->onlyInput('username');
        }

        if ($user->estado !== 'activo') {
            $this->logAttempt($user, $credentials['username'], $request, 'fallido_credenciales', 'Usuario inactivo');
            return back()->withErrors(['username' => 'La cuenta no esta activa.'])->onlyInput('username');
        }

        if (! Hash::check($credentials['password'], $user->password)) {
            $attempts = min(((int) $user->intentos_fallidos) + 1, 3);
            $user->forceFill([
                'intentos_fallidos' => $attempts,
                'estado' => $attempts >= 3 ? 'bloqueado' : $user->estado,
                'bloqueado_hasta' => $attempts >= 3 ? now()->addMinutes(15) : null,
            ])->save();

            $this->logAttempt($user, $credentials['username'], $request, 'fallido_credenciales', 'Contrasena incorrecta');
            return back()->withErrors(['password' => 'Usuario o contrasena incorrectos.'])->onlyInput('username');
        }

        $user->forceFill([
            'intentos_fallidos' => 0,
            'bloqueado_hasta' => null,
            'ultimo_login' => now(),
        ])->save();

        Auth::login($user, $request->boolean('remember'));
        $request->session()->regenerate();
        $this->logAttempt($user, $credentials['username'], $request, 'exitoso');

        return redirect()->intended($user->isOperator() ? route('operator.dashboard') : route('admin.dashboard'));
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
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
