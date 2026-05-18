<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Api\V1\Concerns\ApiHelpers;
use App\Http\Controllers\Controller;
use App\Models\CategoriaEgreso;
use App\Models\CategoriaIngreso;
use App\Models\CategoriaServicio;
use App\Models\Multa;
use App\Models\Proveedor;
use App\Models\Tarifa;
use App\Models\TipoEvento;

class CatalogController extends Controller
{
    use ApiHelpers;

    public function index()
    {
        return $this->ok([
            'categorias_servicio' => CategoriaServicio::where('activa', true)->orderBy('nombre')->get(),
            'categorias_ingreso' => CategoriaIngreso::where('activa', true)->orderBy('nombre')->get(),
            'categorias_egreso' => CategoriaEgreso::where('activa', true)->orderBy('nombre')->get(),
            'proveedores' => Proveedor::where('activo', true)->whereNull('deleted_at')->orderBy('nombre')->get(),
            'tipos_evento' => TipoEvento::where('activa', true)->orderBy('nombre')->get(),
            'multas' => Multa::whereNull('deleted_at')->orderBy('codigo')->get(),
            'tarifas_vigentes' => Tarifa::with('categoria')->where('activa', true)->orderBy('categoria_id')->get(),
        ]);
    }
}
