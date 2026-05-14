@php($active = $active ?? '')
<div class="nav-section">OPERADOR</div>
<a class="nav-link-app {{ $active === 'inicio' ? 'active' : '' }}" href="{{ route('operator.dashboard') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="m3 10 9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/></svg></span>Inicio
</a>
<a class="nav-link-app {{ $active === 'cobros' ? 'active' : '' }}" href="{{ route('operator.cobros.index') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M19 7V5a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5"/><path d="M16 13h.01"/></svg></span>Cobros
</a>
<a class="nav-link-app {{ $active === 'asistencia' ? 'active' : '' }}" href="{{ route('operator.asistencia.index') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg></span>Asistencia
</a>
