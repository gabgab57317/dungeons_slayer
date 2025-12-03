extends CharacterBody2D

##################################################
# ⚡ EXPORTS
##################################################
@export var speed: float = 160.0
@export var max_health: int = 100
@export var melee_damage: int = 3
@export var melee_cooldown: float = 8.0
@export var projectile_scene: PackedScene
@export var projectile_cooldown: float = 10.0
@export var laser_beam: Node2D
@export var laser_cooldown: float = 180.0  # 3 minutes

##################################################
# 🛡 VARIABLES
##################################################
var current_health: int
var is_dead: bool = false
var is_attacking: bool = false
var can_melee: bool = true
var can_projectile: bool = true
var can_laser: bool = true
var player: CharacterBody2D = null
var phase2_started: bool = false
var is_charging_laser: bool = false

##################################################
# 🔗 NODES
##################################################
@onready var anim: AnimatedSprite2D = $Sprite
@onready var melee_area: Area2D = $MeleeArea

##################################################
# 🚀 READY
##################################################
func _ready():
	current_health = max_health
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	anim.play("Idle")

##################################################
# ⏱ PHYSICS PROCESS
##################################################
func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		return

	# ✅ START PHASE 2
	if not phase2_started and current_health <= max_health * 0.5:
		start_phase2()

	# 🚶 MOVEMENT STRATEGIQUE
	strategic_move(delta)

	# ⚔️ ATTAQUE
	if not is_attacking and player:
		var dist = position.distance_to(player.position)
		if dist <= 50 and can_melee:
			start_melee()
		elif dist <= 300 and can_projectile:
			start_projectile()
		elif dist <= 400 and can_laser:
			start_laser()

##################################################
# 🚶 WALK STRATEGIQUE
##################################################
func strategic_move(delta):
	if is_attacking or is_charging_laser or player == null:
		velocity = Vector2.ZERO
		if anim.animation != "Idle":
			anim.play("Idle")
		return

	var dir_to_player = (player.global_position - global_position)
	var distance = dir_to_player.length()
	var move_dir = Vector2.ZERO

	if distance > 100:
		move_dir = dir_to_player.normalized()  # approche
	elif distance < 70:
		move_dir = -dir_to_player.normalized() # recule
	else:
		move_dir = Vector2(-dir_to_player.y, dir_to_player.x).normalized() * 0.5  # esquive

	velocity = move_dir * speed
	move_and_slide()

	if move_dir.x < 0:
		anim.flip_h = true
	else:
		anim.flip_h = false

	if anim.animation != "Walk" and not is_attacking:
		anim.play("Walk")

##################################################
# ⚔️ MELEE ATTACK
##################################################
func start_melee():
	is_attacking = true
	can_melee = false
	velocity = Vector2.ZERO
	anim.play("Melee")
	await get_tree().create_timer(0.2).timeout
	perform_melee()
	await anim.animation_finished
	is_attacking = false
	await get_tree().create_timer(melee_cooldown).timeout
	can_melee = true

func perform_melee():
	for body in melee_area.get_overlapping_bodies():
		if body.is_in_group("player") and not body.is_dead:
			body.take_damage(melee_damage)

##################################################
# 💥 PROJECTILE ATTACK
##################################################
func start_projectile():
	is_attacking = true
	can_projectile = false
	velocity = Vector2.ZERO
	anim.play("RangeAttack")
	await get_tree().create_timer(0.3).timeout
	shoot_projectile()
	await anim.animation_finished
	is_attacking = false
	await get_tree().create_timer(projectile_cooldown).timeout
	can_projectile = true

func shoot_projectile():
	if projectile_scene and player:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		var dir = (player.global_position - global_position).normalized()
		proj.direction = dir
		get_parent().add_child(proj)

##################################################
# ⚡ LASER ATTACK
##################################################
func start_laser():
	is_attacking = true
	can_laser = false
	is_charging_laser = true
	velocity = Vector2.ZERO

	# Animation charge
	anim.play("Charge")
	await anim.animation_finished
	is_charging_laser = false

	# Fire laser
	laser_beam.fire()
	await get_tree().create_timer(laser_cooldown).timeout
	can_laser = true
	is_attacking = false

##################################################
# 💠 PHASE 2 GLOW + BLOCK + ARMOR
##################################################
func start_phase2():
	phase2_started = true
	velocity = Vector2.ZERO
	is_attacking = true

	anim.play("Glowing")
	await anim.animation_finished
	is_attacking = false

	# Active block et armor buff uniquement en phase2
	# Code block/armor à ajouter ici selon tes besoins

	# Soigne le joueur à max health
	if player:
		player.current_health = player.max_health

##################################################
# ❤️ TAKE DAMAGE
##################################################
func take_damage(dmg: int):
	if is_dead:
		return

	# ✅ Clignotement rouge
	_do_blink()
	current_health -= dmg

	if current_health <= 0:
		die()

func _do_blink():
	for i in range(3):
		anim.modulate = Color(1,0.2,0.2,0.4)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1,1,1,1)
		await get_tree().create_timer(0.1).timeout

##################################################
# ☠️ DEATH
##################################################
func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("Death")
	await anim.animation_finished
	queue_free()
