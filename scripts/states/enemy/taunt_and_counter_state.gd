@icon("res://assets/icons/AtIconsComedyMask.svg")
@tool
class_name TauntAndCounter extends EnemyState

## This is a template state used by enemy boxers.
## In this state, the enemy will keep looping the same animation, but react to the player's attacks.
## This is used to recreate boxers like Don Flamenco, where they taunt and only attack when attacked at first.
## You can set conditions to transition to another state if desired.
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

@export var taunt_animation : String = "taunt"

func _init() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required = true
	
	moveset_type = MOVESET_TYPE_ENUM.PREDETERMINED_ORDER
	moveset_array = [taunt_animation]
	block_behavior = BLOCK_BEHAVIOR_ENUM.COUNTER_ATTACK
	
	# Given the nature of the state, it's REQUIRED to have the condition to change after player is tired.
	# This is to avoid the enemy doing nothing for the rest of the round after the player gets tired.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED
