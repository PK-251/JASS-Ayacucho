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
            grid-template-columns: 292px minmax(0, 1fr);
            background: linear-gradient(180deg, #f5feff 0%, #e9fdff 100%);
        }
        .sidebar {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            background: linear-gradient(180deg, var(--sidebar-top) 0%, #18b7ca 46%, var(--sidebar-bottom) 100%);
            color: #fff;
            box-shadow: 10px 0 36px rgba(0, 113, 132, .12);
        }
        .brand-block {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 24px 22px 22px;
            border-bottom: 1px solid rgba(255,255,255,.18);
        }
        .brand-icon {
            width: 58px;
            height: 58px;
            display: grid;
            place-items: center;
            border-radius: 8px;
            background: rgba(255,255,255,.18);
            box-shadow: inset 0 0 0 1px rgba(255,255,255,.14);
            overflow: hidden;
        }
        .brand-icon img {
            width: 54px;
            height: 40px;
            object-fit: contain;
            filter: drop-shadow(0 2px 3px rgba(0,0,0,.12));
        }
        .brand-title {
            font-size: 1.22rem;
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
            padding: 22px 14px;
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
            min-height: 50px;
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
            padding: 20px 16px;
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
            padding: 28px 34px 42px;
            background: #eaffff;
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
            box-shadow: 0 14px 34px rgba(14, 122, 144, .08);
        }
        .metric-card { min-height: 118px; padding: 22px; }
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
        @media (max-width: 920px) {
            .app-shell { grid-template-columns: 1fr; }
            .sidebar { min-height: auto; }
            .nav-wrap { padding-bottom: 10px; }
            main { padding: 22px 18px 34px; }
            .topbar { align-items: stretch; flex-direction: column; }
        }
    </style>
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
            <div>
                <div class="user-name">{{ auth()->user()?->full_name ?? 'Usuario' }}</div>
                <div class="user-role">{{ auth()->user()?->role?->nombre ?? 'Sistema' }}</div>
            </div>
        </div>
    </aside>
    <main>
        @yield('content')
    </main>
</div>
</body>
</html>
