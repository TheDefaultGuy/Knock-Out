@icon("res://assets/icons/BoxiconsShieldHalf.svg")

class_name DefenseComponent extends Node

## This component is in charge of setting the status of defense of the [Player] / [Enemy].
##
## It is a required component for the [Fighter] class, which includes the [Player] and all [Enemy] boxers.
## It interacts with the opposing Fighter's [AttackingComponent], as it gets called by it.
## It mainly checks if an attack lands given the fighter's blocking, dodging, state, etc...


## Signal emitted when the [Player] successully performs a parry.
signal player_parried_signal

## Signal emitted when a dodge was performed. Used by the [Player].
signal succesful_dodge 

## Signal emitted when the [Enemy] was hit during the stunned window. Used to transition into [StunState].
signal stunned_signal

## Signal emitted whenthe [Fighter] has registered a hit.
signal hit_registered_signal

const IMPACT_EFFECT = preload("uid://mbb7yyvjhw12")
const PARRY_EFFECT = preload("uid://c2vbdtoq1noj0")

#region Exported Variables
@export_group("Defense Variables")

## Which position the [Fighter] is currently in and is used for determining dodges.
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
## Used only by the [Player], as enemies can't get hurt if they block.
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

#region Stored Variables
## Stores the hit animation. It can change depending on the state.
var current_hit_animation : String = "hit"

## Stores the block animation. It can change depending on the state.
var current_block_animation : String = "block"


## The position where effects will spawn.
var effect_position = [-10.0, -54.0]

## Array that stores both [member lower_damage_multiplier] and [member upper_damage_multiplier] variables for cleaner code.
var multiplier_array : Array[float] = [lower_damage_multiplier, upper_damage_multiplier, upper_damage_multiplier]

## Array that stores both [member lower_blocking_status] and [member upper_blocking_status] variables for cleaner code.
var blocking_array : Array[bool] = [lower_blocking_status, upper_blocking_status]

## Array that stores both [member lower_star_window] and [member upper_star_window] variables for cleaner code.
var star_window_array : Array[bool] = [lower_star_window, upper_star_window]


@onready var health_component: HealthComponent = %HealthComponent
@onready var animation_component: AnimationComponent = %AnimationComponent

@onready var animation_tree: AnimationTree = %AnimationTree
#endregion

#func _init() -> void:
	#self.process_priority = -2

func _ready() -> void:
	if owner is Enemy: # Enemies can't get hurt when they block.
		blocking_damage_multiplier = 0

## Sets the defense variables array so that it's easier to check and for cleaner code.
func set_defense_variables_arrays() -> void:
	multiplier_array = [lower_damage_multiplier, upper_damage_multiplier, upper_damage_multiplier]
	blocking_array = [lower_blocking_status, upper_blocking_status]
	star_window_array = [lower_star_window, upper_star_window]

## This is the main function used to check if a hit is succesful or not and is called by the opposing fighter's [AttackingComponent].
## 
## [br][param punch_height] is which height region the punch covers.
## [br][param damage_amount] is the base damage the punch will deal.
## [br][param punch_range] is what dodge positions (X axis) the attack covers; this is used for real hit ditection.
## [br][param punch_direction] is which direction the punch is coming from from the player's perspective; this is mainly used for selecting animations.
func check_defense(punch_height : int, punch_range : int, damage_amount : float, punch_direction : int) -> bool: 
	
	set_defense_variables_arrays() # Sets the defense variables arrays for easier checking
	
	# First, it checks for invulnerabilities and dodges.
	if is_invulnerable(punch_height) or is_punch_dodged(punch_range) == true: # If the player is invulnerable or is not in the area the punch covers, it missed.
		if owner is Player: # Sends a signal that the player successfully dodged so that they can leave the Tired State.
			succesful_dodge.emit()
		#FightManager.missed_attack_signal.emit()
		return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.
		
	else:
		match punch_height:
			Global.height.BOTH: # Checks to see if it's an attack that covers both heights.
				
				# If HealthComponent calculates the health and it returns as <= 0, then that means they're knocked down.
				if health_component.handle_damage_and_knockdown(damage_amount, 1.0, punch_height, punch_direction) == false:
					animation_component.set_animation_blend(current_hit_animation, Vector2i(punch_direction, punch_height))
					animation_component.play_animation(current_hit_animation)
					
				return true
				
			_: 
				return await check_blocking_status(blocking_array[punch_height], damage_amount, punch_height, punch_direction, punch_range)
				

## Function that checks the blocking status of the [Fighter] and whether or not the incoming attack would land.
func check_blocking_status(blocking_status : bool, damage_amount : float, punch_height : int, punch_direction : int, punch_range : int) -> bool:
	match blocking_status:
		
		# Checks to see if the fighter is currently vulnerable in the given region.
		# true = blocking and NOT vulnerable
		# false = not blocking and IS vulnerable
		false: # NOT blocking
			return choose_hit_region(punch_height, damage_amount, punch_direction)
			
		true: # IS blocking
			
			 # Only applies to the player.
			handle_player_blocking_and_parry(damage_amount, punch_height, punch_direction, punch_range)
				
			# Sets the blend of the block animation.
			animation_component.set_animation_blend(current_block_animation, Vector2i(punch_direction, punch_height))
			
			# Plays the corresponding block animation if it wasn't enough damage for a knockdown.
			animation_component.play_animation(current_block_animation)
			print("Blocked")
			
			# This is done so that state change functions dont try and check for idle or something and checks on the actual block animation
			await animation_tree.animation_started 
			
			FightManager.successful_block_signal.emit()
			return false # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.

	return false  # Returns that the hit was NOT successful. Mainly as an answer to the attacking component.

#region Helper/short functions

## Function that deals with the logic around blocks and parries for the [Player].
## For the [Player], it checks if the block was during the parry window by checking the [member parry_timer].
func handle_player_blocking_and_parry(damage_amount : float, punch_height : int, punch_direction : int, punch_range : int)-> void:
	if owner is not Player : # Don't run this function if you're not the player.
		return
		
	# Basically, if you're blocking, but the punch isn't straight ahead, you still get hit.
	if dodge_position == Global.range.NEUTRAL:
		if punch_range != Global.range.NEUTRAL:
			return choose_hit_region(punch_height, damage_amount, punch_direction)
	
	# If the parry timer hasn't reached 0, then it's considered a successful parry.
	if owner.input_component.parry_timer.time_left > 0.0 :
		
		# Emits the signal to playe the parry sound effect.
		FightManager.play_sfx_signal.emit("parry")
		
		player_parried_signal.emit()
		
		# Sets the block animation as the fast block.
		current_block_animation = "fast_block"
		play_parry_effect(punch_height)
		
	else: # If the block wasn't during the parry window, the use the regular block animation.
		current_block_animation = "block"
		
	FightManager.lower_stamina() # Lowers the player stamina after a block.


## Chooses which region the attack landed and does calls all of the pertinent functions.
func choose_hit_region(punch_height : int, damage_amount : float, punch_direction : int) -> bool:
	
	hit_registered_signal.emit() # Emits that a hit has been registered.
	print("HIT REGISTERED")
	
	if owner is Enemy:
		
		check_for_star_and_stun(punch_height) # Checks the star punch and stun windows
		
		play_impact_effect(punch_height)
		
		# If the damage passes a certain amount, then play the final hit animation instead.
		if damage_amount > 15.0 :
			
			current_hit_animation = "final_hit"
			
			# Punches dealing more than 15.0 are considered star punches for sake of simplicity.
			owner.hit_by_star_punch_signal.emit() 
	
	if health_component.handle_damage_and_knockdown(damage_amount, multiplier_array[punch_height], punch_height, punch_direction) == true:
		return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.
	
	# Sets the blend of the current hit animation based on the punch height and the direction.
	animation_component.set_animation_blend(current_hit_animation, Vector2i(punch_direction, punch_height))
	
	# Actually starts the hit animation.
	animation_component.play_animation(current_hit_animation)
	
	return true # Returns that the hit WAS successful. Mainly as an answer to the attacking component.

## Checks to see if the attack can be rewarded a star and if the [Enemy] enters [StunState]. 
##
## Then, it checks to see if the attack landed during a stun window.
## Returns true if stunned, and false if not
func check_for_star_and_stun(punch_height : int) -> bool: 
	if owner is Enemy : # Checks to see if the parent that is getting hit is the enemy and not the player.
		
		# Checks to see if the star window of that region is true or false.
		if star_window_array[punch_height] == true :
			FightManager.award_star()
		
		if stun_window == true : # If the player attacked at a time where the enemy can be stunned, move to the stunned state.
			stunned_signal.emit()
			current_hit_animation = "stun_hit" if stun_window == true else "hit"
		return stun_window
		
	return false
	
## Helper function that makes the vulnurability checking simpler.
func is_invulnerable(punch_height: int) -> bool:
	match punch_height:
		Global.height.HIGH:
			return upper_invulnerability
			
		Global.height.LOW:
			return lower_invulnerability
			
		Global.height.BOTH:
			return lower_invulnerability and upper_invulnerability
			
		_: 
			return false

## Helper function that makes the dodge checking simpler.
func is_punch_dodged(punch_range: int) -> bool:
	# Checks if the punch is down the middle and if the defender is not in the middle or neutral dodge position.
	var dodged_neutral = (punch_range == Global.range.NEUTRAL and dodge_position != Global.range.NEUTRAL)
	var dodged_right = (punch_range <= Global.range.NEUTRAL and dodge_position >= Global.range.RIGHT)
	var dodged_left = (punch_range >= Global.range.NEUTRAL and dodge_position <= Global.range.LEFT)

	# Returns true if any of them are true.
	return dodged_neutral or dodged_right or dodged_left


## Resets [member current_hit_animation] and [member current_block_animation] as well as the [member current_anim_state_machine] back to the default ones.
func reset_current_animations() -> void:
	current_hit_animation = "hit"
	current_block_animation = "block"

#endregion

func play_impact_effect(punch_height) -> void:
	var impact_effect = IMPACT_EFFECT.instantiate()
	impact_effect.position.y = effect_position[punch_height]
	owner.add_child(impact_effect)
	
func play_parry_effect(punch_height) -> void:
	var parry_effect = PARRY_EFFECT.instantiate()
	parry_effect.position.y = effect_position[punch_height]
	owner.add_child(parry_effect)
