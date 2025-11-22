extends CharacterBody2D

@export var speed: float = 50.0
@export var detection_range: float = 150.0
@export var max_health: int = 1
@export var attack_cooldown: float = 1.2

var current_health: int = max_health
var is_dead: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var can_take_damage: bool = true
var attack_counter: int = 0
var player: CharacterBody2D = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	add_to_group("enemy1")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	anim.play("idle_orc")


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if is_dead or anim.animation == "death_orc":
		velocity = Vector2.ZERO
		return

	if player == null or player.is_dead:
		velocity = Vector2.ZERO
		if anim.animation != "idle_orc":
			anim.play("idle_orc")
		return

	var dist = position.distance_to(player.position)

	# Poursuit le joueur s’il est proche
	if dist <= detection_range and not is_attacking:
		chase_player()
	else:
		velocity = Vector2.ZERO
		if not is_attacking and anim.animation != "idle_orc":
			anim.play("idle_orc")

	move_and_slide()

	# Vérifie si peut attaquer
	if not is_attacking and can_attack:
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player") and not body.is_dead:
				start_attack()
				break


func chase_player():
	var dir = (player.position - position).normalized()
	velocity = dir * speed

	# Flip du sprite selon la direction
	if dir.x < 0:
		anim.flip_h = true
		attack_area.position.x = -abs(attack_area.position.x)
	else:
		anim.flip_h = false
		attack_area.position.x = abs(attack_area.position.x)

	if not is_attacking and anim.animation != "walk_orc":
		anim.play("walk_orc")


func start_attack() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO

	# 1 attaque sur 3 = attaque 2
	attack_counter += 1
	var damage := 1
	var anim_name := "attack_enemy_1_orc"

	if attack_counter >= 3:
		attack_counter = 0
		damage = 2
		anim_name = "attack_enemy_2_orc"

	anim.play(anim_name)

	await get_tree().create_timer(0.15).timeout
	perform_attack(damage)

	await anim.animation_finished
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func perform_attack(damage: int):
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and not body.is_dead:
			body.take_damage(damage)


func take_damage(damage: int) -> void:
	if is_dead or not can_take_damage:
		return

	current_health -= damage
	can_take_damage = false

	# ✅ Fait clignoter le sprite quand il prend un coup
	blink_effect()

	# Vérifie si mort
	if current_health <= 0:
		await die()
		return

	# Délai avant de pouvoir être touché à nouveau
	await get_tree().create_timer(0.6).timeout
	can_take_damage = true


func blink_effect() -> void:
	_do_blink()


func _do_blink() -> void:
	for i in range(3):
		anim.modulate = Color(1, 1, 1, 0.2)  # transparent
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1, 1)    # normal
		await get_tree().create_timer(0.1).timeout


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	# Désactive collisions et hitbox
	if collision_shape:
		collision_shape.disabled = true
	if attack_area:
		attack_area.monitoring = false

	# ✅ Joue l’animation de mort et garde le corps au sol
	anim.play("death_orc")
	await anim.animation_finished
	velocity = Vector2.ZERO
	queue_free()
