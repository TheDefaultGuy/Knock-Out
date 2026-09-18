@icon("res://assets/icons/TablerEyeExclamation.svg")
@tool
class_name Reactionary extends EnemyState

## In this state, the enemy will react to the player's actions.
## 
## The enemy can dodge if the player throws a punch, throw a fake out punch and then punish if the player dodged.[br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

## The fakeout animation that will play in this state.
@export var fakeout_animation : String = "fakeout"

func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = true
	nested_state_machine = preload("uid://c1biuhgyv30i1")
	nested_machine_name = str(self.name).to_snake_case()
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.RESET_TIMER
	
	check_for_attack_and_append(fakeout_animation)

func enter() -> void: 
	
	super() # Runs the base EnemyState enter function and then runs everything below.
	
	FightManager.player_threw_punch_signal.connect(set_blends)
	FightManager.player_dodged_signal.connect(play_punish_animation)
	
	# Sets the block animation and state machine in the defense component as the block animation in the state machine.
	# This is because the defense component is the one responsible for playing the block animation
	defense_component.current_block_animation = "dodge"
	defense_component.current_anim_state_machine = current_animation_state_machine

func exit() -> void:
	
	super()  # Runs the base EnemyState exit function and then runs everything below.
	
	# Disconnecting signals
	FightManager.player_threw_punch_signal.disconnect(set_blends)
	FightManager.player_dodged_signal.disconnect(play_punish_animation)

## Sets the blends of the hit, and dodge animations depending on the punch thrown by the player.
func set_blends(height : int, direction : int) -> void:
	animation_tree.set(str("parameters/",str(nested_machine_name),"/dodge/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/stun_hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/final_hit/blend_position"), Vector2i(direction, height))
	
func play_punish_animation(dodge_direction : int) -> void:
	if current_animation_state_machine.get_current_node() == str(fakeout_animation) :
		animation_tree.set(str("parameters/",str(nested_machine_name),"/punish/blend_position"), dodge_direction)
		current_animation_state_machine.travel("punish")
