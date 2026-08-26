extends AnimatedSprite2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FightManager.star_awarded_signal.connect(play_anim)
	
func play_anim():
	animation_player.play("award_star")
