<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return redirect()->route('login');
        }

        if (in_array($user->role?->nombre, $roles, true)) {
            return $next($request);
        }

        if ($user->isAdmin()) {
            return redirect()
                ->route('admin.dashboard')
                ->with('warning', 'Entraste a una zona de operador. Te llevamos al panel de administrador.');
        }

        if ($user->isOperator()) {
            return redirect()
                ->route('operator.dashboard')
                ->with('warning', 'Entraste a una zona de administrador. Te llevamos al panel de operador.');
        }

        return redirect()->route('login');
    }
}
