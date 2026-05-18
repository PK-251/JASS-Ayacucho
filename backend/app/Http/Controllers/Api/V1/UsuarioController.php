<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\CategoriaServicio;
use App\Models\Vecino;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\RequiredIf;

class UsuarioController extends Controller
{
    use ApiHelpers;

    public function index(Request $request)
    {
        $buscar = trim((string) $request->query('buscar'));
        $estado = (string) $request->query('estado', '');

        $usuarios = Vecino::query()
            ->with('categoria')
            ->withSum(['pagosPendientes as deuda_cuotas' => fn ($q) => $q->where('estado', 'pendiente')], 'monto_pendiente')
            ->withSum(['multasAplicadas as deuda_multas' => fn ($q) => $q->where('estado', 'pendiente')], 'monto_aplicado')
            ->whereNull('deleted_at')
            ->when($estado !== '', fn ($q) => $q->where('estado', $estado))
            ->when($buscar !== '', function ($q) use ($buscar) {
                $q->where(function ($inner) use ($buscar) {
                    $inner->where('codigo', 'like', "%{$buscar}%")
                        ->orWhere('documento_num', 'like', "%{$buscar}%")
                        ->orWhere('nombres', 'like', "%{$buscar}%")
                        ->orWhere('apellidos', 'like', "%{$buscar}%");
                });
            })
            ->orderBy('codigo')
            ->paginate((int) $request->query('per_page', 10));

        return $this->paginated($usuarios);
    }

    public function store(Request $request)
    {
        $data = $this->validatedData($request);
        $data['codigo'] = $this->nextCode();
        $data['created_by'] = $request->user()->id;
        $data['fecha_registro'] = now()->toDateString();
        $data['tiene_medidor'] = $request->boolean('tiene_medidor');
        $data['numero_medidor'] = $data['tiene_medidor'] ? ($data['numero_medidor'] ?? null) : null;

        $usuario = Vecino::create($data)->load('categoria');

        return $this->created($usuario, 'Usuario registrado correctamente.');
    }

    public function show(Vecino $usuario)
    {
        abort_if($usuario->deleted_at, 404);

        return $this->ok($usuario->load([
            'categoria',
            'cobros' => fn ($q) => $q->latest('fecha_cobro')->limit(8),
            'pagosPendientes' => fn ($q) => $q->where('estado', 'pendiente')->latest('fecha_intento'),
            'multasAplicadas' => fn ($q) => $q->with('multa')->where('estado', 'pendiente')->latest('fecha_aplicacion'),
        ]));
    }

    public function update(Request $request, Vecino $usuario)
    {
        abort_if($usuario->deleted_at, 404);
        $data = $this->validatedData($request, $usuario);
        $data['updated_by'] = $request->user()->id;
        $data['tiene_medidor'] = $request->boolean('tiene_medidor');
        $data['numero_medidor'] = $data['tiene_medidor'] ? ($data['numero_medidor'] ?? null) : null;

        if ($data['estado'] !== 'cortado') {
            $data['fecha_corte'] = null;
        }

        $usuario->update($data);

        return $this->ok($usuario->fresh('categoria'), 'Usuario actualizado correctamente.');
    }

    public function destroy(Request $request, Vecino $usuario)
    {
        abort_if($usuario->deleted_at, 404);
        $data = $request->validate(['motivo_baja' => ['required', 'string', 'max:500']]);

        $usuario->forceFill([
            'estado' => 'baja',
            'motivo_estado' => $data['motivo_baja'],
            'deleted_by' => $request->user()->id,
            'deleted_at' => now(),
        ])->save();

        return $this->ok(null, 'Usuario dado de baja correctamente.');
    }

    public function deuda(Request $request, Vecino $usuario)
    {
        $anio = (int) $request->query('anio', now()->year);
        $mes = (int) $request->query('mes', now()->month);
        $row = DB::selectOne('CALL sp_calcular_deuda_vecino(?, ?, ?)', [$usuario->id, $anio, $mes]);

        return $this->ok($row);
    }

    public function categorias()
    {
        return $this->ok(CategoriaServicio::where('activa', true)->orderBy('nombre')->get());
    }

    private function validatedData(Request $request, ?Vecino $usuario = null): array
    {
        $id = $usuario?->id;

        return $request->validate([
            'documento_tipo' => ['required', Rule::in(['DNI', 'RUC', 'CE'])],
            'documento_num' => ['required', 'string', 'max:11', Rule::unique('vecinos', 'documento_num')->ignore($id)],
            'nombres' => ['required', 'string', 'max:100'],
            'apellidos' => ['required', 'string', 'max:100'],
            'direccion' => ['required', 'string', 'max:255'],
            'telefono' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:150'],
            'categoria_id' => ['required', 'exists:categorias_servicio,id'],
            'estado' => ['required', Rule::in(['activo', 'suspendido', 'cortado'])],
            'tiene_medidor' => ['nullable', 'boolean'],
            'numero_medidor' => ['nullable', 'string', 'max:30', Rule::unique('vecinos', 'numero_medidor')->ignore($id)],
            'fecha_corte' => [new RequiredIf($request->input('estado') === 'cortado'), 'nullable', 'date'],
            'motivo_estado' => ['nullable', 'string', 'max:500'],
        ]);
    }

    private function nextCode(): string
    {
        $next = (int) DB::table('vecinos')
            ->selectRaw("COALESCE(MAX(CAST(SUBSTRING(codigo, 3) AS UNSIGNED)), 0) + 1 AS next_code")
            ->value('next_code');

        return 'U-'.str_pad((string) $next, 4, '0', STR_PAD_LEFT);
    }
}
