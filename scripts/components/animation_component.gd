class_name AnimationComponent extends Node


@onready var anim_sprite: AnimatedSprite2D = %"Player Sprite"

var tween : Tween = null
const anim_speed := 0.3
const anim_distance := 16.0

func _ready() -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func dodge_animation(direction : String):
	if direction == "right":
		print("dodge right animation")
		reset_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(anim_sprite, "position", Vector2(anim_sprite.position.x + anim_distance, 0.0), anim_speed)
		tween.tween_property(anim_sprite, "position", Vector2(anim_sprite.position.x, 0.0), anim_speed)
	
	elif direction == "left":
		print("dodge left animation")
		reset_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(anim_sprite, "position", Vector2(anim_sprite.position.x - anim_distance, 0.0), anim_speed)
		tween.tween_property(anim_sprite, "position", Vector2(anim_sprite.position.x, 0.0), anim_speed)
	else:
		print("Invalid direction. Animation component.")
		
func low_punch_animation(_direction):
	anim_sprite.play("low")
	await anim_sprite.animation_finished
	anim_sprite.play("idle")
	
func high_punch_animation(_direction):
	anim_sprite.play("high")
	await anim_sprite.animation_finished
	anim_sprite.play("idle")
	
func reset_tween() -> void:
	if tween: # If a tween exists already, kill it and make a new one.
		tween.kill()
	tween = create_tween()
