extends Node2D

@export var pickup_sound: AudioStreamPlayer2D
var picked_up := false

@onready var area: Area2D = $Area2D


func _ready():
	area.connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	if picked_up:
		return

	if body.is_in_group("player"):

		# === FULL HEAL ===
		if body.has_method("heal_full"):
			body.heal_full()

		picked_up = true

		# === SOUND ===
		if pickup_sound:
			pickup_sound.play()

		# === DISAPPEAR ANIMATION ===
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
		tween.tween_callback(Callable(self, "queue_free"))
