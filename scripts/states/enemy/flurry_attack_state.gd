@icon("res://assets/icons/MaterialSymbolsDeliveryTruckSpeedRounded.svg")
## This is a template state used by enemy boxers.
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.
class_name FlurryAttackState extends State

@onready var anim_state_machine = animation_tree.get("parameters/playback")

#region Exported Variables
@export_category("🎬 Animations & Moveset")
## The state machine animation that will play in this state that holds all of the attacks.
@export var state_machine_animation : String = "intro"

## How the delay between each attack is handled.
@export_category("⏱ Attack Delays")

## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export var number_of_repetitions : int = 3


@export_category("⇄ State Changing Conditions")
## The state the enemy will transition to if the player got knocked out during this state.
@export var KO_state : State
## The state the enemy will transition to if the player survived this state.
@export var survived_state : State

var attack_count : int = -1
#endregion

#region The Enter and Exit functions
func enter():
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/", false)
	animation_tree.set("parameters/conditions/spectating", false)
	animation_tree.set("parameters/conditions/ready_to_loop", false)
	#animation_tree.set(str("parameters/",state_machine_animation,"/conditions/attacking"), true)
	animation_tree.animation_finished.connect(increase_count.unbind(1))
	anim_state_machine.travel(state_machine_animation)
	
	if KO_state == null:
		printerr(self.name, " : Target State not set.")
	if survived_state == null:
		survived_state = get_parent().interrupted_state
		
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	
	FightManager.player_knocked_down_signal.connect(change_state)
	#animation_tree.get(str("parameters/",state_machine_animation,"/playback")).animtion

	defense_component.stunned_signal.connect(transition_to_stunned)
	attack_count = -1
	
	

func exit():
	anim_state_machine.travel(state_machine_animation)

	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
	FightManager.player_knocked_down_signal.disconnect(change_state)

	animation_tree.animation_finished.disconnect(increase_count)
	
func _process(_delta: float) -> void:
	pass
#endregion

func increase_count():
	attack_count += 1
	if attack_count >= number_of_repetitions:
		get_parent().interrupted_state = survived_state
		#animation_tree.set(str("parameters/",state_machine_animation,"/conditions/attacking"), false)
		#animation_tree.get(str("parameters/",state_machine_animation,"/playback")).travel("end")
		transition_to_previous_state()
		


func change_state():
	get_parent().interrupted_state = KO_state
	#animation_tree.get(str("parameters/",state_machine_animation,"/playback")).travel("end")
	#transition_to_previous_state()
	
