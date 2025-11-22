extends Node2D

# Optionnel : tu peux mettre un son à jouer
@export var pickup_sound: AudioStreamPlayer2D

var picked_up: bool = false

func _ready():
	# Connecte le signal pour détecter quand un corps entre dans l'Area2D
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	if picked_up:
		return

	# Vérifie si le corps appartient au joueur
	if body.is_in_group("player"):
		picked_up = true

		# ✅ Remet le joueur à sa vie maximale
		if body.has_method("heal_full"):
			body.heal_full()

		# ✅ Joue un son si défini
		if pickup_sound:
			pickup_sound.play()

		# ✅ Disparaît visuellement avec un petit effet
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(Callable(self, "queue_free"))
