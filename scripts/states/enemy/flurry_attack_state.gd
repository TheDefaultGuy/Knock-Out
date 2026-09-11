@icon("res://assets/icons/MaterialSymbolsDeliveryTruckSpeedRounded.svg")
@tool
## A state in which the enemy will perform an intro animation and then a series of repeated moves,
## Similar to Piston Hondo's "Hondo Rush", Mr Sandman's "Dreamland Express", and Super Macho Man's Clotheslines.
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name FlurryAttacks extends EnemyState


#region Exported Variables

## How the delay between each attack is handled.
@export_category("⚙️ Attack Settings")

## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export var number_of_repetitions : int = 3
## Whether to skip the intro animation or not. Use it for when you ONLY want the repeated attacks.
@export var skip_intro : bool = false
## A Small delay before performing the attacks. Mainly as a small buffer to make sure to animations get cut off.
@export var start_delay : float = 0.2

var target_state : State

var attack_count : int = 0


#endregion

#region The Ready, Enter and Exit functions
func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required = false
	nested_state_machine = preload("uid://bg1hc7fvrio3n")
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	
func _enter_tree() -> void:
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	
## Overrides te state change condition so that this state can function properly.
func _validate_property(property: Dictionary) -> void: 
	attack_timer_required = false
	update_shown_exported_variables(property)
	

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	
	current_animation_state_machine = animation_tree[str("parameters/",nested_machine_name,"/playback")]
	
	if skip_intro == true:
		animation_tree.set(str("parameters/",nested_machine_name,"/conditions/skip_intro"), true)
	else:
		animation_tree.set(str("parameters/",nested_machine_name,"/conditions/skip_intro"), false)
		

	get_parent().interrupted_state = primary_target_state
	
	animation_tree.animation_finished.connect(increase_count)
	
	
	toggle_important_state_signal_connections()
	
	match skip_intro: # Resets the attack count when re-entering this state
		true:
			attack_count = 1 
		false:
			attack_count = 0
			
	await get_tree().create_timer(start_delay).timeout
	anim_state_machine.travel(nested_machine_name)

func exit() -> void:
	animation_tree.animation_finished.disconnect(increase_count)
	toggle_important_state_signal_connections()
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self or get_parent().current_state is EnemySpectating:
		animation_tree.set(str("parameters/",nested_machine_name,"/conditions/ko"), Global.player_node.isKnockdown)
		check_state_completion()
#endregion

## Increases the attack count variable by 1 every time an animation is played in this state.
func increase_count(_animation) -> void:
	attack_count += 1
	if attack_count == number_of_repetitions:
		current_animation_state_machine.travel("End")
		
