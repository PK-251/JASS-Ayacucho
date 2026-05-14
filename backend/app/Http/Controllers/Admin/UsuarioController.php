<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CategoriaServicio;
use App\Models\Vecino;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\RequiredIf;
use Illuminate\View\View;

class UsuarioController extends Controller
{
    public function index(Request $request): View
    {
        $search = trim((string) $request->query('buscar'));

        $usuarios = Vecino::query()
            ->with('categoria')
            ->withSum(['pagosPendientes as deuda_cuotas' => fn ($query) => $query->where('estado', 'pendiente')], 'monto_pendiente')
            ->withSum(['multasAplicadas as deuda_multas' => fn ($query) => $query->where('estado', 'pendiente')], 'monto_aplicado')
            ->whereNull('deleted_at')
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('codigo', 'like', "%{$search}%")
                        ->orWhere('documento_num', 'like', "%{$search}%")
                        ->orWhere('nombres', 'like', "%{$search}%")
                        ->orWhere('apellidos', 'like', "%{$search}%");
                });
            })
            ->orderBy('codigo')
            ->paginate(10)
            ->withQueryString();

        $base = Vecino::whereNull('deleted_at');

        return view('admin.usuarios.index', [
            'usuarios' => $usuarios,
            'buscar' => $search,
            'totalUsuarios' => (clone $base)->count(),
            'activos' => (clone $base)->where('estado', 'activo')->count(),
            'suspendidos' => (clone $base)->where('estado', 'suspendido')->count(),
            'cortados' => (clone $base)->where('estado', 'cortado')->count(),
        ]);
    }

    public function create(): View
    {
        return view('admin.usuarios.create', [
            'categorias' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
            'codigoSugerido' => $this->nextCode(),
            'usuario' => new Vecino(['estado' => 'activo', 'documento_tipo' => 'DNI']),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validatedData($request);
        $data['codigo'] = $this->nextCode();
        $data['created_by'] = auth()->id();
        $data['fecha_registro'] = now()->toDateString();
        $data['tiene_medidor'] = $request->boolean('tiene_medidor');
        $data['numero_medidor'] = $data['tiene_medidor'] ? ($data['numero_medidor'] ?? null) : null;

        Vecino::create($data);

        return redirect()->route('admin.usuarios.index')->with('success', 'Usuario registrado correctamente.');
    }

    public function show(Vecino $usuario): View
    {
        $usuario->load([
            'categoria',
            'cobros' => fn ($query) => $query->latest('fecha_cobro')->limit(8),
            'pagosPendientes' => fn ($query) => $query->where('estado', 'pendiente')->latest('fecha_intento'),
            'multasAplicadas' => fn ($query) => $query->with('multa')->where('estado', 'pendiente')->latest('fecha_aplicacion'),
        ]);

        return view('admin.usuarios.show', ['usuario' => $usuario]);
    }

    public function edit(Vecino $usuario): View
    {
        return view('admin.usuarios.edit', [
            'usuario' => $usuario,
            'categorias' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
        ]);
    }

    public function update(Request $request, Vecino $usuario): RedirectResponse
    {
        $data = $this->validatedData($request, $usuario);
        $data['updated_by'] = auth()->id();
        $data['tiene_medidor'] = $request->boolean('tiene_medidor');
        $data['numero_medidor'] = $data['tiene_medidor'] ? ($data['numero_medidor'] ?? null) : null;

        if ($data['estado'] !== 'cortado') {
            $data['fecha_corte'] = null;
        }

        $usuario->update($data);

        return redirect()->route('admin.usuarios.show', $usuario)->with('success', 'Usuario actualizado correctamente.');
    }

    public function destroy(Request $request, Vecino $usuario): RedirectResponse
    {
        $request->validate([
            'motivo_baja' => ['required', 'string', 'max:500'],
        ]);

        $usuario->forceFill([
            'estado' => 'baja',
            'motivo_estado' => $request->motivo_baja,
            'deleted_by' => auth()->id(),
            'deleted_at' => now(),
        ])->save();

        return redirect()->route('admin.usuarios.index')->with('success', 'Usuario dado de baja correctamente.');
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
