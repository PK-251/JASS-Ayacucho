<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Acceso - {{ config('app.name') }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        :root { --aqua: #16bfd0; --aqua-dark: #087b91; --ink: #123047; --muted: #6e8294; }
        * { box-sizing: border-box; }
        body { min-height: 100vh; margin: 0; background: #f4f8fb; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--ink); }
        .login-wrap { min-height: 100vh; display: grid; grid-template-columns: minmax(380px, 1.06fr) minmax(420px, .94fr); }
        .login-brand { position: relative; overflow: hidden; background: linear-gradient(155deg, #20c7d7 0%, #0e899c 52%, #087185 100%); color: white; display: flex; align-items: center; justify-content: center; padding: 56px; }
        .login-brand::before { content: ""; position: absolute; inset: 0; background-image: radial-gradient(circle at 18px 18px, rgba(255,255,255,.14) 1px, transparent 1.5px); background-size: 30px 30px; opacity: .45; }
        .brand-content { position: relative; width: min(560px, 100%); text-align: center; }
        .logo-stage { width: min(360px, 78%); margin: 0 auto 34px; padding: 22px 28px; border-radius: 8px; background: rgba(255,255,255,.92); box-shadow: 0 22px 60px rgba(3, 64, 77, .28); }
        .logo-stage img { display: block; width: 100%; height: auto; }
        .brand-title { font-size: clamp(2rem, 4vw, 3.05rem); font-weight: 850; line-height: 1.05; }
        .brand-subtitle { font-size: 1.18rem; margin-top: 10px; }
        .brand-note { color: rgba(255,255,255,.82); margin-top: 16px; }
        .login-panel { background: linear-gradient(180deg, #fbfdff 0%, #eef6fa 100%); display: flex; align-items: center; justify-content: center; padding: 48px 32px; }
        .login-card { max-width: 410px; width: 100%; background: rgba(255,255,255,.92); border: 1px solid #bdebf2; border-radius: 8px; padding: 34px; box-shadow: 0 24px 70px rgba(23, 72, 91, .14); }
        .card-logo { width: 82px; height: 82px; display: grid; place-items: center; margin-bottom: 18px; border-radius: 50%; background: #e7fbff; border: 1px solid #bdebf2; }
        .card-logo img { width: 68px; height: auto; }
        .form-label { color: #21384c; }
        .form-control { border-color: #b6e8ef; min-height: 46px; border-radius: 7px; }
        .form-control:focus { border-color: #15a9bd; box-shadow: 0 0 0 .2rem rgba(21,169,189,.14); }
        .btn-aqua { background: #087f95; color: white; border: 0; border-radius: 7px; min-height: 48px; box-shadow: 0 10px 20px rgba(8,127,149,.2); }
        .btn-aqua:hover { background: #066d80; color: white; }
        .tiny-footer { color: var(--muted); font-size: .8rem; }
        @media (max-width: 900px) { .login-wrap { grid-template-columns: 1fr; } .login-brand { min-height: 420px; } .login-panel { padding: 28px 18px; } }
    </style>
</head>
<body>
<div class="login-wrap">
    <section class="login-brand text-center">
        <div class="brand-content">
            <div class="logo-stage">
                <img src="{{ asset('assets/logo-water.svg') }}" alt="Logo de J.A.S.S. Quilcata">
            </div>
            <div class="brand-title">J.A.S.S. QUILCATA</div>
            <div class="brand-subtitle">Sistema de Gestion de Pagos</div>
            <div class="brand-note">Servicio de Agua Potable</div>
        </div>
    </section>
    <section class="login-panel">
        <form class="login-card" method="POST" action="{{ route('login.store') }}">
            @csrf
            <div class="card-logo">
                <img src="{{ asset('assets/logo-water.svg') }}" alt="Logo">
            </div>
            <h1 class="h3 fw-bold mb-1">Bienvenido</h1>
            <p class="text-secondary mb-4">Ingresa tus credenciales para continuar.</p>

            @if ($errors->any())
                <div class="alert alert-danger py-2">{{ $errors->first() }}</div>
            @endif

            <label class="form-label small fw-semibold">Usuario</label>
            <input name="username" value="{{ old('username') }}" class="form-control mb-3" placeholder="admin_jass" autofocus required>

            <label class="form-label small fw-semibold">Contrasena</label>
            <input type="password" name="password" class="form-control mb-3" required>

            <div class="d-flex justify-content-between align-items-center mb-4">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="remember" value="1" id="remember">
                    <label class="form-check-label small" for="remember">Recordarme</label>
                </div>
                <span class="tiny-footer">Conexion local segura</span>
            </div>

            <button class="btn btn-aqua w-100 py-2 fw-semibold">Iniciar sesion</button>
        </form>
    </section>
</div>
</body>
</html>
