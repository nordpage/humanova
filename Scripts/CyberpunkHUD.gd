extends CanvasLayer

# Ссылки на элементы интерфейса
@onready var health_bar = $Control/Control2/Panel/HP
@onready var energy_bar = $Control/Control2/Panel/Energy
@onready var mental_bar = $Control/Control2/Panel/Mental
@onready var heat_container = $Control/Control2/HeatContainer
@onready var heat_meter = $Control/Control2/HeatContainer/HeatMeter
@onready var heat_value = $Control/Control2/HeatContainer/HeatValue
@onready var objective_panel = $Control/ObjectivePanel
@onready var objective_label = $Control/ObjectivePanel/ObjectiveLabel
@onready var augmentation_container = $Control/HBoxContainer
@onready var notification_panel = $Control/NotificationPanel
@onready var notification_label = $Control/NotificationPanel/NotificationLabel
@onready var interaction_panel = $Control/Interaction
@onready var interaction_prompt = $Control/Interaction/InteractionPrompt
@onready var interaction_progress = $Control/Interaction/InteractionProgress



# Настройки
var notification_duration = 3.0
var scan_mode_active = false

# Путь к иконкам аугментаций
var augmentation_icons = {
	"neuro_accelerator": {
		"active": preload("res://icons/augmentations/neuro_accelerator_active.png"),
		"passive": preload("res://icons/augmentations/neuro_accelerator_passive.png")
	},
	"cyber_eyes": {
		"active": preload("res://icons/augmentations/cyber_eyes_active.png"),
		"passive": preload("res://icons/augmentations/cyber_eyes_passive.png")
	}
	# Другие аугментации
}

func _ready():
	# Инициализация HUD
	notification_panel.visible = false
	interaction_panel.visible = false
	update_objective("Исследовать район и найти информацию")
	show_notification("Система запущена. Добро пожаловать в CyberEcho.", 5.0)
	# Задаем начальные значения
	update_health(100)
	update_sanity(100)
	update_energy(100)
	update_heat(0)

func update_health(value):
	health_bar.value = value

func update_sanity(value):
	mental_bar.value = value

func update_energy(value):
	energy_bar.value = value	

func update_heat(value):
	heat_meter.value = value
	heat_value.text = str(int(value)) + "%"

func update_objective(text):
	objective_label.text = "ТЕКУЩАЯ ЦЕЛЬ: " + text

func show_notification(text, duration = notification_duration):
	notification_label.text = text
	notification_panel.visible = true
	
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	notification_panel.visible = false

func add_augmentation_icon(aug_id, is_installed = true, is_active = false):
	if not aug_id in augmentation_icons:
		return
		
	# Проверяем, не существует ли уже такая иконка
	if augmentation_container.has_node(aug_id):
		update_augmentation_icon(aug_id, is_active)
		return
	
	var aug_frame = TextureRect.new()
	aug_frame.name = aug_id
	aug_frame.texture = preload("res://textures/hud/aug_frame.png")
	aug_frame.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	aug_frame.custom_minimum_size = Vector2(64, 64)
	
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.custom_minimum_size = Vector2(48, 48)
	
	if is_installed:
		if is_active:
			icon.texture = augmentation_icons[aug_id]["active"]
		else:
			icon.texture = augmentation_icons[aug_id]["passive"]
	else:
		icon.texture = augmentation_icons[aug_id]["passive"]
		icon.modulate = Color(0.5, 0.5, 0.5)
	
	aug_frame.add_child(icon)
	augmentation_container.add_child(aug_frame)
	
	# Добавляем номер
	var index = augmentation_container.get_child_count()
	var num_label = Label.new()
	num_label.name = "NumLabel"
	num_label.text = str(index)
	num_label.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	aug_frame.add_child(num_label)
	
	return aug_frame

func update_augmentation_icon(aug_id, is_active):
	var aug_frame = augmentation_container.get_node_or_null(aug_id)
	if aug_frame:
		var icon = aug_frame.get_node("Icon")
		if icon:
			if is_active:
				icon.texture = augmentation_icons[aug_id]["active"]
				aug_frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				icon.texture = augmentation_icons[aug_id]["passive"]
				aug_frame.modulate = Color(0.7, 0.7, 0.7, 1.0)

func remove_augmentation_icon(aug_id):
	var aug_frame = augmentation_container.get_node_or_null(aug_id)
	if aug_frame:
		aug_frame.queue_free()
		
		# Обновляем номера
		var index = 1
		for child in augmentation_container.get_children():
			var num_label = child.get_node_or_null("NumLabel")
			if num_label:
				num_label.text = str(index)
				index += 1

func toggle_scan_mode():
	scan_mode_active = !scan_mode_active
	
	# Здесь код для переключения режима сканирования
	# Например, изменение материала постобработки или оверлея
	
	if scan_mode_active:
		show_notification("Режим сканирования активирован")
	else:
		show_notification("Режим сканирования деактивирован")

func _process(_delta):
	# Пульсация для критических состояний
	if health_bar.value < 30:
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		health_bar.modulate.a = lerp(0.7, 1.0, pulse)
	else:
		health_bar.modulate.a = 1.0
	
	if mental_bar.value < 30:
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		mental_bar.modulate.a = lerp(0.7, 1.0, pulse)
	else:
		mental_bar.modulate.a = 1.0
	
	if heat_meter.value > 80:
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		heat_meter.modulate.a = lerp(0.7, 1.0, pulse)
	else:
		heat_meter.modulate.a = 1.0
	
	if energy_bar.value < 20:
		var pulse = (sin(Time.get_ticks_msec() / 200.0) + 1.0) / 2.0
		energy_bar.modulate.a = lerp(0.7, 1.0, pulse)
	else:
		energy_bar.modulate.a = 1.0
		

func show_interaction_prompt(text):
	interaction_panel.visible = true
	interaction_prompt.text = text
	interaction_prompt.visible = true
	interaction_progress.visible = false  # Скрываем прогресс, если он был виден

func hide_interaction_prompt():
	interaction_panel.visible = false
	interaction_prompt.visible = false
	interaction_progress.visible = false

func update_interaction_progress(progress: float):
	interaction_progress.visible = true
	interaction_progress.value = progress * 100.0  # Предполагается, что progress от 0 до 1
