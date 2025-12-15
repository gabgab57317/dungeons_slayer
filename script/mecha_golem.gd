extends CharacterBody2D

@export var speed: float = 160.0
@export var max_health: int = 100
@export var melee_damage: int = 3
@export var melee_cooldown: float = 8.0
@export var projectile_scene: PackedScene
@export var projectile_cooldown: float = 10.0

var current_health: int
var is_dead := false
var is_attacking := false
var phase2_started := false
var start_played := false
var fight_started := false

var can_melee := true
var can_projectile := true
var can_laser := true

var player: CharacterBody2D

@onready var melee_timer: Timer = $Timers/melee_timer
@onready var projectile_timer: Timer = $Timers/ranged_timer
@onready var laser_timer: Timer = $Timers/laser_timer

@export var boss_health_bar_path: NodePath
var boss_health_bar: Node = null

@onready var anim: AnimatedSprite2D = $Sprite
@onready var melee_area: Area2D = $AttackHitbox

func _ready():
	current_health = max_health
	add_to_group("enemy")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	if boss_health_bar_path != null and boss_health_bar_path != NodePath(""):
		boss_health_bar = get_node_or_null(boss_health_bar_path)
		if boss_health_bar:
			boss_health_bar.visible = false

	melee_timer.wait_time = melee_cooldown
	melee_timer.one_shot = false
	projectile_timer.wait_time = projectile_cooldown
	projectile_timer.one_shot = false

	anim.play("start")
	anim.frame = 0
	anim.stop()

func _physics_process(delta):
	if is_dead or player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	# START animation à 100px
	if not start_played and dist < 100:
		start_played = true
		anim.play("start")
		anim.frame = 0
		await anim.animation_finished
		fight_started = true
		if boss_health_bar:
			boss_health_bar.visible = true
			boss_health_bar.update_health(current_health, max_health)

	if not fight_started:
		return

	# Mise à jour de la vie
	if boss_health_bar:
		boss_health_bar.update_health(current_health, max_health)

	# Phase 2 à 50%
	if not phase2_started and current_health <= max_health * 0.5:
		await start_phase2()

	# Pas de déplacement pendant les attaques
	if is_attacking:
		return

	strategic_move(delta)

	if dist <= 50 and can_melee and melee_timer.is_stopped():
		start_melee()
	elif dist <= 300 and can_projectile and projectile_timer.is_stopped():
		start_projectile()

func strategic_move(_delta):
	var dir = player.global_position - global_position
	var d = dir.length()
	var mv = Vector2.ZERO

	if d > 100:
		mv = dir.normalized()
	elif d < 70:
		mv = -dir.normalized()
	else:
		mv = Vector2(-dir.y, dir.x).normalized() * 0.5

	velocity = mv * speed
	move_and_slide()
	anim.flip_h = mv.x < 0

	if anim.animation != "Walk" and not is_attacking:
		anim.play("Walk")

func start_melee():
	is_attacking = true
	can_melee = false
	velocity = Vector2.ZERO
	anim.play("Melee")

	# Dégat seulement à la frame 4
	await anim.frame_changed
	while anim.frame < 3:
		await anim.frame_changed
	perform_melee()

	await anim.animation_finished
	is_attacking = false
	melee_timer.start()

func perform_melee():
	if melee_area:
		for body in melee_area.get_overlapping_bodies():
			if body.is_in_group("player") and not body.is_dead:
				body.take_damage(melee_damage)
	if boss_health_bar:
		boss_health_bar.flash_damage()

func start_projectile():
	is_attacking = true
	can_projectile = false
	velocity = Vector2.ZERO
	anim.play("RangeAttack")

	# Projectile à la frame 8
	await anim.frame_changed
	while anim.frame < 7:
		await anim.frame_changed

	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = (player.global_position - global_position).normalized()
		get_parent().add_child(proj)

	await anim.animation_finished
	is_attacking = false
	projectile_timer.start()

func start_phase2():
	phase2_started = true
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("Glowing")
	await anim.animation_finished
	is_attacking = false

func take_damage(dmg):
	if is_dead:
		return
	current_health -= dmg
	if boss_health_bar:
		boss_health_bar.flash_damage()
	if current_health <= 0:
		await die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("Death")
	await anim.animation_finished
	if boss_health_bar:
		boss_health_bar.fade_out()
	queue_free()
