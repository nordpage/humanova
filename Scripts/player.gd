extends CharacterBody3D

const BASE_SPEED = 5.0
const BASE_SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5

@onready var pivot = $CamOrigin
@onready var cam_v = $CamOrigin/V
@onready var camera = $CamOrigin/V/H/SpringArm3D/Camera3D
@onready var hud = $"../HUD"
@export var sens = 0.5  # Базовая чувствительность мыши

# Переменные для отслеживания углов
var current_y_angle = 0.0  # Фиксированный угол Y (45 градусов)
var current_x_angle = -45.0  # Фиксированный угол X (-45 градусов для вида сверху)

# Ограничения углов камеры (не используются, так как камера фиксирована)
@export var max_y_angle = 180.0
@export var min_y_angle = -180.0
@export var max_x_angle = 45.0
@export var min_x_angle = -90.0

# Переменные для психологического состояния
var sanity_level = 100.0  # От 0 до 100
var hallucination_intensity = 0.0  # От 0 до 100

# Переменные для дрожания камеры
var shake_intensity = 0.0
var shake_decay = 5.0
var shake_time = 0.0
var random = RandomNumberGenerator.new()

# Система аугментаций
var augmentation_system: AugmentationSystem
var current_interactive_object = null
var interaction_ray_length = 2.0  # Дистанция проверки интерактивных объектов

# Физика
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	random.randomize()
	
	# Установка фиксированного угла камеры (как в Don't Starve)
	pivot.rotation_degrees.y = current_y_angle
	cam_v.rotation_degrees.x = current_x_angle
	
	# Инициализация системы аугментаций
	augmentation_system = AugmentationSystem.new()
	add_child(augmentation_system)
	
	# Подключаем сигналы от системы аугментаций
	augmentation_system.connect("mental_stress_changed", _on_mental_stress_changed)
	augmentation_system.connect("augmentation_activated", _on_augmentation_activated)
	augmentation_system.connect("augmentation_deactivated", _on_augmentation_deactivated)
	
	# Отложенная настройка визуальных эффектов
	call_deferred("setup_environment_effects")

func _on_mental_stress_changed(value):
	# Обновляем уровень рассудка на основе ментального стресса
	sanity_level = max(100.0 - value, 0.0)

func _on_augmentation_activated(aug_id):
	# Обработка активации аугментаций
	match aug_id:
		"cyber_eyes":
			# Включаем эффект ночного зрения
			enable_night_vision()
		"tactical_hud":
			# Включаем тактический интерфейс
			enable_tactical_hud()
		"neuro_accelerator":
			# Эффект замедления времени (для игрока)
			apply_camera_shake(0.3, 0.5)
		"sensory_enhancer":
			# Улучшенное восприятие
			enable_enhanced_senses()

func _on_augmentation_deactivated(aug_id):
	# Обработка деактивации аугментаций
	match aug_id:
		"cyber_eyes":
			disable_night_vision()
		"tactical_hud":
			disable_tactical_hud()
		"neuro_accelerator":
			# Ничего не делаем, эффект временный
			pass
		"sensory_enhancer":
			disable_enhanced_senses()

func _input(event):
	# Движения мыши не обрабатываются, камера фиксирована
	
	# Только активация аугментаций по клавишам
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			toggle_augmentation("neuro_accelerator")
		elif event.keycode == KEY_2:
			toggle_augmentation("cyber_eyes")
		elif event.keycode == KEY_3:
			toggle_augmentation("cyber_strength")
		elif event.keycode == KEY_4:
			toggle_augmentation("hyper_memory")
			
	if event.is_action_pressed("interact") and current_interactive_object:
		current_interactive_object.interact(self)

func toggle_augmentation(aug_id):
	var aug = augmentation_system.get_augmentation_info(aug_id)
	if aug.empty():
		return
	
	if aug["installed"]:
		if aug["active"]:
			augmentation_system.deactivate_augmentation(aug_id)
		else:
			augmentation_system.activate_augmentation(aug_id)

func _physics_process(delta):
	# Обновление системы аугментаций
	augmentation_system.update(delta)
	
	# Обновление дрожания камеры
	update_camera_shake(delta)
	
	# Обновление психологических эффектов
	update_psychological_effects(delta)
	
	# Получаем текущие модификаторы от аугментаций
	var modifiers = augmentation_system.get_current_modifiers()
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Выход
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	# Получаем вектор ввода
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = Vector3.ZERO
	
	# В Don't Starve управление относительно мира, а не камеры
	# Но мы сохраняем базовое смещение из-за фиксированного угла камеры
	# Чтобы up действительно двигал вверх на экране
	var world_basis = Basis(Vector3.UP, deg_to_rad(0))  # 45 градусов смещение
	direction = world_basis * Vector3(input_dir.x, 0, input_dir.y)
	direction.y = 0
	direction = direction.normalized()
	
	# Применяем модификаторы скорости от аугментаций
	var speed_mod = modifiers["speed"]
	var current_speed = BASE_SPEED * speed_mod
	var current_sprint_speed = BASE_SPRINT_SPEED * speed_mod
	
	# Проверка на спринт
	var final_speed = current_sprint_speed if Input.is_action_pressed("sprint") else current_speed	
	
	# Перемещение персонажа с учетом психического состояния
	if direction:
		# Добавляем случайности к движению при низком уровне психики
		if sanity_level < 50:
			var distortion = (50.0 - sanity_level) / 50.0
			direction.x += random.randf_range(-0.3, 0.3) * distortion
			direction.z += random.randf_range(-0.3, 0.3) * distortion
			direction = direction.normalized()
		
		velocity.x = direction.x * final_speed
		velocity.z = direction.z * final_speed
	else:
		velocity.x = move_toward(velocity.x, 0, final_speed)
		velocity.z = move_toward(velocity.z, 0, final_speed)
	
	# Применяем движение
	move_and_slide()
	
	# НЕ поворачиваем персонажа - он всегда обращен в одном направлении
	# self.rotation.y = deg_to_rad(current_y_angle)
	var space_state = get_world_3d().direct_space_state
	var camera_global_position = camera.global_position
	var ray_end = camera_global_position + -camera.global_transform.basis.z * interaction_ray_length
	
	var query = PhysicsRayQueryParameters3D.create(camera_global_position, ray_end)
	query.exclude = [self]  # Исключаем самого игрока
	query.collision_mask = 4
	
	var result = space_state.intersect_ray(query)
	
	var new_interactive_object = null
	
	if result and result.collider:
		var object = result.collider
		
		# Проверяем, является ли объект интерактивным
		if object is InteractiveObject and object.can_be_interacted():
			new_interactive_object = object
		elif object.get_parent() is InteractiveObject and object.get_parent().can_be_interacted():
			new_interactive_object = object.get_parent()
	
	# Обновляем подсветку и подсказки
	if new_interactive_object != current_interactive_object:
		if current_interactive_object:
			current_interactive_object.highlight(false)
		
		current_interactive_object = new_interactive_object
		
		if current_interactive_object:
			current_interactive_object.highlight(true)
			show_interaction_prompt(current_interactive_object.get_interaction_prompt())
		else:
			hide_interaction_prompt()
			
	if Input.is_action_just_pressed("debug"):
		print("Current interactive object: ", current_interactive_object)
		print("Ray length: ", interaction_ray_length)
		print("Camera position: ", camera.global_position)
		
		# Выполнить ручной рейкаст и вывести все результаты
		var space_state = get_world_3d().direct_space_state
		var ray_end = camera.global_position + -camera.global_transform.basis.z * 10.0  # Увеличиваем дистанцию
		var query = PhysicsRayQueryParameters3D.create(camera.global_position, ray_end)
		query.exclude = [self]
		query.collision_mask = 0xFFFFFFFF  # Проверяем все слои
		var result = space_state.intersect_ray(query)
		print("Debug raycast hit: ", result)
		if result and result.collider:
			print("Collider: ", result.collider)
			print("Collider parent: ", result.collider.get_parent())

func setup_environment_effects():
	var world_env = WorldEnvironment.new()
	world_env.name = "PsychologicalEffects"
	add_child(world_env)
	
	var env = Environment.new()
	world_env.environment = env
	
	# Базовые настройки окружения
	env.set("background_mode", Environment.BG_CLEAR_COLOR)
	
	# Включаем эффекты постобработки
	env.set("glow/enabled", true)
	env.set("glow/intensity", 0.1)
	env.set("glow/bloom", 0.1)
	
	# Настраиваем цветокоррекцию
	env.set("adjustment/enabled", true)
	env.set("adjustment/brightness", 1.0)
	env.set("adjustment/contrast", 1.0)
	env.set("adjustment/saturation", 1.0)

func update_camera_shake(delta):
	if shake_time > 0:
		shake_time -= delta
		var offset_x = random.randf_range(-1.0, 1.0) * shake_intensity
		var offset_y = random.randf_range(-1.0, 1.0) * shake_intensity
		
		camera.h_offset = offset_x
		camera.v_offset = offset_y
		
		shake_intensity = max(0, shake_intensity - shake_decay * delta)
	else:
		camera.h_offset = 0
		camera.v_offset = 0

func update_psychological_effects(delta):
	var world_env = get_node_or_null("PsychologicalEffects")
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Вычисляем коэффициенты искажений на основе уровня психики
		var distortion = (100.0 - sanity_level) / 100.0
		
		# Применяем искажения к окружению
		env.set("adjustment/brightness", lerp(1.0, 1.3, distortion))  # Ярче при стрессе
		env.set("adjustment/contrast", lerp(1.0, 1.4, distortion))    # Контрастнее
		env.set("adjustment/saturation", lerp(1.0, 0.7, distortion))  # Менее насыщенный
		
		# Эффект свечения
		env.set("glow/intensity", lerp(0.1, 0.5, distortion))
		env.set("glow/bloom", lerp(0.1, 0.3, distortion))

func apply_camera_shake(intensity, time):
	shake_intensity = intensity
	shake_time = time

func decrease_sanity(amount):
	sanity_level = max(0, sanity_level - amount)
	apply_camera_shake(amount / 20.0, 0.5)  # Небольшое дрожание при снижении психики
	
	if sanity_level < 30:
		# Вызвать галлюцинации
		trigger_hallucination()

func increase_sanity(amount):
	sanity_level = min(100, sanity_level + amount)

func trigger_hallucination():
	# Случайное искажение зрения
	var intensity = (100.0 - sanity_level) / 100.0 * 3.0
	apply_camera_shake(intensity, 2.0)
	
	hallucination_intensity = intensity * 10.0

# Функции для эффектов аугментаций

func enable_night_vision():
	var world_env = get_node_or_null("PsychologicalEffects")
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Создаем градиент для ночного видения (зеленоватый)
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(0.0, 0.1, 0.05))
		gradient.add_point(0.5, Color(0.0, 0.5, 0.2))
		gradient.add_point(1.0, Color(0.2, 0.8, 0.4))
		
		# Создаем текстуру из градиента
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		gradient_texture.width = 256
		
		# Применяем как цветокоррекцию
		env.set("adjustment/enabled", true)
		env.set("adjustment/color_correction", gradient_texture)
		
		# Дополнительные настройки
		env.set("adjustment/brightness", 1.5)
		env.set("adjustment/contrast", 0.8)
		env.set("adjustment/saturation", 0.2)

func disable_night_vision():
	# Вернуть настройки окружения к нормальным
	update_psychological_effects(0.1)

func enable_tactical_hud():
	# Здесь можно создать и показать интерфейс HUD
	var hud = preload("res://Scenes/HUD.tscn").instantiate()
	add_child(hud)

func disable_tactical_hud():
	# Удалить HUD
	var hud = get_node_or_null("TacticalHUD")
	if hud:
		hud.queue_free()

func enable_enhanced_senses():
	# Увеличиваем дальность видимости и чувствительность
	var world_env = get_node_or_null("PsychologicalEffects")
	if world_env and world_env.environment:
		var env = world_env.environment
		env.set("adjustment/brightness", 1.2)
		env.set("adjustment/contrast", 1.3)
		env.set("adjustment/saturation", 1.5)

func disable_enhanced_senses():
	# Вернуть настройки окружения к нормальным
	update_psychological_effects(0.1)

# Публичное API для других систем

func install_augmentation(aug_id):
	return augmentation_system.install_augmentation(aug_id)

func get_mental_stress() -> float:
	return augmentation_system.mental_stress

func get_thermal_state() -> float:
	return augmentation_system.thermal_state

func get_energy_consumption() -> float:
	return augmentation_system.energy_consumption

func get_active_augmentations() -> Dictionary:
	return augmentation_system.get_active_augmentations()
	
func show_interaction_prompt(text):
	# Здесь ваш код для отображения подсказки на экране
	# Например:
	if hud:
		print("Show interaction: " + text)
		hud.show_interaction_prompt(text)

func hide_interaction_prompt():
	if hud:
		hud.hide_interaction_prompt()

# Показать уведомление
func show_notification(text, duration = 3.0):
	if hud:
		hud.show_notification(text, duration)
