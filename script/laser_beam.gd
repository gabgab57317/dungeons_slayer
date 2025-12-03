extends Node2D

##########################################
# 🌟 EXPORTS 🌟
##########################################
@export var damage: int = 2
@export var life_time: float = 2.0       # Durée du laser actif

##########################################
# 🔗 NODES 🔗
##########################################
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

##########################################
# 🚀 READY 🚀
##########################################
func _ready():
	visible = false
	anim.visible = false
	anim.stop()
	area.monitoring = false
	area.body_entered.connect(Callable(self, "_on_body_entered"))

##########################################
# ⚡ FIRE LASER ⚡
##########################################
func fire():
	visible = true
	anim.visible = true

	# Jouer animation de tir
	anim.play("Fire")
	area.monitoring = true

	# Durée du laser
	await get_tree().create_timer(life_time).timeout

	# Désactive laser
	area.monitoring = false
	anim.play("Off")      # Animation d'extinction
	anim.visible = false
	visible = false

##########################################
# 💥 HITBOX 💥
##########################################
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not body.is_dead:
		if body.has_method("take_damage"):
			body.take_damage(damage)
