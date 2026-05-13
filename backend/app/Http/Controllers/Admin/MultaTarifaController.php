<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CategoriaServicio;
use App\Models\Multa;
use App\Models\Tarifa;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class MultaTarifaController extends Controller
{
    public function index(): View
    {
        $tarifasVigentes = Tarifa::with('categoria')
            ->where('activa', true)
            ->whereNull('fecha_vigencia_fin')
            ->orderBy('categoria_id')
            ->get();

        return view('admin.multas.index', [
            'tarifasVigentes' => $tarifasVigentes,
            'historialTarifas' => Tarifa::with('categoria')->orderByDesc('fecha_vigencia_inicio')->limit(8)->get(),
            'multas' => Multa::withCount(['aplicaciones as aplicadas_count'])
                ->whereNull('deleted_at')
                ->orderBy('codigo')
                ->get(),
            'categorias' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
            'tarifasActivas' => $tarifasVigentes->count(),
            'multasActivas' => Multa::where('activa', true)->whereNull('deleted_at')->count(),
            'multasInactivas' => Multa::where('activa', false)->whereNull('deleted_at')->count(),
            'multasAplicadas' => DB::table('multas_aplicadas')->whereIn('estado', ['pendiente', 'cobrada'])->count(),
        ]);
    }

    public function createMulta(): View
    {
        return view('admin.multas.create-multa', [
            'multa' => new Multa(['activa' => true, 'tipo_aplicacion' => 'manual']),
            'codigoSugerido' => $this->nextMultaCode(),
            'editing' => false,
        ]);
    }

    public function storeMulta(Request $request): RedirectResponse
    {
        $data = $this->validatedMulta($request);
        $multa = Multa::create([
            ...$data,
            'codigo' => $this->nextMultaCode(),
            'activa' => $request->boolean('activa'),
            'created_by' => auth()->id(),
        ]);

        return redirect()->route('admin.multas.index')->with('success', 'Multa '.$multa->codigo.' creada correctamente.');
    }

    public function editMulta(Multa $multa): View
    {
        return view('admin.multas.edit-multa', [
            'multa' => $multa,
            'editing' => true,
        ]);
    }

    public function updateMulta(Request $request, Multa $multa): RedirectResponse
    {
        $data = $this->validatedMulta($request);
        $multa->update([
            ...$data,
            'activa' => $request->boolean('activa'),
            'updated_by' => auth()->id(),
        ]);

        return redirect()->route('admin.multas.index')->with('success', 'Multa actualizada correctamente.');
    }

    public function destroyMulta(Request $request, Multa $multa): RedirectResponse
    {
        $request->validate(['motivo' => ['nullable', 'string', 'max:500']]);

        $multa->update([
            'activa' => false,
            'updated_by' => auth()->id(),
            'deleted_at' => now(),
        ]);

        return redirect()->route('admin.multas.index')->with('success', 'Multa desactivada correctamente.');
    }

    public function createTarifa(): View
    {
        return view('admin.multas.create-tarifa', [
            'categorias' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
            'vigentes' => Tarifa::where('activa', true)->whereNull('fecha_vigencia_fin')->pluck('monto', 'categoria_id'),
        ]);
    }

    public function storeTarifa(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'categoria_id' => ['required', 'exists:categorias_servicio,id'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'fecha_vigencia_inicio' => ['required', 'date'],
            'motivo_cambio' => ['required', 'string', 'max:500'],
            'descripcion' => ['nullable', 'string', 'max:500'],
        ]);

        DB::transaction(function () use ($data) {
            Tarifa::where('categoria_id', $data['categoria_id'])
                ->where('activa', true)
                ->whereNull('fecha_vigencia_fin')
                ->update([
                    'activa' => false,
                    'fecha_vigencia_fin' => date('Y-m-d', strtotime($data['fecha_vigencia_inicio'].' -1 day')),
                    'updated_by' => auth()->id(),
                ]);

            Tarifa::create([
                ...$data,
                'activa' => true,
                'fecha_vigencia_fin' => null,
                'created_by' => auth()->id(),
            ]);
        });

        return redirect()->route('admin.multas.index')->with('success', 'Tarifa actualizada correctamente.');
    }

    private function validatedMulta(Request $request): array
    {
        return $request->validate([
            'nombre' => ['required', 'string', 'max:100'],
            'descripcion' => ['nullable', 'string', 'max:500'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'tipo_aplicacion' => ['required', Rule::in(['automatica_mensual', 'manual', 'semi_automatica'])],
            'condicion_aplicacion' => ['nullable', 'string', 'max:500'],
        ]);
    }

    private function nextMultaCode(): string
    {
        $lastNumber = (int) DB::table('multas')
            ->selectRaw("COALESCE(MAX(CAST(SUBSTRING(codigo, 3) AS UNSIGNED)), 0) AS last_number")
            ->value('last_number');

        return 'M-'.str_pad((string) ($lastNumber + 1), 2, '0', STR_PAD_LEFT);
    }
}
