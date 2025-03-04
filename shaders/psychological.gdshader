shader_type canvas_item;

uniform float distortion_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float hallucination_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.0, 10.0) = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Функция для добавления шума
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Функция искажения
vec2 distort(vec2 uv, float intensity) {
    vec2 center = vec2(0.5);
    vec2 distort_uv = uv - center;
    float dist = length(distort_uv);
    float factor = pow(dist, 1.0) * intensity * 0.1;

    // Волнообразное искажение со временем
    float time = TIME * time_scale;
    float wave = sin(dist * 10.0 - time) * sin(dist * 15.0 - time * 0.5);

    return uv + distort_uv * factor * (1.0 + wave * hallucination_intensity);
}

void fragment() {
    // Базовые UV координаты
    vec2 uv = SCREEN_UV;

    // Применяем искажение
    vec2 distorted_uv = distort(uv, distortion_intensity);

    // Хроматическая аберрация
    float r_offset = aberration_intensity * 0.01;
    float g_offset = aberration_intensity * 0.005;

    vec4 r_color = texture(SCREEN_TEXTURE, distorted_uv + vec2(r_offset, 0.0));
    vec4 g_color = texture(SCREEN_TEXTURE, distorted_uv - vec2(0.0, g_offset));
    vec4 b_color = texture(SCREEN_TEXTURE, distorted_uv - vec2(r_offset, -g_offset));

    // Создаем итоговый цвет с аберрацией
    vec4 color = vec4(r_color.r, g_color.g, b_color.b, 1.0);

    // Добавляем шум для эффекта зернистости
    float grain = random(uv * TIME * 0.01) * grain_intensity;
    color.rgb += vec3(grain);

    // Добавляем виньетирование
    float vignette = length(uv - 0.5);
    vignette = smoothstep(0.5, 0.35, vignette) * vignette_intensity;
    color.rgb = mix(color.rgb, color.rgb * (1.0 - vignette), vignette_intensity);

    // Добавляем эффект галлюцинации при высокой интенсивности
    if (hallucination_intensity > 0.3) {
        // Пульсация и волны
        float pulse = sin(TIME * time_scale) * 0.5 + 0.5;
        float wave_effect = sin(uv.y * 50.0 + TIME * 2.0) * hallucination_intensity * 0.1;

        // Добавляем цветовой тинт для галлюцинаций
        color.rgb = mix(color.rgb, tint_color.rgb, hallucination_intensity * 0.3 * pulse);
        color.rgb += vec3(wave_effect);
    }

    COLOR = color;
}