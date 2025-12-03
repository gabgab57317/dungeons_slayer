extends Area2D

##########################################
# 🧩 VARIABLES 🧩
##########################################
var damage: int = 1

##########################################
# ⚔️ ENABLE HIT ⚔️
# dmg -> dégâts que le hitbox inflige
##########################################
func enable_hit(dmg: int):
	damage = dmg
	monitoring = true
	await _deactivate_delayed()

##########################################
# ⏱️ DEACTIVATE AFTER SHORT TIME
##########################################
func _deactivate_delayed():
	await get_tree().create_timer(0.2).timeout
	monitoring = false

##########################################
# ⚔️ COLLISION WITH PLAYER
##########################################
func _on_area_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
