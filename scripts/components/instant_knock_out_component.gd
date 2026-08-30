@icon("res://assets/icons/MdiAlarmBell.svg")
@tool
## This is the component in charge of storing and checking the conditions for instant Knock-Out tricks for enemy fighters.
##
## The main function is the check_for_instant_ko() function. It's called by the Defense Component if the enemy has the instant_ko_window variable set to true.
## To properly set up an instant KO condition, you need to choose which states
class_name InstantKOComponent extends Node


#region Exported Variables and function that handles which variables to show
## Sets the condition for the player to get an instant KO.
enum KO_CONDITION_TYPE{
	## Will grant a KO if the player lands a  punch that is at least worth the given star amount.
	STARS_USED,
	## Will grant a KO if the player lands another star punch after the enemy has already received the given star punch amount.
	STAR_PUNCHES_RECEIVED,
	## Will grant a KO if the player has already knocked down the enemy a given number of times before the given round time.
	KNOCK_DOWNS_BEFORE_ROUND_TIME,
	## Will grant a KO if the player hasn't been hit before in the round.
	NEVER_BEEN_HIT
}

@export var state_machine : StateMachine

@export_category("Instant KO Conditions")
## What condition type to use for granting an instant KO.
@export var condition := KO_CONDITION_TYPE.STARS_USED:
	set(value):
		condition = value
		notify_property_list_changed()

## The first checked state in which the instant KO will occur.
@export var expected_state_A : State
## The state in which the instant KO will occur.
@export var expected_state_B : State
#@export var conditional_animation : String = "jab"


## The number of stars required for the star punch to grant an instant KO.
@export_range (1, 3) var number_of_stars : int = 3

## The number of star punches landed required to grant an instant KO.
@export_range (1, 12) var star_punches_received : int = 6


## The number of star punches landed required to grant an instant KO.
@export_range (1, 6) var knock_downs_required : int = 1

## The round time required to grant an instant KO.
@export_range(10.0, 180.0, 1.0, "suffix:s") var ko_round_time : float

## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "number_of_stars" and condition != KO_CONDITION_TYPE.STARS_USED:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "ko_round_time" and condition != KO_CONDITION_TYPE.KNOCK_DOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "knock_downs_required" and condition != KO_CONDITION_TYPE.KNOCK_DOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "star_punches_received" and condition != KO_CONDITION_TYPE.STAR_PUNCHES_RECEIVED:
		property.usage = PROPERTY_USAGE_NONE
#endregion

func _ready() -> void:
	if expected_state_A == null:
		printerr(get_parent().name, " Instant KO Component: Expected State A not set.")
	if expected_state_B == null :
		push_warning(get_parent().name, " Instant KO Component: Expected State B not set.")
		
## Checks if the conditions for an instant Knock-Out have been met.
## Returns true if the conditions HAVE been met and thus awards an instant KO.
func check_for_instant_knock_out() -> bool:
	match condition:
		KO_CONDITION_TYPE.STARS_USED:
			if FightManager.stars_used >= number_of_stars:
				if state_machine.current_state == expected_state_A or state_machine.current_state == expected_state_B:
					print_rich("[color=cyan]Instant KO component:[/color] KO condition met: Number of stars.")
					return true
				
		KO_CONDITION_TYPE.STAR_PUNCHES_RECEIVED:
			if FightManager.star_punches_landed >= star_punches_received:
				if state_machine.current_state == expected_state_A or state_machine.current_state == expected_state_B:
					print_rich("[color=cyan]Instant KO component:[/color] KO condition met: Star Punches Received ")
					return true
				
		KO_CONDITION_TYPE.KNOCK_DOWNS_BEFORE_ROUND_TIME:
			if FightManager.enemy_ko_count >= knock_downs_required and FightManager.round_time <= ko_round_time:
				if state_machine.current_state == expected_state_A or state_machine.current_state == expected_state_B:
					print_rich("[color=cyan]Instant KO component:[/color] KO condition met: Knockdowns before round time")
					return true
				
		KO_CONDITION_TYPE.NEVER_BEEN_HIT:
			if Global.player_node.health_component.hp == Global.player_node.health_component.initial_hp:
				if state_machine.current_state == expected_state_A or state_machine.current_state == expected_state_B:
					print_rich("[color=cyan]Instant KO component:[/color] KO condition met: Never Hit", condition)
					return true
	return false
