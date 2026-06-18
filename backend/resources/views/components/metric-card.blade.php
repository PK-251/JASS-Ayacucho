@props(['label', 'icon', 'tone' => 'default', 'valueClass' => '', 'badge' => null, 'badgeClass' => 'badge-soft'])

<div {{ $attributes->merge(['class' => 'metric-card']) }}>
    <span class="metric-icon metric-icon--{{ $tone }}">
        <x-metric-icon :name="$icon" />
    </span>
    <div class="metric-label">{{ $label }}</div>
    <div class="metric-value {{ $valueClass }}">{{ $slot }}</div>
    @if ($badge)
        <span class="badge {{ $badgeClass }} mt-2">{{ $badge }}</span>
    @endif
    @isset($footer)
        {{ $footer }}
    @endisset
</div>
