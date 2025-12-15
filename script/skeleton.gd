extends CharacterBody2D

##########################################
# 🌟 EXPORTS 🌟
##########################################
@export var speed: float = 50.0                 # 🏃 Vitesse de déplacement
@export var detection_range: float = 150.0     # 👀 Distance de détection du joueur
@export var max_health: int = 25                 # ❤️ Vie maximale
@export var attack_cooldown: float = 3.5       # ⏱️ Temps entre attaques

##########################################
# 🧩 VARIABLES 🧩
##########################################
var current_health: int = max_health           # ❤️ Vie actuelle
var is_dead: bool = false                      # Mort
var is_attacking: bool = false                 # En attaque
var can_attack: bool = true                    # Peut attaquer
var can_take_damage: bool = true               # Peut prendre des dégâts
var attack_counter: int = 0                    # Compteur pour varier les attaques
var player: CharacterBody2D = null             # Joueur ciblé

# ⚔️ Gestion des dégâts sur un frame spécifique
var attack_damage: int = 1
var damage_frame: int = 7                      # 6ᵉ frame (index 0 = frame 1)
var damage_done_this_attack: bool = false

##########################################
# 🔗 NODES 🔗
##########################################
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

##########################################
# 🚀 READY 🚀
##########################################
func _ready():
	add_to_group("enemy2")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	anim.play("idle_skeleton")

	# 🔔 Connecte le signal pour vérifier le frame courant
	anim.connect("frame_changed", Callable(self, "_on_frame_changed"))

##########################################
# 🏃 PHYSICS PROCESS 🏃
##########################################
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if is_dead or anim.animation == "death_skeleton":
		velocity = Vector2.ZERO
		return

	if player == null or player.is_dead:
		velocity = Vector2.ZERO
		if anim.animation != "idle_skeleton":
			anim.play("idle_skeleton")
		return

	var dist = position.distance_to(player.position)

	# ---------- 🏃 POURSUIVRE LE JOUEUR ----------
	if dist <= detection_range and not is_attacking:
		chase_player()
	else:
		velocity = Vector2.ZERO
		if not is_attacking and anim.animation != "idle_skeleton":
			anim.play("idle_skeleton")

	move_and_slide()

	# ---------- ⚔️ VÉRIFIER SI PEUT ATTAQUER ----------
	if not is_attacking and can_attack:
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player") and not body.is_dead:
				start_attack()
				break

##########################################
# 🏃 CHASE PLAYER 🏃
##########################################
func chase_player():
	var dir = (player.position - position).normalized()
	velocity = dir * speed

	# ---------- 🎨 FLIP SPRITE ----------
	if dir.x < 0:
		anim.flip_h = true
		attack_area.position.x = -abs(attack_area.position.x)
	else:
		anim.flip_h = false
		attack_area.position.x = abs(attack_area.position.x)

	if not is_attacking and anim.animation != "walk_skeleton":
		anim.play("walk_skeleton")

##########################################
# ⚔️ START ATTACK ⚔️
##########################################
func start_attack() -> void:
	is_attacking = true
	can_attack = false
	damage_done_this_attack = false   # 🔄 Reset avant attaque
	velocity = Vector2.ZERO

	anim.play("attack_enemy_skeleton")

	# ✅ Attendre fin animation
	await anim.animation_finished
	is_attacking = false

	# ⏱️ Cooldown avant prochaine attaque
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

##########################################
# ⚡ FRAME-BASED DAMAGE ⚡
##########################################
func _on_frame_changed():
	if not is_attacking:
		return

	if anim.animation == "attack_enemy_skeleton":
		if anim.frame == damage_frame and not damage_done_this_attack:
			damage_done_this_attack = true
			perform_attack(attack_damage)

##########################################
# ⚔️ PERFORM ATTACK ⚔️
##########################################
func perform_attack(damage: int):
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and not body.is_dead:
			body.take_damage(damage)

##########################################
# ❤️ TAKE DAMAGE ❤️
##########################################
func take_damage(damage: int) -> void:
	if is_dead or not can_take_damage:
		return

	current_health -= damage
	can_take_damage = false

	# ⚡ BLINK DAMAGE
	blink_effect()

	# ☠️ Vérifie mort
	if current_health <= 0:
		await die()
		return

	# ⏱️ Invincibilité temporaire
	await get_tree().create_timer(0.6).timeout
	can_take_damage = true

##########################################
# ⚡ BLINK EFFECT ⚡
##########################################
func blink_effect() -> void:
	_do_blink()

func _do_blink() -> void:
	for i in range(3):
		anim.modulate = Color(1,1,1,0.2)  # Transparent
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1,1,1,1)    # Normal
		await get_tree().create_timer(0.1).timeout

##########################################
# ☠️ DIE ☠️
##########################################
func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	# 🔒 Désactiver collisions et hitbox
	if collision_shape:
		collision_shape.disabled = true
	if attack_area:
		attack_area.monitoring = false

	# 🎨 Animation mort
	anim.play("death_skeleton")
	await anim.animation_finished
	velocity = Vector2.ZERO
	queue_free()
