extends CanvasLayer

##########################################
# 🔗 NODES 🔗
##########################################
@onready var hearts := $MarginContainer/HBoxContainer.get_children()  # ❤️ Les cœurs
var player = null                                                         # 👤 Référence au joueur

##########################################
# 🚀 READY 🚀
##########################################
func _ready():
	# ---------- 👤 Cherche le joueur dans la scène ----------
	var p = get_tree().get_nodes_in_group("player")
	if p.size() > 0:
		player = p[0]

	# ---------- ⚡ Met à jour la vie à chaque frame ----------
	set_process(true)

##########################################
# 🏃 PROCESS 🏃
##########################################
func _process(_delta):
	if player == null:
		return

	update_hearts(player.current_health, player.max_health)

##########################################
# ❤️ UPDATE HEARTS ❤️
##########################################
func update_hearts(current: int, _max_hp: int):
	for i in range(hearts.size()):
		if i < current:
			hearts[i].visible = true
		else:
			hearts[i].visible = false
