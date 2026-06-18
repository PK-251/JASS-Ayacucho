<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\CategoriaServicio;
use App\Models\Multa;
use App\Models\Tarifa;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MultaTarifaController extends Controller
{
    use ApiHelpers;

    public function index()
    {
        return $this->ok([
            'tarifas_vigentes' => Tarifa::with('categoria')->where('activa', true)->orderBy('categoria_id')->get(),
            'historial_tarifas' => Tarifa::with('categoria')->latest('fecha_vigencia_inicio')->limit(12)->get(),
            'multas' => Multa::whereNull('deleted_at')->orderBy('codigo')->get(),
            'categorias_servicio' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
        ]);
    }

    public function storeMulta(Request $request)
    {
        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:100'],
            'descripcion' => ['nullable', 'string', 'max:500'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'tipo_aplicacion' => ['required', Rule::in(['automatica_mensual', 'manual', 'semi_automatica'])],
            'condicion_aplicacion' => ['nullable', 'string', 'max:500'],
            'activa' => ['nullable', 'boolean'],
        ]);
        $multa = Multa::create([
            ...$data,
            'codigo' => $this->nextMultaCode(),
            'activa' => (bool) ($data['activa'] ?? true),
            'created_by' => $request->user()->id,
        ]);

        Cache::forget(CatalogController::CACHE_KEY);

        return $this->created($multa, 'Multa creada correctamente.');
    }

    public function updateMulta(Request $request, Multa $multa)
    {
        $data = $request->validate([
            'nombre' => ['required', 'string', 'max:100'],
            'descripcion' => ['nullable', 'string', 'max:500'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'tipo_aplicacion' => ['required', Rule::in(['automatica_mensual', 'manual', 'semi_automatica'])],
            'condicion_aplicacion' => ['nullable', 'string', 'max:500'],
            'activa' => ['nullable', 'boolean'],
        ]);
        $multa->update([...$data, 'activa' => (bool) ($data['activa'] ?? false), 'updated_by' => $request->user()->id]);

        Cache::forget(CatalogController::CACHE_KEY);

        return $this->ok($multa->fresh(), 'Multa actualizada correctamente.');
    }

    public function destroyMulta(Request $request, Multa $multa)
    {
        $multa->update(['activa' => false, 'updated_by' => $request->user()->id, 'deleted_at' => now()]);

        Cache::forget(CatalogController::CACHE_KEY);

        return $this->ok(null, 'Multa desactivada correctamente.');
    }

    public function storeTarifa(Request $request)
    {
        $data = $request->validate([
            'categoria_id' => ['required', 'exists:categorias_servicio,id'],
            'monto' => ['required', 'numeric', 'min:0.01'],
            'fecha_vigencia_inicio' => ['required', 'date'],
            'motivo_cambio' => ['required', 'string', 'max:500'],
        ]);
        DB::transaction(function () use ($data, $request) {
            Tarifa::where('categoria_id', $data['categoria_id'])->where('activa', true)->update([
                'activa' => false,
                'fecha_vigencia_fin' => date('Y-m-d', strtotime($data['fecha_vigencia_inicio'].' -1 day')),
                'updated_by' => $request->user()->id,
            ]);
            Tarifa::create([...$data, 'activa' => true, 'created_by' => $request->user()->id]);
        });

        Cache::forget(CatalogController::CACHE_KEY);

        return $this->created(Tarifa::with('categoria')->where('categoria_id', $data['categoria_id'])->where('activa', true)->first(), 'Tarifa actualizada correctamente.');
    }

    private function nextMultaCode(): string
    {
        $lastNumber = (int) DB::table('multas')->selectRaw("COALESCE(MAX(CAST(SUBSTRING(codigo, 3) AS UNSIGNED)), 0) AS last_number")->value('last_number');
        return 'M-'.str_pad((string) ($lastNumber + 1), 2, '0', STR_PAD_LEFT);
    }
}
