<?php

namespace App\Http\Controllers\Api\V1\Concerns;

use Illuminate\Database\QueryException;
use Illuminate\Pagination\LengthAwarePaginator;

trait ApiHelpers
{
    protected function ok(mixed $data = null, string $message = 'OK', int $status = 200): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    protected function created(mixed $data = null, string $message = 'Registrado correctamente.'): \Illuminate\Http\JsonResponse
    {
        return $this->ok($data, $message, 201);
    }

    protected function paginated(LengthAwarePaginator $paginator, string $message = 'OK'): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'message' => $message,
            'data' => $paginator->items(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
            'links' => [
                'first' => $paginator->url(1),
                'last' => $paginator->url($paginator->lastPage()),
                'prev' => $paginator->previousPageUrl(),
                'next' => $paginator->nextPageUrl(),
            ],
        ]);
    }

    protected function money(mixed $value): float
    {
        return round((float) $value, 2);
    }

    protected function procedureError(QueryException $e): string
    {
        $message = $e->getPrevious()?->getMessage() ?: $e->getMessage();

        if (preg_match('/1644\s+(.+)$/', $message, $matches)) {
            return trim($matches[1]);
        }

        if (str_contains(strtolower($message), 'constraint')) {
            return 'No se permiten valores negativos ni montos invalidos.';
        }

        return 'No se pudo completar la operacion en MariaDB. Revisa los datos e intenta nuevamente.';
    }
}
