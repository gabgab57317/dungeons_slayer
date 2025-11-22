extends Area2D

@export var heal_amount: int = 9999  # grande valeur pour remettre full HP
@export var pickup_sound: AudioStreamPlayer2D

var picked_up: bool = false


func _ready():
	# Connecte le signal de détection automatique
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	if picked_up:
		return

	# Vérifie si le corps est un joueur
	if body.is_in_group("player"):
		picked_up = true

		# ✅ Remet le joueur à son max de vie
		if body.has_method("max_health") and body.has_method("current_health"):
			# (Si ton player n'a pas de setter, on fait directement :)
			body.current_health = body.max_health
		else:
			# Sinon, tu peux aussi créer une méthode dans le joueur : heal_full()
			if body.has_method("heal_full"):
				body.heal_full()

		# ✅ Joue un son s’il y en a un
		if pickup_sound:
			pickup_sound.play()

		# ✅ Effet visuel facultatif (petite disparition)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(Callable(self, "queue_free"))
