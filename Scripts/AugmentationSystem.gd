extends Node

class_name AugmentationSystem

# Сигналы для обработки событий
signal augmentation_installed(augmentation_id)
signal augmentation_removed(augmentation_id)
signal augmentation_activated(augmentation_id)
signal augmentation_deactivated(augmentation_id)
signal mental_stress_changed(value)
signal thermal_state_changed(value)
signal energy_consumption_changed(value)

# Основные параметры системы
var mental_stress: float = 0.0          # От 0 до 100
var thermal_state: float = 0.0          # От 0 до 100
var energy_consumption: float = 0.0     # От 0 до 100

# Буфер текущих эффектов
var speed_modifier: float = 1.0
var strength_modifier: float = 1.0
var reaction_time_modifier: float = 1.0
var accuracy_modifier: float = 1.0
var vision_range_modifier: float = 1.0
var energy_recovery_modifier: float = 1.0
var health_recovery_modifier: float = 0.0
var cooldown_modifier: float = 1.0

# Словарь доступных аугментаций
var augmentations = {
	"neuro_accelerator": {
		"name": "Нейроускоритель",
		"description": "Увеличивает скорость реакции и рефлексы игрока.",
		"bonuses": {
			"speed": 0.2,           # +20% скорости
			"reaction_time": 0.15,  # -15% времени реакции
		},
		"drawbacks": {
			"thermal_state": 10,    # +10% теплового состояния
		},
		"interactions": {
			"cyber_eyes": {
				"accuracy": 0.1     # +10% точности при стрельбе
			},
			"cooling_system": {
				"thermal_state": -5 # -5% теплового состояния
			}
		},
		"installed": false,
		"active": false,
		"cost": 1500,
		"slot": "neural",
		"level": 1
	},
	"cyber_eyes": {
		"name": "Киберглаза",
		"description": "Улучшает зрение, добавляя функции ночного видения и автоматической фокусировки.",
		"bonuses": {
			"accuracy": 0.15,         # +15% точности
			"night_vision": true,     # Включает ночное зрение
		},
		"drawbacks": {
			"mental_stress": 5,       # +5% ментального стресса
		},
		"interactions": {
			"neuro_accelerator": {
				"night_vision_duration": 0.25  # +25% времени действия
			},
			"hyper_memory": {
				"mental_stress": 10  # +10% ментального стресса
			}
		},
		"installed": false,
		"active": false,
		"cost": 2000,
		"slot": "sensory",
		"level": 1
	},
	# ... остальные аугментации из списка ...
}

# Текущие активные аугментации
var active_augmentations = {}
var installed_augmentations = {}

func _ready():
	# Инициализация системы
	pass

func install_augmentation(aug_id: String) -> bool:
	if aug_id in augmentations and not augmentations[aug_id]["installed"]:
		augmentations[aug_id]["installed"] = true
		installed_augmentations[aug_id] = augmentations[aug_id]
		emit_signal("augmentation_installed", aug_id)
		return true
	return false

func remove_augmentation(aug_id: String) -> bool:
	if aug_id in augmentations and augmentations[aug_id]["installed"]:
		if augmentations[aug_id]["active"]:
			deactivate_augmentation(aug_id)
		
		augmentations[aug_id]["installed"] = false
		installed_augmentations.erase(aug_id)
		emit_signal("augmentation_removed", aug_id)
		return true
	return false

func activate_augmentation(aug_id: String) -> bool:
	if aug_id in augmentations and augmentations[aug_id]["installed"] and not augmentations[aug_id]["active"]:
		augmentations[aug_id]["active"] = true
		active_augmentations[aug_id] = augmentations[aug_id]
		
		# Применяем эффекты
		apply_augmentation_effects(aug_id)
		
		emit_signal("augmentation_activated", aug_id)
		return true
	return false

func deactivate_augmentation(aug_id: String) -> bool:
	if aug_id in augmentations and augmentations[aug_id]["active"]:
		augmentations[aug_id]["active"] = false
		active_augmentations.erase(aug_id)
		
		# Снимаем эффекты
		remove_augmentation_effects(aug_id)
		
		emit_signal("augmentation_deactivated", aug_id)
		return true
	return false

func apply_augmentation_effects(aug_id: String) -> void:
	var aug = augmentations[aug_id]
	
	# Применяем бонусы
	if "speed" in aug["bonuses"]:
		speed_modifier += aug["bonuses"]["speed"]
	
	if "reaction_time" in aug["bonuses"]:
		reaction_time_modifier -= aug["bonuses"]["reaction_time"]
	
	if "accuracy" in aug["bonuses"]:
		accuracy_modifier += aug["bonuses"]["accuracy"]
	
	if "strength" in aug["bonuses"]:
		strength_modifier += aug["bonuses"]["strength"]
	
	# Применяем негативные эффекты
	if "mental_stress" in aug["drawbacks"]:
		increase_mental_stress(aug["drawbacks"]["mental_stress"])
	
	if "thermal_state" in aug["drawbacks"]:
		increase_thermal_state(aug["drawbacks"]["thermal_state"])
	
	if "energy_consumption" in aug["drawbacks"]:
		increase_energy_consumption(aug["drawbacks"]["energy_consumption"])
	
	# Проверяем и применяем эффекты взаимодействия
	apply_interaction_effects(aug_id)

func remove_augmentation_effects(aug_id: String) -> void:
	var aug = augmentations[aug_id]
	
	# Снимаем бонусы
	if "speed" in aug["bonuses"]:
		speed_modifier -= aug["bonuses"]["speed"]
	
	if "reaction_time" in aug["bonuses"]:
		reaction_time_modifier += aug["bonuses"]["reaction_time"]
	
	if "accuracy" in aug["bonuses"]:
		accuracy_modifier -= aug["bonuses"]["accuracy"]
	
	if "strength" in aug["bonuses"]:
		strength_modifier -= aug["bonuses"]["strength"]
	
	# Снимаем эффекты взаимодействия
	remove_interaction_effects(aug_id)

func apply_interaction_effects(aug_id: String) -> void:
	var aug = augmentations[aug_id]
	
	# Проверяем взаимодействия с другими активными аугментациями
	if "interactions" in aug:
		for other_aug_id in aug["interactions"].keys():
			if other_aug_id in active_augmentations:
				var interaction = aug["interactions"][other_aug_id]
				
				# Применяем эффекты взаимодействия
				for effect in interaction.keys():
					match effect:
						"speed":
							speed_modifier += interaction[effect]
						"accuracy":
							accuracy_modifier += interaction[effect]
						"mental_stress":
							increase_mental_stress(interaction[effect])
						"thermal_state":
							increase_thermal_state(interaction[effect])
						"energy_consumption":
							increase_energy_consumption(interaction[effect])
						# ... другие эффекты

func remove_interaction_effects(aug_id: String) -> void:
	var aug = augmentations[aug_id]
	
	# Снимаем эффекты взаимодействия
	if "interactions" in aug:
		for other_aug_id in aug["interactions"].keys():
			if other_aug_id in active_augmentations:
				var interaction = aug["interactions"][other_aug_id]
				
				# Снимаем эффекты взаимодействия
				for effect in interaction.keys():
					match effect:
						"speed":
							speed_modifier -= interaction[effect]
						"accuracy":
							accuracy_modifier -= interaction[effect]
						# ... другие эффекты

func increase_mental_stress(value: float) -> void:
	mental_stress = min(mental_stress + value, 100.0)
	emit_signal("mental_stress_changed", mental_stress)
	check_mental_effects()

func decrease_mental_stress(value: float) -> void:
	mental_stress = max(mental_stress - value, 0.0)
	emit_signal("mental_stress_changed", mental_stress)

func increase_thermal_state(value: float) -> void:
	thermal_state = min(thermal_state + value, 100.0)
	emit_signal("thermal_state_changed", thermal_state)
	check_thermal_effects()

func decrease_thermal_state(value: float) -> void:
	thermal_state = max(thermal_state - value, 0.0)
	emit_signal("thermal_state_changed", thermal_state)

func increase_energy_consumption(value: float) -> void:
	energy_consumption = min(energy_consumption + value, 100.0)
	emit_signal("energy_consumption_changed", energy_consumption)
	check_energy_effects()

func decrease_energy_consumption(value: float) -> void:
	energy_consumption = max(energy_consumption - value, 0.0)
	emit_signal("energy_consumption_changed", energy_consumption)

func check_mental_effects() -> void:
	# Проверка на критическое состояние психики
	if mental_stress > 80.0:
		# Тяжелые галлюцинации
		get_parent().trigger_hallucination()
	elif mental_stress > 50.0:
		# Умеренные галлюцинации
		get_parent().decrease_sanity(mental_stress / 10.0)

func check_thermal_effects() -> void:
	# Проверка на перегрев
	if thermal_state > 90.0:
		# Критический перегрев - отключение всех аугментаций
		for aug_id in active_augmentations.keys():
			deactivate_augmentation(aug_id)
	elif thermal_state > 70.0:
		# Перегрев - снижение эффективности
		speed_modifier *= 0.7
		reaction_time_modifier *= 1.3
		accuracy_modifier *= 0.7

func check_energy_effects() -> void:
	# Проверка на истощение энергии
	if energy_consumption > 90.0:
		# Критическое истощение - отключение всех аугментаций
		for aug_id in active_augmentations.keys():
			deactivate_augmentation(aug_id)
	elif energy_consumption > 70.0:
		# Высокое потребление - снижение эффективности
		energy_recovery_modifier *= 0.5

func get_augmentation_info(aug_id: String) -> Dictionary:
	if aug_id in augmentations:
		return augmentations[aug_id]
	return {}

func get_all_augmentations() -> Dictionary:
	return augmentations

func get_installed_augmentations() -> Dictionary:
	return installed_augmentations

func get_active_augmentations() -> Dictionary:
	return active_augmentations

func update(delta: float) -> void:
	# Обновляем состояния и эффекты
	update_recovery(delta)
	update_stress_effects(delta)

func update_recovery(delta: float) -> void:
	# Постепенное восстановление
	if thermal_state > 0:
		decrease_thermal_state(delta * 2.0 * (1.0 + health_recovery_modifier))
	
	if energy_consumption > 0:
		decrease_energy_consumption(delta * 1.5 * energy_recovery_modifier)

func update_stress_effects(delta: float) -> void:
	# Постепенное восстановление психического состояния
	if mental_stress > 0:
		decrease_mental_stress(delta * 0.5)

func get_current_modifiers() -> Dictionary:
	return {
		"speed": speed_modifier,
		"strength": strength_modifier,
		"reaction_time": reaction_time_modifier,
		"accuracy": accuracy_modifier,
		"vision_range": vision_range_modifier,
		"energy_recovery": energy_recovery_modifier,
		"health_recovery": health_recovery_modifier,
		"cooldown": cooldown_modifier
	}
