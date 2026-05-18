<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name') }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root {
            --sidebar-top: #28c6d7;
            --sidebar-bottom: #0b8ea6;
            --aqua: #12acc2;
            --aqua-deep: #087b91;
            --aqua-soft: #e9fdff;
            --line: #b7edf4;
            --ink: #183247;
            --muted: #74879a;
            --success: #18b981;
            --danger: #ef4444;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            background: #eafcff;
            color: var(--ink);
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        .app-shell {
            min-height: 100vh;
            display: grid;
            grid-template-columns: 280px minmax(0, 1fr);
            background: linear-gradient(180deg, #f7feff 0%, #e6fbff 100%);
        }
        .sidebar {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            background: linear-gradient(180deg, var(--sidebar-top) 0%, #18b7ca 46%, var(--sidebar-bottom) 100%);
            color: #fff;
            box-shadow: 12px 0 34px rgba(0, 113, 132, .13);
        }
        .brand-block {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 26px 20px 24px;
            border-bottom: 1px solid rgba(255,255,255,.18);
        }
        .brand-icon {
            width: 66px;
            height: 66px;
            display: grid;
            place-items: center;
            border-radius: 10px;
            background: rgba(255,255,255,.24);
            box-shadow: inset 0 0 0 1px rgba(255,255,255,.14);
            overflow: hidden;
        }
        .brand-icon img {
            width: 62px;
            height: 46px;
            object-fit: contain;
            filter: drop-shadow(0 2px 3px rgba(0,0,0,.12));
        }
        .brand-title {
            font-size: 1.26rem;
            font-weight: 850;
            letter-spacing: .02em;
            line-height: 1.02;
        }
        .brand-subtitle {
            margin-top: 5px;
            font-size: .88rem;
            color: rgba(255,255,255,.82);
        }
        .nav-wrap {
            padding: 24px 14px 18px;
            flex: 1;
        }
        .nav-section {
            margin: 0 0 9px 6px;
            font-size: .78rem;
            font-weight: 850;
            letter-spacing: .05em;
            color: rgba(255,255,255,.62);
        }
        .nav-link-app {
            display: flex;
            align-items: center;
            gap: 12px;
            min-height: 48px;
            margin: 5px 0;
            padding: 0 16px;
            border-radius: 8px;
            color: rgba(255,255,255,.92);
            text-decoration: none;
            font-weight: 700;
        }
        .nav-link-app:hover,
        .nav-link-app.active {
            color: #fff;
            background: rgba(255,255,255,.22);
        }
        .nav-icon {
            width: 24px;
            height: 24px;
            display: inline-grid;
            place-items: center;
            flex: 0 0 24px;
            color: rgba(255,255,255,.86);
        }
        .nav-icon svg {
            width: 21px;
            height: 21px;
            display: block;
            stroke: currentColor;
            stroke-width: 2.25;
            fill: none;
            stroke-linecap: round;
            stroke-linejoin: round;
        }
        .nav-link-app.active .nav-icon,
        .nav-link-app:hover .nav-icon { color: #fff; }
        .user-card {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 18px 16px;
            border-top: 1px solid rgba(255,255,255,.20);
            background: rgba(4, 122, 143, .20);
        }
        .user-avatar {
            width: 42px;
            height: 42px;
            display: grid;
            place-items: center;
            border-radius: 999px;
            background: rgba(255,255,255,.28);
            color: #fff;
            font-weight: 800;
        }
        .user-name { font-weight: 800; line-height: 1.05; }
        .user-role { font-size: .82rem; color: rgba(255,255,255,.72); }
        main {
            min-width: 0;
            padding: 30px 34px 42px;
            background: linear-gradient(180deg, #eaffff 0%, #f4ffff 100%);
        }
        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 18px;
            margin-bottom: 28px;
        }
        .page-title { font-size: 2rem; font-weight: 850; margin: 0; color: var(--ink); }
        .page-subtitle { color: var(--muted); margin-top: 2px; }
        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 8px 16px;
            border-radius: 999px;
            background: #defbf2;
            color: #087b62;
            font-size: .9rem;
            font-weight: 800;
            border: 1px solid #bff2e1;
        }
        .status-pill::before {
            content: "";
            width: 8px;
            height: 8px;
            border-radius: 999px;
            background: #10b981;
        }
        .metric-card,
        .panel {
            background: rgba(255,255,255,.88);
            border: 1px solid var(--line);
            border-radius: 8px;
            box-shadow: 0 16px 38px rgba(14, 122, 144, .08);
        }
        .metric-card { min-height: 118px; padding: 22px; position: relative; overflow: hidden; }
        .metric-card::after { content: ""; position:absolute; right:14px; top:14px; width:42px; height:42px; border-radius:8px; background:rgba(18,172,194,.10); pointer-events:none; }
        .metric-label { color: #74879a; font-size: .95rem; font-weight: 650; }
        .metric-value { font-size: 2.15rem; font-weight: 850; color: #057e96; line-height: 1.05; margin-top: 8px; }
        .metric-value.success { color: #10b981; }
        .metric-value.danger { color: #ef4444; }
        .badge-soft { background: #dff9f2; color: #07845e; }
        .badge-warning-soft { background: #fff2c2; color: #b77905; }
        .badge-danger-soft { background: #ffe2e2; color: #df3c3c; }
        .table-panel { padding: 18px; }
        .table { --bs-table-bg: transparent; --bs-table-color: var(--ink); margin-bottom: 0; }
        .table thead th {
            background: #effbff;
            color: #0b8ea6;
            font-size: .84rem;
            text-transform: uppercase;
            border-bottom: 1px solid #c4eef5;
        }
        .table tbody td {
            border-color: #d9f2f6;
            vertical-align: middle;
        }
        .series-link { color: #07a8c2; font-weight: 800; text-decoration: none; }
        .btn-aqua {
            background: #087f95;
            color: #fff;
            border: 0;
            border-radius: 7px;
            box-shadow: 0 10px 20px rgba(8,127,149,.18);
        }
        .btn-aqua:hover { background: #066d80; color: #fff; }
        .btn, .form-control, .form-select { border-radius: 7px; }
        .btn-icon { display:inline-flex; align-items:center; justify-content:center; gap:9px; font-weight:800; }
        .action-icon-sm { display:inline-flex; align-items:center; justify-content:center; width:18px; height:18px; flex:0 0 auto; }
        .btn-icon svg, .action-icon svg, .action-icon-sm svg { width:18px; height:18px; stroke:currentColor; stroke-width:2.2; fill:none; stroke-linecap:round; stroke-linejoin:round; }
        .soft-field { background:#f7feff; border:1px solid #b7edf4; }
        .sidebar-logout { border:0; background:transparent; color:rgba(255,255,255,.78); padding:0; font-size:.82rem; text-decoration:none; }
        .sidebar-logout:hover { color:#fff; text-decoration:underline; }

        /* Polish layer: shared screens */
        .content-stack { display:flex; flex-direction:column; gap:24px; }
        .page-actions, .toolbar-actions { display:flex; align-items:center; flex-wrap:wrap; gap:10px; }
        .panel-header { display:flex; align-items:center; justify-content:space-between; gap:14px; padding:18px 18px 0; }
        .panel-title { margin:0; font-size:1.12rem; font-weight:850; color:#173247; }
        .panel-subtitle { color:var(--muted); font-size:.88rem; margin-top:2px; }
        .toolbar { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; padding:14px; background:#f5fdff; border:1px solid #c9f0f6; border-radius:10px; }
        .filter-form { display:flex; flex-wrap:wrap; gap:10px; align-items:center; }
        .filter-form .form-control, .filter-form .form-select { min-height:40px; }
        .search-box { position:relative; min-width:min(340px, 100%); }
        .search-box::before { content:""; position:absolute; left:13px; top:50%; width:15px; height:15px; transform:translateY(-50%); opacity:.55; background:currentColor; color:#0b8ea6; -webkit-mask:url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="none" stroke="black" stroke-width="2" stroke-linecap="round" d="m21 21-4.3-4.3M10.8 18a7.2 7.2 0 1 1 0-14.4 7.2 7.2 0 0 1 0 14.4Z"/></svg>') center/contain no-repeat; mask:url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="none" stroke="black" stroke-width="2" stroke-linecap="round" d="m21 21-4.3-4.3M10.8 18a7.2 7.2 0 1 1 0-14.4 7.2 7.2 0 0 1 0 14.4Z"/></svg>') center/contain no-repeat; }
        .search-box .form-control { padding-left:38px; }
        .action-icon { width:36px; height:36px; display:inline-flex; align-items:center; justify-content:center; border-radius:9px; border:1px solid #bfeaf1; background:#fff; color:#087f95; text-decoration:none; transition:.18s ease; }
        .action-icon:hover { background:#e9fdff; color:#055f70; transform:translateY(-1px); }
        .action-icon.danger { color:#dc2626; border-color:#ffd1d1; }
        .action-icon.danger:hover { background:#fff0f0; }
        .btn-outline-info { --bs-btn-color:#087f95; --bs-btn-border-color:#9fe6ef; --bs-btn-hover-bg:#dffbff; --bs-btn-hover-border-color:#7adce8; --bs-btn-hover-color:#055f70; font-weight:800; }
        .btn-outline-danger { font-weight:800; }
        .btn-sm { font-weight:800; }
        .metric-card { min-height:128px; }
        .metric-card .badge { font-weight:800; border-radius:8px; padding:.42rem .62rem; }
        .metric-card:nth-child(odd)::after { background:rgba(16,185,129,.11); }
        .status-pill { display:inline-flex; align-items:center; gap:8px; border-radius:999px; background:#dff9f2; color:#087b5f; font-weight:850; padding:8px 14px; font-size:.85rem; }
        .status-pill::before { content:""; width:7px; height:7px; border-radius:50%; background:#10b981; box-shadow:0 0 0 4px rgba(16,185,129,.13); }
        .table-panel { overflow:hidden; }
        .table-responsive { border-radius:10px; }
        .table thead th:first-child { border-top-left-radius:8px; }
        .table thead th:last-child { border-top-right-radius:8px; }
        .table tbody tr { transition:background .15s ease; }
        .table tbody tr:hover { background:#f3fdff; }
        .table .badge { border-radius:999px; padding:.36rem .6rem; font-weight:850; }
        .form-control, .form-select { border:1px solid #beeaf1; min-height:42px; }
        .form-control:focus, .form-select:focus { border-color:#15b9cd; box-shadow:0 0 0 .22rem rgba(18,172,194,.13); }
        textarea.form-control { min-height:110px; }
        label, .form-label { color:#24445a; font-weight:800; font-size:.86rem; }
        .modal-content, .dropdown-menu { border:1px solid #c5eef4; border-radius:12px; box-shadow:0 24px 60px rgba(8,127,149,.16); }
        .alert { border-radius:10px; }
        .alert-warning { background:#fff7d8; border-color:#f6d57b; color:#9a6500; }
        .alert-danger { background:#fff0f0; border-color:#ffcaca; color:#b91c1c; }
        .alert-success { background:#e8fbf3; border-color:#bff0dd; color:#047857; }
        .pagination { gap:6px; }
        .page-link { border-radius:8px !important; border-color:#c5eef4; color:#087f95; font-weight:800; }
        .page-item.active .page-link { background:#0b8ea6; border-color:#0b8ea6; }
        .quick-actions { display:flex; flex-wrap:wrap; gap:14px; }
        .quick-actions .btn { min-height:48px; padding-inline:24px; }
        .empty-state { border:1px dashed #aee8f0; border-radius:12px; background:#f7feff; padding:28px; text-align:center; color:#6d8496; }
        .detail-card { border:1px solid #d3f0f5; border-radius:12px; background:#fff; padding:16px; }
        .detail-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(190px, 1fr)); gap:12px; }
        .avatar-mini { width:46px; height:46px; border-radius:50%; display:inline-grid; place-items:center; background:#b7eff7; color:#087f95; font-weight:900; flex:0 0 auto; }
        .brand-block .brand-copy strong { letter-spacing:.04em; }
        .sidebar .nav-link-app.active { box-shadow: inset 4px 0 0 rgba(255,255,255,.85); }
        .sidebar .nav-link-app svg { opacity:.95; }
        .user-card { background:rgba(0,92,111,.18); border-top:1px solid rgba(255,255,255,.16); }
        .user-card .avatar { box-shadow:0 8px 18px rgba(0,70,90,.16); }
        @media (max-width: 680px) {
            .page-actions, .toolbar-actions, .filter-form, .quick-actions { width:100%; }
            .page-actions .btn, .toolbar-actions .btn, .quick-actions .btn { width:100%; justify-content:center; }
            .metric-value { font-size:1.85rem; }
            .panel-header { align-items:flex-start; flex-direction:column; }
            .toolbar { align-items:stretch; }
            .filter-form .form-control, .filter-form .form-select, .search-box { width:100%; min-width:0; }
        }


        /* Polish layer: internal forms and details */
        .form-card { position:relative; overflow:hidden; }
        .form-card::before { content:""; position:absolute; right:22px; top:18px; width:150px; height:110px; background:url("{{ asset('assets/logo-water.svg') }}") center/contain no-repeat; opacity:.035; pointer-events:none; }
        .form-card > * { position:relative; z-index:1; }
        .form-card .alert { margin-bottom:22px; }
        .form-actions { display:flex; justify-content:flex-end; flex-wrap:wrap; gap:10px; margin-top:24px; padding-top:18px; border-top:1px solid #d8f3f7; }
        .form-actions .btn { min-width:150px; }
        .form-check-input { border-color:#91dfe9; }
        .form-check-input:checked { background-color:#0b8ea6; border-color:#0b8ea6; }
        .detail-hero { display:flex; justify-content:space-between; align-items:flex-start; gap:18px; flex-wrap:wrap; }
        .detail-hero .metric-value { margin-top:2px; }
        .info-list { display:grid; gap:10px; }
        .info-list .info-row { display:flex; justify-content:space-between; gap:14px; padding:10px 0; border-bottom:1px solid #e3f5f8; }
        .info-list .info-row:last-child { border-bottom:0; }
        .info-list span { color:#6d8496; }
        .info-list strong { color:#173247; text-align:right; }
        .picker-item { display:block; border:1px solid #d3f0f5; background:#fff; border-radius:12px; padding:14px; color:inherit; text-decoration:none; transition:.18s ease; }
        .picker-item:hover, .picker-item.active { border-color:#14b8cf; background:#edfcff; transform:translateY(-1px); box-shadow:0 12px 24px rgba(8,127,149,.10); }
        .success-mark { width:74px; height:74px; border-radius:999px; background:#dff9f2; color:#087b62; display:grid; place-items:center; font-size:2.2rem; font-weight:900; }
        .sticky-bottom-action { position:sticky; bottom:0; z-index:5; margin:24px -18px -18px; padding:16px 18px; background:rgba(247,254,255,.94); border-top:1px solid #c5eef4; backdrop-filter:blur(10px); }
        @media (max-width: 680px) { .form-actions .btn { width:100%; } .detail-hero { align-items:stretch; } .detail-hero .text-end { text-align:left !important; } }

        @media (max-width: 920px) {
            .app-shell { grid-template-columns: 1fr; }
            .sidebar { min-height: auto; }
            .nav-wrap { padding-bottom: 10px; }
            main { padding: 22px 18px 34px; }
            .topbar { align-items: stretch; flex-direction: column; }
        }
    </style>
    @stack('styles')
</head>
<body>
<div class="app-shell">
    <aside class="sidebar">
        <div class="brand-block">
            <div class="brand-icon">
                <img src="{{ asset('assets/logo-water.svg') }}" alt="Logo J.A.S.S. Quilcata">
            </div>
            <div>
                <div class="brand-title">J.A.S.S. QUILCATA</div>
                <div class="brand-subtitle">Sara-Sara, Ayacucho</div>
            </div>
        </div>

        <nav class="nav-wrap">
            @yield('nav')
        </nav>

        <div class="user-card">
            <div class="user-avatar">{{ strtoupper(substr(auth()->user()?->nombres ?? 'U', 0, 1).substr(auth()->user()?->apellidos ?? 'S', 0, 1)) }}</div>
            <div class="flex-grow-1">
                <div class="user-name">{{ auth()->user()?->full_name ?? 'Usuario' }}</div>
                <div class="user-role">{{ auth()->user()?->role?->nombre ?? 'Sistema' }}</div>
                <form method="POST" action="{{ route('logout') }}" class="mt-1">
                    @csrf
                    <button class="sidebar-logout" type="submit">Cerrar sesion</button>
                </form>
            </div>
        </div>
    </aside>
    <main>
        @yield('content')
    </main>
</div>
</body>
</html>
