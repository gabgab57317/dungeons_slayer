extends CanvasLayer

##########################################
# 🌟 NODES 🌟
##########################################
@onready var health_fill: ColorRect = $HealthFill   # ❤️ Vie normale
@onready var armor_fill: ColorRect = $ArmorFill     # 🛡️ Armor (bonus)
@onready var background: TextureRect = $Background # ░ Fond de la barre (PNG)

##########################################
# ❤️ UPDATE HEALTH ❤️
# hp       -> vie actuelle
# max_hp   -> vie max
# armor    -> points d’armor (bleu)
##########################################
func update_health(hp: int, max_hp: int, armor: int = 0):
	if health_fill:
		health_fill.rect_scale.x = clamp(float(hp)/float(max_hp),0,1)
	if armor_fill:
		armor_fill.rect_scale.x = clamp(float(armor)/float(max_hp),0,1)
