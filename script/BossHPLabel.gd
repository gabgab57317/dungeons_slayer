extends Label

@export var shake_threshold: float = 0.3
@export var shake_magnitude: float = 2.0
@export var blink_time: float = 0.1
@export var fade_time: float = 1.0

var max_hp: int = 100
var current_hp: int = 100
var buff_hp: int = 0
var flashing: bool = false
var is_dead: bool = false
var is_blocking: bool = false

func _ready():
	text = "HP: " % current_hp
	visible = false

func update_health(new_hp: int, new_max: int, new_buff: int=0, blocking: bool=false):
	current_hp = clamp(new_hp, 0, new_max)
	max_hp = new_max
	buff_hp = new_buff
	is_blocking = blocking
	
	var display_text := ""
	if is_blocking:
		display_text += "%d" % current_hp
	else:
		display_text += "%d" % current_hp
	
	if buff_hp > 0:
		display_text += "+%d" % buff_hp
	
	text = "HP: %s" % display_text
	
	if float(current_hp) / max_hp <= shake_threshold:
		shake_label()

func flash_damage():
	if flashing:
		return
	flashing = true
	var original_color = modulate
	modulate = Color(1,0.3,0.3)
	await get_tree().create_timer(blink_time).timeout
	modulate = original_color
	flashing = false

func shake_label():
	var original_pos = position
	for i in range(5):
		@warning_ignore("narrowing_conversion")
		position = original_pos + Vector2(randi_range(-shake_magnitude, shake_magnitude), randi_range(-shake_magnitude, shake_magnitude))
		await get_tree().create_timer(0.03).timeout
	position = original_pos

func fade_out():
	if is_dead:
		return
	is_dead = true
	var t := 0.0
	var _original_modulate = modulate
	while t < fade_time:
		t += get_process_delta_time()
		modulate.a = lerp(1.0, 0.0, t / fade_time)
		await get_tree().process_frame
	queue_free()
