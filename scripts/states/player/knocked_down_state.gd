@icon("res://assets/icons/StreamlineSleepSolid.svg")
class_name PlayerKnockedDown extends State

@onready var input_component: InputComponent = %InputComponent


## Value from 0.0 to 100.0 that determines how far the player is to recovering from a knockout and getting up.
@export var get_up_progress : float = 0.0
## How much does each button press increase the get up progress.
## How fast they get up.
@export var get_up_step_value : float = 10.0 
@export var get_up_decay_rate : float = 50.0

@export var get_up_threshold : float = 100.0

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/knockeddown", true)
	animation_tree.set("parameters/conditions/gotup", false)
	FightManager.player_ready_status = false
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	FightManager.fight_is_over_signal.connect(failed_to_get_up)
	self.owner.isKnockdown = true
	
func exit() -> void:
	get_up_progress = 0.0
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)
	FightManager.fight_is_over_signal.disconnect(failed_to_get_up)
	self.owner.isKnockdown = false
	
func _process(delta: float) -> void:
	if get_parent().current_state == self:
		get_up_progress = clampf(get_up_progress - get_up_decay_rate * delta, 0.0 , 110.0)
		animation_tree.set("parameters/get_up_blend/blend_position", get_up_progress)

		if get_up_progress >= get_up_threshold: # When the get up progress reaches 100, the player succesfully gets back up.
			 # plays the get up animation
			animation_tree.set("parameters/conditions/knockeddown", false)
			animation_tree.set("parameters/conditions/gotup", true)
			
			FightManager.fighter_got_up_signal.emit() # Emits the global signal
	return

func perform_defense(_move : int, _action_name : String):
	pass
		
## When an attack input is Given by the Input Component, increase the get up progress.
func perform_attack(_height : int, _direction : int, _action_name : String, _special : bool):
	get_up_progress += get_up_step_value
	
## Doesn't let the player be able to get up after they failed to get up before the 10 count.
func failed_to_get_up(): 
	get_up_step_value = 0.0
	get_up_decay_rate = 2.0 * get_up_decay_rate

func ready_to_fight():
	FightManager.player_ready_status = true
	FightManager.fighter_ready_signal.emit()
