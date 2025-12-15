extends Node2D

@onready var beam_anim: AnimatedSprite2D = get_parent().get_node("Sprite")
@onready var hitbox: Area2D = get_parent().get_node("Hurtbox")

@export var fire_duration: float = 0.30
var is_firing := false

func fire():
	if is_firing:
		return

	is_firing = true
	beam_anim.play("fire")
	hitbox.monitoring = true
	hitbox.visible = true

	await get_tree().create_timer(fire_duration).timeout

	beam_anim.play("off")
	hitbox.monitoring = false
	hitbox.visible = false
	is_firing = false
