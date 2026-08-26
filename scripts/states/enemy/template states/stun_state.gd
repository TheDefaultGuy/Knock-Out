@icon("res://assets/icons/EmojioneMonotoneDizzy.svg")
## This is the state in which the enemy is stunned and can't fight back.
## It is a required state for all enemies.
class_name StunState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

## How long stun lasts for in seconds.
@export_range(0.5, 3.0, 0.25, "suffix:s") var stun_duration : float = 2.0 

func enter(): # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/stunned", true)
	animation_tree.set("parameters/conditions/spectating", false)
	animation_tree.set("parameters/conditions/recovered", false)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	await get_tree().create_timer(stun_duration).timeout
	animation_tree.set("parameters/conditions/recovered", true)
	transition_to_previous_state()
	

func exit():
	animation_tree.set("parameters/conditions/stunned", false)
	animation_tree.set("parameters/conditions/recovered", true)
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)

func _process(_delta: float) -> void:
	pass
	
