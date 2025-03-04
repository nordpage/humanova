extends Node3D

class_name AtmosphericLighting

# Основные настройки
@export_group("Base Settings")
@export var base_ambient_color: Color = Color(0.02, 0.02, 0.04)  # Темно-синий базовый
@export var global_intensity: float = 1.0
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.05, 0.03, 0.1)
@export var fog_density: float = 0.01  # Уменьшена плотность тумана

# Неоновые цвета
@export_group("Neon Colors")
@export var neon_primary: Color = Color(0.9, 0.2, 0.9)  # Пурпурный
@export var neon_secondary: Color = Color(0.1, 0.7, 0.9)  # Голубой
@export var neon_accent: Color = Color(0.2, 0.9, 0.4)  # Зеленый

# Компоненты
var world_environment: WorldEnvironment
var lights: Array[Light3D] = []
var neon_lights: Array[Light3D] = []
var flickering_lights: Array[Light3D] = []

# Влияние психического состояния
var sanity_level: float = 100.0
var distortion_level: float = 0.0

func _ready():
	print("AtmosphericLighting: Запуск...")
	setup_environment()
	collect_scene_lights()
	
	# Отладка
	print("AtmosphericLighting: Инициализация завершена")
	print("Найдено обычных источников света: ", lights.size())
	print("Найдено неоновых источников света: ", neon_lights.size())
	print("Найдено мерцающих источников света: ", flickering_lights.size())

func setup_environment():
	# Создаем окружение
	print("AtmosphericLighting: Настройка окружения...")
	world_environment = WorldEnvironment.new()
	world_environment.name = "SceneEnvironment"
	add_child(world_environment)
	
	var env = Environment.new()
	world_environment.environment = env
	
	# Настройка базового окружения через set
	env.set("background_mode", Environment.BG_COLOR)
	env.set("background_color", base_ambient_color)
	
	# Настройка тумана
	env.set("fog/enabled", fog_enabled)
	env.set("fog/density", fog_density)
	env.set("fog/sky_affect", 0.7)
	env.set("fog/color", fog_color)
	
	# Настройка тональной карты
	env.set("tonemap/mode", Environment.TONE_MAPPER_FILMIC)
	env.set("tonemap/exposure", 0.9)
	
	# Настройка свечения
	env.set("glow/enabled", true)
	env.set("glow/intensity", 0.15)
	env.set("glow/bloom", 0.15)
	env.set("glow/hdr_threshold", 0.9)
	
	# Настройка цветокоррекции
	env.set("adjustment/enabled", true)
	env.set("adjustment/brightness", 1.0)
	env.set("adjustment/contrast", 1.05)
	env.set("adjustment/saturation", 1.1)
	
	print("AtmosphericLighting: Окружение настроено")

func collect_scene_lights():
	print("AtmosphericLighting: Поиск источников света...")
	
	# Поиск через рекурсивный обход
	var scene_root = get_tree().current_scene
	print("  - Текущая сцена: ", scene_root.name)
	
	find_all_lights(scene_root, lights)
	print("  - Найдено источников света: ", lights.size())
	
	if lights.size() > 0:
		for light in lights:
			process_light(light)
	else:
		print("ПРЕДУПРЕЖДЕНИЕ: Источники света не найдены! Проверьте сцену.")

func find_all_lights(node, results):
	if node is Light3D:
		if not results.has(node):
			results.append(node)
	
	for child in node.get_children():
		find_all_lights(child, results)

func process_light(light):
	print("  - Обработка света: ", light.name)
		
	# Определяем тип света строго по имени
	var light_name = light.name.to_lower()
	
	if "neon" in light_name:
		print("    * Определен как неоновый")
		neon_lights.append(light)
		
		# Сохраняем базовую энергию света
		if not light.has_meta("base_energy"):
			light.set_meta("base_energy", light.light_energy)
			
	elif "flicker" in light_name or "broken" in light_name:
		print("    * Определен как мерцающий")
		flickering_lights.append(light)
		add_flicker_to_light(light)
	
	# НЕ определяем по цвету - только по имени

func add_flicker_to_light(light: Light3D):
	print("AtmosphericLighting: Добавление эффекта мерцания к ", light.name)
	
	# Проверяем, есть ли уже таймер мерцания
	if light.has_node("FlickerTimer"):
		print("  - У источника уже есть таймер мерцания")
		return
		
	# Добавляем компонент для мерцания
	var flicker = Timer.new()
	flicker.name = "FlickerTimer"
	light.add_child(flicker)
	flicker.wait_time = randf_range(0.05, 0.2)
	flicker.autostart = true
	
	# Сохраняем базовую энергию света
	if not light.has_meta("base_energy"):
		light.set_meta("base_energy", light.light_energy)
	
	# Подключаем сигнал
	flicker.timeout.connect(_on_flicker_timeout.bind(light))
	print("  - Таймер мерцания добавлен и запущен")

func _on_flicker_timeout(light: Light3D):
	if not is_instance_valid(light):
		return
		
	var timer = light.get_node("FlickerTimer")
	if not is_instance_valid(timer):
		return
	
	# Получаем базовую энергию или используем текущую
	var base_energy = 1.0
	if light.has_meta("base_energy"):
		base_energy = light.get_meta("base_energy")
	
	# Рандомизация интенсивности
	var flicker_amount = randf_range(0.7, 1.3)
	if randf() < 0.05:  # Шанс сильной вспышки или затухания
		flicker_amount = randf_range(0.1, 2.0)
	
	light.light_energy = base_energy * flicker_amount
	
	# Настраиваем следующий интервал
	timer.wait_time = randf_range(0.05, 0.2)
	timer.start()

func update_with_sanity(sanity: float):
	# Обновляем освещение на основе психического состояния
	sanity_level = sanity
	distortion_level = (100.0 - sanity) / 100.0
	
	# Обновляем окружение
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.set("adjustment/brightness", lerp(1.0, 1.15, distortion_level))
		env.set("adjustment/contrast", lerp(1.05, 1.2, distortion_level))
		env.set("glow/intensity", lerp(0.15, 0.4, distortion_level))
		
		# Искажаем цвета при низком уровне рассудка
		if sanity < 50:
			env.set("adjustment/saturation", lerp(1.1, 0.7, distortion_level))
		else:
			env.set("adjustment/saturation", 1.1)
	
	# Обновляем поведение неоновых источников света
	for light in neon_lights:
		if not is_instance_valid(light):
			continue
			
		if sanity < 30:
			# Начинаем мерцание всех неоновых источников
			if not light.has_node("FlickerTimer"):
				add_flicker_to_light(light)
		else:
			# Убираем мерцание с неоновых, если не должны мерцать
			if light.has_node("FlickerTimer") and not flickering_lights.has(light):
				light.get_node("FlickerTimer").queue_free()
				if light.has_meta("base_energy"):
					light.light_energy = light.get_meta("base_energy")

func _process(delta):
	# Плавные изменения, создающие живое ощущение
	if Engine.is_editor_hint():
		return
		
	# Пульсация неоновых источников - очень мягкая
	for light in neon_lights:
		if not is_instance_valid(light):
			continue
			
		if not light.has_node("FlickerTimer"):  # Не трогаем те, что мерцают
			var pulse = sin(Time.get_ticks_msec() / 1000.0) * 0.05 + 0.95  # Меньше диапазон (0.9-1.0)
			
			if light.has_meta("base_energy"):
				var base = light.get_meta("base_energy")
				light.light_energy = light.light_energy * 0.95 + base * pulse * 0.05
			else:
				# Сохраняем базовую энергию, если её ещё нет
				light.set_meta("base_energy", light.light_energy)

# Создание предустановок освещения для разных настроений/областей
func apply_preset(preset_name: String):
	print("AtmosphericLighting: Применение пресета: ", preset_name)
	match preset_name:
		"downtown":
			neon_primary = Color(0.9, 0.2, 0.9)  # Пурпурный
			neon_secondary = Color(0.1, 0.7, 0.9)  # Голубой
			base_ambient_color = Color(0.02, 0.02, 0.04)
			fog_color = Color(0.05, 0.03, 0.1)
			fog_density = 0.01
		
		"industrial":
			neon_primary = Color(0.9, 0.5, 0.1)  # Оранжевый
			neon_secondary = Color(0.6, 0.1, 0.1)  # Темно-красный
			base_ambient_color = Color(0.03, 0.02, 0.01)
			fog_color = Color(0.05, 0.04, 0.02)
			fog_density = 0.015
		
		"corporate":
			neon_primary = Color(0.1, 0.5, 0.9)  # Синий
			neon_secondary = Color(0.1, 0.7, 0.5)  # Сине-зеленый
			base_ambient_color = Color(0.04, 0.04, 0.05)
			fog_color = Color(0.04, 0.04, 0.06)
			fog_density = 0.005
		
		"slums":
			neon_primary = Color(0.6, 0.5, 0.1)  # Желтый
			neon_secondary = Color(0.5, 0.2, 0.6)  # Фиолетовый
			base_ambient_color = Color(0.02, 0.01, 0.02)
			fog_color = Color(0.04, 0.02, 0.04)
			fog_density = 0.02
	
	# Применяем новые настройки
	update_lighting_parameters()

func update_lighting_parameters():
	# Обновляем все компоненты освещения
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.set("background_color", base_ambient_color)
		env.set("fog/color", fog_color)
		env.set("fog/density", fog_density)
	
	# Обновляем неоновые источники света
	update_neon_lights()

func update_neon_lights():
	# Обновляем цвета неоновых источников
	var neon_index = 0
	for light in neon_lights:
		if not is_instance_valid(light):
			continue
			
		# Чередуем основной и вторичный цвета
		if neon_index % 3 == 0:
			light.light_color = neon_primary
		elif neon_index % 3 == 1:
			light.light_color = neon_secondary
		else:
			light.light_color = neon_accent
		neon_index += 1
