# Компьютерный терминал
class_name InteractiveTerminal
extends InteractiveObject

@export var has_security: bool = false
@export var security_level: int = 1
@export var terminal_data: String = "No data available"
@export var terminal_hacked: bool = false

func _ready():
	super._ready()
	interaction_prompt = "Использовать терминал"
	interaction_time = 0.5  # Небольшая задержка для реалистичности

func _complete_interaction(actor):
	if has_security and not terminal_hacked:
		# Открываем мини-игру для взлома
		var hacking_game = preload("res://Scenes/Minigames/HackingGame.tscn").instantiate()
		actor.add_child(hacking_game)
		hacking_game.setup(security_level)
		hacking_game.connect("hacking_successful", _on_hacking_successful)
		hacking_game.connect("hacking_failed", _on_hacking_failed)
	else:
		# Показываем интерфейс терминала
		var terminal_ui = preload("res://Scenes/UI/TerminalUI.tscn").instantiate()
		actor.add_child(terminal_ui)
		terminal_ui.display_data(terminal_data)
	
	super._complete_interaction(actor)

func _on_hacking_successful():
	terminal_hacked = true
	# Показываем интерфейс терминала с данными
	var terminal_ui = preload("res://Scenes/UI/TerminalUI.tscn").instantiate()
	get_parent().add_child(terminal_ui)
	terminal_ui.display_data(terminal_data)

func _on_hacking_failed():
	# Возможная реакция на неудачный взлом (сигнализация, урон)
	pass
