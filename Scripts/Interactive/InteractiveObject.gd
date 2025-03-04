extends Node3D

class_name InteractiveObject

signal interaction_started(object)
signal interaction_completed(object)

@export var interaction_prompt: String = "Взаимодействовать"
@export var interaction_time: float = 0.0  # Мгновенное взаимодействие, если 0
@export var can_interact: bool = true
@export var highlight_color: Color = Color(0.0, 0.7, 0.9)  # Киберпанк-голубой

# Ссылки на компоненты
var highlight_material: StandardMaterial3D
var original_materials = []
var is_highlighted = false
var interaction_progress = 0.0

func _ready():
	# Создаем материал подсветки
	highlight_material = StandardMaterial3D.new()
	highlight_material.emission_enabled = true
	highlight_material.emission = highlight_color
	highlight_material.emission_energy = 1.0
	
	# Сохраняем оригинальные материалы
	store_original_materials()

func store_original_materials():
	# Сохраняем оригинальные материалы дочерних мешей
	for child in get_children():
		if child is MeshInstance3D:
			var materials = []
			for i in range(child.get_surface_override_material_count()):
				materials.append(child.get_surface_override_material(i))
			original_materials.append({"node": child, "materials": materials})

func highlight(enable: bool):
	if enable == is_highlighted:
		return
		
	is_highlighted = enable
	
	if enable:
		# Подсвечиваем объект
		for child in get_children():
			if child is MeshInstance3D:
				for i in range(child.get_surface_override_material_count()):
					var original = child.get_surface_override_material(i)
					if original:
						var mixed_material = original.duplicate()
						mixed_material.emission_enabled = true
						mixed_material.emission = highlight_color
						mixed_material.emission_energy = 0.5
						child.set_surface_override_material(i, mixed_material)
	else:
		# Восстанавливаем оригинальные материалы
		for item in original_materials:
			var mesh = item["node"]
			var materials = item["materials"]
			for i in range(materials.size()):
				mesh.set_surface_override_material(i, materials[i])

func can_be_interacted() -> bool:
	return can_interact

func get_interaction_prompt() -> String:
	return interaction_prompt

func interact(actor):
	if not can_interact:
		return false
		
	emit_signal("interaction_started", self)
	
	if interaction_time <= 0:
		# Мгновенное взаимодействие
		_complete_interaction(actor)
		return true
	else:
		# Длительное взаимодействие
		return false  # Будет обрабатываться в _process

func _process_interaction(actor, delta: float) -> bool:
	if interaction_progress < 1.0:
		interaction_progress += delta / interaction_time
		if interaction_progress >= 1.0:
			interaction_progress = 1.0
			_complete_interaction(actor)
			return true
	return false

func _complete_interaction(actor):
	# Переопределяется в подклассах
	emit_signal("interaction_completed", self)

func cancel_interaction():
	interaction_progress = 0.0
