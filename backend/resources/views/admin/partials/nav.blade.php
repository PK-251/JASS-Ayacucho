@php($active = $active ?? '')
<div class="nav-section">PRINCIPAL</div>
<a class="nav-link-app {{ $active === 'inicio' ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="m3 10 9-7 9 7"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/></svg></span>Inicio
</a>

<div class="nav-section mt-4">GESTION</div>
<a class="nav-link-app {{ $active === 'usuarios' ? 'active' : '' }}" href="{{ route('admin.usuarios.index') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span>Padron de Usuarios
</a>
<a class="nav-link-app {{ $active === 'cobros' ? 'active' : '' }}" href="{{ route('admin.cobros.index') }}">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M19 7V5a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5"/><path d="M16 13h.01"/></svg></span>Cobros
</a>
<a class="nav-link-app {{ $active === 'ingresos' ? 'active' : '' }}" href="#">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/></svg></span>Ingresos
</a>
<a class="nav-link-app {{ $active === 'egresos' ? 'active' : '' }}" href="#">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M8 8h8"/><path d="M8 12h8"/><path d="M8 16h5"/></svg></span>Egresos
</a>

<div class="nav-section mt-4">ADMINISTRACION</div>
<a class="nav-link-app {{ $active === 'multas' ? 'active' : '' }}" href="#">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="m14 13-7.5 7.5a2.1 2.1 0 0 1-3-3L11 10"/><path d="m16 16 6-6"/><path d="m8 8 6-6"/><path d="m9 7 8 8"/><path d="m13 3 8 8"/></svg></span>Multas y Tarifas
</a>
<a class="nav-link-app {{ $active === 'reportes' ? 'active' : '' }}" href="#">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M3 3v18h18"/><path d="M7 16v-5"/><path d="M12 16V7"/><path d="M17 16v-3"/></svg></span>Reportes
</a>
<a class="nav-link-app {{ $active === 'asistencia' ? 'active' : '' }}" href="#">
    <span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/></svg></span>Control de Asistencia
</a>
