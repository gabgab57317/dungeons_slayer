extends Node2D

##########################################
# 🌟 EXPORTS 🌟
##########################################
@export var speed: float = 300      # 🏃 Vitesse du projectile
@export var damage: int = 1         # ⚔️ Dégâts infligés
@export var life_time: float = 2.0  # ⏱️ Durée avant disparition

##########################################
# 🧩 VARIABLES 🧩
##########################################
var direction: Vector2 = Vector2.ZERO  # 🎯 Direction de déplacement

##########################################
# 🔗 NODES 🔗
##########################################
@onready var sprite: Sprite2D = $AnimatedSprite2D  # 🎨 Animation du projectile
@onready var area: Area2D = $Area2D                        # ⚔️ Zone de dégâts
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D  # ⚡ Collision

##########################################
# 🚀 READY 🚀
##########################################
func _ready():
	if sprite:
		sprite.play("idle")  # Animation par défaut
	if area:
		area.monitoring = true
	if collision:
		collision.disabled = false

	# ⏱️ Auto-destruction après life_time secondes
	await get_tree().create_timer(life_time).timeout
	queue_free()

##########################################
# 🏃 PHYSICS PROCESS 🏃
##########################################
func _physics_process(delta):
	if direction != Vector2.ZERO:
		global_position += direction.normalized() * speed * delta

##########################################
# ⚔️ COLLISION ⚔️
##########################################
func _on_area_entered(body):
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
