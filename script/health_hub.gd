extends CanvasLayer

@onready var hearts := $MarginContainer/HBoxContainer.get_children()
var player = null


func _ready():
	# Va chercher le joueur dans la scène
	var p = get_tree().get_nodes_in_group("player")
	if p.size() > 0:
		player = p[0]

	# Met à jour la vie à chaque frame
	set_process(true)


func _process(delta):
	if player == null:
		return

	update_hearts(player.current_health, player.max_health)


func update_hearts(current: int, max_hp: int):
	for i in range(hearts.size()):
		if i < current:
			hearts[i].visible = true
		else:
			hearts[i].visible = false
