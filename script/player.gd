extends CharacterBody2D

@export var speed: float = 150.0
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.15
@export var max_health: int = 100

var current_health: int = max_health
var is_dead := false
var facing_right := true
var can_attack := true
var can_move := true
var can_take_damage := true
var is_dashing := false
var attack_in_progress := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

func _ready():
	add_to_group("player")
	anim.play("idle_player")

func _physics_process(_delta):
	if is_dead:
		return

	var direction := Vector2.ZERO

	if can_move and not is_dashing and not attack_in_progress:
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1
		if Input.is_action_pressed("ui_down"):
			direction.y += 1
		if Input.is_action_pressed("ui_left"):
			facing_right = false
			direction.x -= 1
		if Input.is_action_pressed("ui_right"):
			facing_right = true
			direction.x += 1

	anim.flip_h = not facing_right
	attack_area.position.x = 20 * (1 if facing_right else -1)

	if can_move and not is_dashing and not attack_in_progress:
		velocity = direction.normalized() * speed
		move_and_slide()
		if direction != Vector2.ZERO:
			play_anim_safe("walk_player")
		else:
			play_anim_safe("idle_player")

	if can_attack and not is_dashing:
		if Input.is_action_just_pressed("attack1"):
			do_attack("attack1_player", 10)
		elif Input.is_action_just_pressed("attack2"):
			do_attack("attack2_player", 20)

	if Input.is_action_just_pressed("dash") and not is_dashing:
		start_dash(direction)

func do_attack(animation_name: String, dmg: int):
	if attack_in_progress:
		return
	attack_in_progress = true
	can_move = false
	can_attack = false
	velocity = Vector2.ZERO
	play_anim_safe(animation_name)
	await anim.animation_finished
	check_attack_hit(dmg)
	attack_in_progress = false
	can_move = true
	can_attack = true
	play_anim_safe("idle_player")

func check_attack_hit(dmg):
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(dmg)

func start_dash(direction):
	is_dashing = true
	can_move = false
	can_attack = false
	can_take_damage = false
	if direction == Vector2.ZERO:
		direction = Vector2(1 if facing_right else -1, 0)
	play_anim_safe("dash_player")
	velocity = direction.normalized() * dash_speed
	var t = get_tree().create_timer(dash_duration)
	while t.time_left > 0:
		move_and_slide()
		await get_tree().process_frame
	is_dashing = false
	can_move = true
	can_attack = true
	can_take_damage = true
	play_anim_safe("idle_player")

func take_damage(dmg):
	if not can_take_damage or is_dead:
		return
	current_health -= dmg
	can_take_damage = false
	await blink_red()
	if current_health <= 0:
		die()
		return
	await get_tree().create_timer(1.0).timeout
	can_take_damage = true

func blink_red():
	for i in range(3):
		anim.modulate = Color(1,0.2,0.2)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout

func die():
	is_dead = true
	can_move = false
	can_attack = false
	play_anim_safe("death_player")
	await anim.animation_finished
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func heal_full():
	current_health = max_health

@warning_ignore("shadowed_variable_base_class")
func play_anim_safe(name: String):
	if anim.animation != name:
		anim.play(name)
