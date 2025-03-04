shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

uniform vec3 fog_color : source_color = vec3(0.05, 0.03, 0.1);
uniform float fog_density : hint_range(0.0, 1.0) = 0.01;  // Уменьшенная плотность
uniform float fog_height : hint_range(0.0, 20.0) = 5.0;

uniform vec3 neon_color1 : source_color = vec3(0.9, 0.2, 0.9); // Пурпурный
uniform vec3 neon_color2 : source_color = vec3(0.1, 0.7, 0.9); // Голубой
uniform float ray_intensity : hint_range(0.0, 5.0) = 0.6;      // Снижена интенсивность лучей
uniform float ray_density : hint_range(0.0, 20.0) = 3.0;       // Снижена плотность лучей
uniform float ray_speed : hint_range(0.0, 5.0) = 0.5;          // Снижена скорость

uniform float noise_scale : hint_range(0.1, 10.0) = 1.2;       // Меньше масштаб шума
uniform float noise_speed : hint_range(0.0, 2.0) = 0.1;        // Медленнее движение

// Функция для генерации 3D шума
float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    f = f * f * (3.0 - 2.0 * f);

    float n = i.x + i.y * 157.0 + 113.0 * i.z;
    return mix(mix(mix(fract(sin(n + 0.0) * 43758.5453),
                     fract(sin(n + 1.0) * 43758.5453), f.x),
                mix(fract(sin(n + 157.0) * 43758.5453),
                     fract(sin(n + 158.0) * 43758.5453), f.x), f.y),
              mix(mix(fract(sin(n + 113.0) * 43758.5453),
                     fract(sin(n + 114.0) * 43758.5453), f.x),
                mix(fract(sin(n + 270.0) * 43758.5453),
                     fract(sin(n + 271.0) * 43758.5453), f.x), f.y), f.z);
}

// Фрактальный Броуновский шум с меньшим количеством итераций
float fbm(vec3 p) {
    float f = 0.0;
    float weight = 0.5;
    float scale = 1.0;

    for (int i = 0; i < 3; i++) {  // Меньше итераций для тонкости
        f += weight * noise3D(p * scale);
        weight *= 0.5;
        scale *= 2.0;
    }

    return f;
}

// Более тонкие лучи света через туман
float light_rays(vec3 position, float time) {
    // Проецируем позицию на плоскость XZ
    vec2 pos_xz = position.xz;

    // Создаем лучи с меньшей интенсивностью
    float ray = 0.0;

    // Луч 1 - более плавный переход
    vec2 ray_dir1 = normalize(vec2(1.0, 0.5));
    ray += smoothstep(0.3, 0.7, sin(dot(pos_xz, ray_dir1) * ray_density + time * ray_speed));

    // Луч 2 - более плавный переход
    vec2 ray_dir2 = normalize(vec2(-0.7, 0.8));
    ray += smoothstep(0.3, 0.7, sin(dot(pos_xz, ray_dir2) * ray_density + time * ray_speed * 0.7));

    // Затухание с высотой более плавное
    float height_atten = smoothstep(fog_height, fog_height * 0.3, position.y);

    return ray * height_atten * ray_intensity * 0.7;  // Снижаем общую интенсивность
}

void fragment() {
    // Получаем позицию в мировых координатах
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Движущийся шум для тумана
    float time = TIME * noise_speed;
    vec3 noise_pos = world_pos * noise_scale + vec3(0.0, time, 0.0);
    float noise_val = fbm(noise_pos);

    // Более плавное затухание тумана с высотой
    float height_factor = smoothstep(fog_height, fog_height * 0.2, world_pos.y);

    // Базовая плотность тумана уменьшена
    float fog_amount = noise_val * fog_density * height_factor * 0.8;

    // Лучи света
    float rays = light_rays(world_pos, time);

    // Смешиваем цвета лучей с меньшей насыщенностью
    vec3 ray_color = mix(neon_color1 * 0.8, neon_color2 * 0.8, sin(TIME * 0.3) * 0.5 + 0.5);

    // Итоговый цвет с большей долей основного цвета тумана
    vec3 final_color = mix(fog_color, ray_color, rays * 0.7);

    // Более низкий альфа-канал для прозрачности
    float alpha = clamp(fog_amount * 0.7, 0.0, 0.8);  // Ограничиваем максимальную непрозрачность

    // Меньшее свечение
    ALBEDO = final_color;
    ALPHA = alpha;
    EMISSION = final_color * alpha * 0.3;  // Меньше эмиссии
}