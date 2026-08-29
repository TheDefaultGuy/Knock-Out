@icon("res://assets/icons/IntroLoop.svg")
@tool
## This is a template state used by enemy boxers.
##
## In this state, the enemy will first perform an intro animation,
## and then loop another animation or a series of animations over and over until either they or the player are knocked down.
## This should be used to recreate attacks like Bald Bull's Bull Rush, where the enemy won't stop until somebody is knocked down.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name IntroLoopState extends State

@onready var anim_state_machine = animation_tree.get("parameters/playback")


#region Exported Variables
@export_category("🎬 Animations & Moveset")
## The intro animation that will play in this state.
@export var state_machine_animation : String = "intro_loop_attack"

## How the delay between each attack is handled.
@export_category("⏱ Attack Delays")
## A Multipurpose timer that can be used by various states.
@export var general_timer : Timer
## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_wait_time : float = 3.0
## The maximum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_wait_time : float = 8.0

@export_category("⇄ State Changing Conditions")
## The state the enemy will transition to after the conditions are met.
@export var target_state : State
#endregion

#region The Ready, Enter and Exit functions
func _ready() -> void:
	if general_timer == null:
		printerr(self.name, " : General Timer not set.")
	general_timer.timeout.connect(perform_action)
	
	
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/", false)
	animation_tree.set("parameters/conditions/spectating", false)
	animation_tree.set("parameters/conditions/ready_to_loop", false)
	
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	FightManager.no_stamina_signal.connect(transition_to_previous_state)
	defense_component.stunned_signal.connect(transition_to_stunned)

	if target_state == null:
		printerr(self.name, " : Target State not set.")
		return
	if animation_tree == null:
		printerr(self.name, " : Animation tree not set.")
		return
	anim_state_machine.travel(state_machine_animation)
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = target_state 


func exit() -> void:
	anim_state_machine.travel(state_machine_animation)
	general_timer.stop()
	general_timer.timeout.disconnect(perform_action)
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	FightManager.no_stamina_signal.disconnect(transition_to_previous_state)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
#endregion

## Does the weight calculation and chooses a random move
func get_weighted_choice(weight_dict: Dictionary):
	# Calculate the total sum of all weights
	var total_weight: float = 0.0
	for weight in weight_dict.values():
		total_weight += weight
	
	# Pick a random number between 0 and the total weight
	var rolled_value: float = randf_range(0.0, total_weight)
	
	# ate through the dictionary to find which bracket the roll falls into
	for key in weight_dict:
		var weight: float = weight_dict[key]
		if rolled_value < weight:
			return key # The chosen attack
			
		rolled_value -= weight # Shrink the remaining roll value
	
	return weight_dict.keys().back() # Fallback edge case

func perform_action() -> void:
	animation_tree.get(str("parameters/",state_machine_animation,"/playback")).travel("attack")

func change_state() -> void:
	get_parent().interrupted_state = target_state

## Function that is manually called by the "idle" animation of this state.
## It'll choose a random time between  the min and max values and once that time is up, it'll perform the next attack.
func start_loop_timer() -> void:
	general_timer.start(randf_range(min_wait_time, max_wait_time)) 
	
