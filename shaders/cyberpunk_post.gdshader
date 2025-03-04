shader_type canvas_item;

// Основные параметры
uniform float aberration_amount : hint_range(0.0, 3.0) = 0.5;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.03;
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float distortion : hint_range(0.0, 1.0) = 0.0;

// Текстуры
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Дополнительные параметры
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;

// Генератор шума
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Искажение координат
vec2 distort_uv(vec2 uv) {
    vec2 center = vec2(0.5);
    vec2 dist_uv = uv - center;
    float dist = length(dist_uv);

    // Базовое искажение от центра
    float distort_strength = distortion * 0.2;

    // Добавляем волновое искажение при высоком уровне расстройства
    if (distortion > 0.3) {
        float wave = sin(dist * 20.0 - TIME * pulse_speed) * sin(dist * 15.0 - TIME * pulse_speed * 0.7);
        distort_strength += wave * distortion * 0.05;
    }

    return uv + dist_uv * dist * distort_strength;
}

// Хроматическая аберрация
vec4 apply_aberration(vec2 uv) {
    float aberration = aberration_amount * 0.01;

    vec2 red_uv = uv + vec2(aberration, 0.0);
    vec2 green_uv = uv - vec2(0.0, aberration * 0.5);
    vec2 blue_uv = uv - vec2(aberration, -aberration * 0.5);

    float r = texture(SCREEN_TEXTURE, red_uv).r;
    float g = texture(SCREEN_TEXTURE, green_uv).g;
    float b = texture(SCREEN_TEXTURE, blue_uv).b;

    return vec4(r, g, b, 1.0);
}

// Виньетирование
float apply_vignette(vec2 uv) {
    vec2 center = vec2(0.5);
    float dist = length(uv - center);
    return smoothstep(0.8, 0.2, dist * vignette_intensity * 2.0);
}

// Сканлайны
float apply_scanlines(vec2 uv) {
    float scanlines = sin(uv.y * 800.0) * 0.5 + 0.5;
    return mix(1.0, scanlines, scanline_intensity);
}

// Цифровой шум
float apply_grain(vec2 uv) {
    float noise = rand(uv * TIME * 0.01);
    return mix(1.0, noise, grain_intensity);
}

// Пульсация
float apply_pulse(vec2 uv) {
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    return pulse * distortion * 0.2 + 1.0;
}

void fragment() {
    // Применяем базовые искажения UV
    vec2 distorted_uv = distort_uv(UV);

    // Хроматическая аберрация
    vec4 color = apply_aberration(distorted_uv);

    // Применяем виньетирование
    float vignette = apply_vignette(distorted_uv);
    color.rgb *= vignette;

    // Сканлайны
    float scanlines = apply_scanlines(distorted_uv);
    color.rgb *= scanlines;

    // Шум
    float grain = apply_grain(UV); // Используем оригинальные UV для шума
    color.rgb = mix(color.rgb, color.rgb * grain, grain_intensity);

    // Пульсация при высоком уровне искажения
    if (distortion > 0.5) {
        color.rgb *= apply_pulse(UV);
    }

    // Финальный тинт
    color.rgb = mix(color.rgb, color.rgb * tint_color.rgb, distortion * 0.3);

    COLOR = color;
}