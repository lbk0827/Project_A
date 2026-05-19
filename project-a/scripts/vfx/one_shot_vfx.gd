extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	anim.animation_finished.connect(queue_free)
	anim.play()
