@icon("res://assets/icons/BoxiconsShieldHalf.svg")
## This component is in charge of setting the status of defense of the player / enemy.
##
## It is a required component for the [annotation Fighter] class, which includes the Player and all enemy boxers.
## It interacts with the opposing Fighter's [annotation Attack Component], as it gets called by it.
## It mainly checks if an attack lands given the fighter's blocking, dodging, state, etc...
class_name DefenseComponent extends Node

#region Exported Variables
@export_group("Defense Variables")

## Which position the fighter is currently in and is used for determining dodges.
##
## 0 = Neutral; no dodge
##-1 = Dodging Left
## 1 = Dodging Right
@export var dodge_position : int = Global.range.NEUTRAL

## Used to multiply damage at specific moments as a way to make weakspots or counter attack options.
##
## Used by enemies so that the player can be rewarded with well timed counter punches or exploiting weakspots.
## This and all "Defense Variables" should only be accessed and manipulated by animations within the move set animation
@export var upper_damage_multiplier : float = 1.0 

## Used to multiply damage at specific moments as a way to make weakspots or counter attack options.
##
## Used by enemies so that the player can be rewarded with well timed counter punches or exploiting weakspots.
## This and all "Defense Variables" should only be accessed and manipulated by animations within the move set animation
@export var lower_damage_multiplier : float = 1.0

## Used to divide damage done by attacks when blocked.
## Used only by the player, as enemies can't get hurt if they block.
@export var blocking_damage_multiplier : float = 0.1 

## Whether the upper part of the fighter is blocked.
## High attacks will be considered as if they landed, by the attacker, but blocked by the defender.
@export var upper_blocking_status : bool = false

## Whether the lower part of the fighter is blocked. 
## Low attacks will be considered as if they landed, by the attacker, but blocked by the defender.
@export var lower_blocking_status : bool = false

## Whether the fighter is invulnerable or not in the upper section.
## Used for if they're ducking, dodging with their head, moved away, etc...
@export var upper_invulnerability : bool = false 

## Whether the fighter is invulnerable or not in the lower section.
## Used for if they're ducking, dodging with their head, moved away, etc...
@export var lower_invulnerability : bool = false

## The window of time in which attacking stuns the enemy. Never used by the player.
@export var stun_window : bool = false 

## The window of time in which attacking grants a star for star punches.
## It's split into 2 variables corresponding to the 2 different heights. That way, you have the option of awarding a star by hitting the face but not the body or vice versa.
@export var upper_star_window : bool = false 

## The window of time in which attacking grants a star for star punches.
## It's split into 2 variables corresponding to the 2 different heights. That way, you have the option of awarding a star by hitting the face but not the body or vice versa.
@export var lower_star_window : bool = false

## The window of time in which being hit will trigger an instant KO check.
@export var instant_ko_window: bool = false 
#endregion

## Signal emitted when a dodge was performed. Used by the player.
signal succesful_dodge 
## Signal emitted when the enemy was hit during the stunned. Used to transition into stunned state.
signal stunned_signal

## Stores the hit animation. It can change depending on the state.
var current_hit_animation : String = "hit"

var current_anim_state_machine : AnimationNodeStateMachinePlayback = null

func _ready() -> void:
	current_anim_state_machine = get_parent().animation_tree["parameters/playback"]
	if get_parent().isPlayer == false: # Enemies can't get hurt when they block.
		blocking_damage_multiplier = 0

## This is the main function used to check if a hit is succesful or not and is called by the opposing fighter's [annotation Attack Component].
## 
## Punch height and damage amount is self-explanatory.
## Punch_range is what dodge positions (X axis) the attack covers; this is used for real hit ditection.
## Punch direction is which direction the punch is coming from from the player's perspective; this is only used for selecting animations.
func check_defense(punch_height : int, punch_range : int, damage_amount : float, punch_direction : int) -> bool: 
	# First, it checks for invulnerabilities and dodges.
	if is_invulnerable(punch_height) or is_punch_dodged(punch_range):
		if get_parent().isPlayer == true:
			succesful_dodge.emit()
			FightManager.missed_attack_signal.emit()
		return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.
		
	else:
		
		match punch_height:
			Global.height.LOW: # Checks to see if the attack thrown is a lower attack.
				return check_blocking_status(lower_blocking_status, damage_amount, Global.height.LOW, punch_direction)
				
			Global.height.HIGH: # Checks to see if the attack thrown is a high attack.
				return check_blocking_status(upper_blocking_status, damage_amount, Global.height.HIGH, punch_direction)
					
			Global.height.BOTH: # Checks to see if it's an attack that covers both heights.
				
				# If Health Component calculates the health and it returns as <= 0, then that means they're knocked down.
				if handle_damage_and_knockdown(damage_amount, 1.0, punch_height, punch_direction) == true:
					return true
				else:
					get_parent().animation_tree.set("parameters/hit/blend_position", Vector2i(punch_direction, punch_height))
					play_animation(str(current_hit_animation))
					return true
				
			_: # Fall back for Unaccounted 4th height value.
				printerr(get_parent().name, " Defense Component: Unaccounted 4th height value.")
				return false 
				

## Function that checks the blocking status of the fighter and whether or not the incoming attack would land.
func check_blocking_status(blocking_status : bool, damage_amount : float, punch_height : int, punch_direction : int) -> bool:
	match blocking_status:
		
		# Checks to see if the fighter is currently vulnerable in the given region. true = blocking and NOT vulnerable, false = not blocking and IS vulnerable	
		false: # Not blocking
			if punch_height == Global.height.LOW:
				if handle_damage_and_knockdown(damage_amount, lower_damage_multiplier, punch_height, punch_direction) == true:
					return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.
					
			else: # if the punch height was LOW or BOTH
				if handle_damage_and_knockdown(damage_amount, upper_damage_multiplier, punch_height, punch_direction) == true:
					return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.
			
			check_for_star_and_stun(punch_height)
			get_parent().animation_tree.set("parameters/hit/blend_position", Vector2i(punch_direction, punch_height))
			play_animation(str(current_hit_animation))
			return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.
				
		true: # IS blocking
			if handle_damage_and_knockdown(damage_amount, blocking_damage_multiplier, punch_height, punch_direction) == true:
				return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.
			
			# Plays the corresponding block animation if it wasn't enough damage for a knockdown.
			get_parent().animation_tree.set("parameters/block/blend_position",  punch_height)
			play_animation("block")

			FightManager.succesful_block_signal.emit()
			return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.

	return false  # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.
			
#region Helper/short functions
## Helper function. Deals damage and returns whether or not the attack resulted in a knock down.
## Also emits the the signal that the hit was successful.
func handle_damage_and_knockdown(damage_amount : float, multiplier : float, punch_height : int, punch_direction : int) -> bool:
	if get_parent().isPlayer == true: # checks to see if the defender is the player. If the player got hit, lower their stamina.
		FightManager.lower_stamina()
	else:
		if check_instant_ko() == true:
			damage_amount = damage_amount * 300.0
	if get_parent().health_component.deal_damage_and_check_for_knockdown(damage_amount, multiplier) == true:
		get_parent().animation_tree.set("parameters/knock_down/blend_position", Vector2i(punch_direction, punch_height))
		play_animation("knock_down")
		return true
	else:
		return false

				
## Checks to see if the attack can be rewarded a star. 
## Then, it checks to see if the attack landed during a stun window.
## Returns true if stunned, and false if not
func check_for_star_and_stun(punch_height : int) -> bool: 
	if get_parent().isPlayer == false: # Checks to see if the parent that is getting hit is the enemy and not the player.
		match punch_height: # If the player attacked at a time where a star can be awarded, run the award star function.
			Global.height.LOW:
				if lower_star_window == true:
					FightManager.award_star()
			Global.height.HIGH:
				if upper_star_window == true:
					FightManager.award_star()
			
		if stun_window == true: # If the player attacked at a time where the enemy can be stunned, move to the stunned state.
			stunned_signal.emit()
			return true
	return false
	
## A shorthand way to call the travel function.
func play_animation(animation_name : String): 
	current_anim_state_machine.travel(animation_name)
	
## Helper function that makes the vulnurability checking simpler.
func is_invulnerable(punch_height: int) -> bool:
	var high_invul = (punch_height == Global.height.HIGH and upper_invulnerability)
	var low_invul = (punch_height == Global.height.LOW and lower_invulnerability)
	
	# Returns true if any of them are true.
	return high_invul or low_invul

## Helper function that makes the dodge checking simpler.
func is_punch_dodged(punch_range: int) -> bool:
	# Checks if the punch is down the middle and if the defender is not in the middle or neutral dodge position.
	var dodged_neutral = (punch_range == Global.range.NEUTRAL and dodge_position != Global.range.NEUTRAL)
	var dodged_right = (punch_range <= Global.range.NEUTRAL and dodge_position >= Global.range.RIGHT)
	var dodged_left = (punch_range >= Global.range.NEUTRAL and dodge_position <= Global.range.LEFT)
	var ducked_neutral = (punch_range == Global.range.NEUTRAL and dodge_position == Global.range.NEUTRAL and upper_invulnerability)
	
	# Returns true if any of them are true.
	return dodged_neutral or dodged_right or dodged_left or ducked_neutral

## Checks the instant KO window and then calls the function in the instant KO component to check and return whether or not it's an instant KO.
func check_instant_ko() -> bool:
	if instant_ko_window == true:
		if get_parent().instant_ko_component != null:
			if get_parent().instant_ko_component.check_for_instant_knock_out() == true:
				return true
		else:
			push_error("Defense Component: ", get_parent().name, " doesn't have an Instant KO Component.")
	return false
#endregion

func reset_hit_animation():
	current_hit_animation = "hit"
	current_anim_state_machine = get_parent().animation_tree["parameters/playback"]
