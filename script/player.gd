extends CharacterBody2D

@export var speed: float = 150.0
@export var max_health: int = 6
var current_health: int = max_health
var is_dead: bool = false

var facing_right: bool = true
var can_attack: bool = true
var can_take_damage: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea


func _ready():
	add_to_group("player")
	anim.play("idle_player")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var direction := Vector2.ZERO

	# === MOUVEMENT ===
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		facing_right = false
		anim.flip_h = true
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		facing_right = true
		anim.flip_h = false
		direction.x += 1

	# === POSITION HITBOX ===
	attack_area.position.x = abs(attack_area.position.x) * (1 if facing_right else -1)

	# === MOUVEMENT BLOQUÉ PENDANT L’ATTAQUE ===
	if can_attack:
		velocity = direction.normalized() * speed
		move_and_slide()

		# === ANIMATIONS ===
		if direction != Vector2.ZERO:
			anim.play("walk_player")
		else:
			anim.play("idle_player")

	# === ATTAQUES ===
	if Input.is_action_just_pressed("attack1") and can_attack:
		do_attack(1)
	elif Input.is_action_just_pressed("attack2") and can_attack:
		do_attack(2)


# --- ATTAQUE ---
func do_attack(dmg: int) -> void:
	can_attack = false
	velocity = Vector2.ZERO

	if dmg == 1:
		anim.play("attack1_player")
	else:
		anim.play("attack2_player")

	await anim.animation_finished
	check_attack_hit(dmg)
	can_attack = true


func check_attack_hit(dmg: int) -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(dmg)


# --- PRENDRE DES DÉGÂTS ---
func take_damage(dmg: int) -> void:
	if not can_take_damage or is_dead:
		return

	current_health -= dmg
	can_take_damage = false

	# === CLIGNOTEMENT ROUGE ===
	await blink_red()

	if current_health <= 0:
		die()
		return

	# === INVINCIBILITÉ TEMPORAIRE ===
	await get_tree().create_timer(0.8).timeout
	can_take_damage = true


# --- EFFET CLIGNOTEMENT ---
func blink_red():
	for i in range(3):
		anim.modulate = Color(1, 0.2, 0.2, 0.4)  # rouge transparent
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1, 1)  # normal
		await get_tree().create_timer(0.1).timeout


# --- MORT ---
func die():
	if is_dead:
		return

	is_dead = true
	anim.play("death_player")
	set_physics_process(false)

	await anim.animation_finished
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


# --- HEAL COMPLET ---
func heal_full():
	current_health = max_health
