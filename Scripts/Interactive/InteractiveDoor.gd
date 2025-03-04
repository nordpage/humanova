# Дверь
class_name InteractiveDoor
extends InteractiveObject

@export var is_locked: bool = false
@export var key_id: String = ""
@export var door_open_sound: AudioStream
@export var door_locked_sound: AudioStream

var is_open: bool = false
var animation_player: AnimationPlayer

func _ready():
	super._ready()
	interaction_prompt = "Открыть дверь" if not is_locked else "Дверь заперта"
	animation_player = $AnimationPlayer
	
	if not animation_player:
		push_error("InteractiveDoor needs an AnimationPlayer with 'open' and 'close' animations")

func _complete_interaction(actor):
	if is_locked:
		# Проверяем, есть ли у актора ключ
		var inventory = actor.get_node_or_null("Inventory")
		if inventory and inventory.has_item(key_id):
			is_locked = false
			interaction_prompt = "Открыть дверь"
			play_sound(door_open_sound)
			# Показываем уведомление
			actor.show_notification("Дверь разблокирована")
		else:
			play_sound(door_locked_sound)
			actor.show_notification("Требуется ключ")
	else:
		# Переключаем состояние двери
		is_open = !is_open
		if is_open:
			animation_player.play("door")
			play_sound(door_open_sound)
		else:
			animation_player.play_backwards("door")
			play_sound(door_open_sound)
	
	super._complete_interaction(actor)

func play_sound(sound: AudioStream):
	if sound:
		var audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
		audio_player.stream = sound
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
