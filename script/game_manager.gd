extends Node

@export var player_path: NodePath
@export var teleport_point_path: NodePath

@export var flash_times: int = 3
@export var flash_color: Color = Color(0.3, 0.5, 1)
@export var flash_interval: float = 0.15
@export var teleport_delay: float = 0.5

var has_teleported: bool = false  # Assure que la téléportation ne se fait qu'une fois

func _process(_delta):
	if has_teleported:
		return  # Ne rien faire si le joueur a déjà été téléporté

	var player = get_node_or_null(player_path)
	if player == null or player.is_dead:
		return

	var enemies = get_tree().get_nodes_in_group("enemy1")
	if enemies.size() == 0:
		has_teleported = true
		start_teleport_sequence(player)


func start_teleport_sequence(player: Node) -> void:
	var teleport_point = get_node_or_null(teleport_point_path)
	if teleport_point == null:
		push_error("ERREUR: teleport_point_path invalide")
		return

	# Bloque le joueur
	player.can_attack = false
	player.can_take_damage = false
	player.set_physics_process(false)

	flash_and_teleport(player, teleport_point)


func flash_and_teleport(player: Node, teleport_point: Node) -> void:
	# On suppose que player.anim existe
	var sprite = player.anim
	var original_color = sprite.modulate

	# Clignotement bleu
	for i in range(flash_times):
		sprite.modulate = flash_color
		await get_tree().create_timer(flash_interval).timeout
		sprite.modulate = original_color
		await get_tree().create_timer(flash_interval).timeout

	await get_tree().create_timer(teleport_delay).timeout

	# Téléportation
	player.global_position = teleport_point.global_position
	print("Player téléporté !")

	# Réactive le joueur
	player.set_physics_process(true)
	player.can_attack = true
	player.can_take_damage = true
