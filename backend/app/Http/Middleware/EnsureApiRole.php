<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureApiRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }

        if (in_array($user->role?->nombre, $roles, true)) {
            return $next($request);
        }

        return response()->json(['message' => 'No tienes permiso para entrar a esta zona.'], 403);
    }
}
