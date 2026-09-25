@icon("res://assets/icons/MdiAlarmBell.svg")
@tool
class_name InstantKDComponent extends Node

## This is the component in charge of storing and checking the conditions for instant knockdown tricks for [Enemy] fighters.
##
## The main function is the [method check_for_instant_knockdown] function. It's called by the [HealthComponent] every time a successful hit has been registered.
## To properly set up an 


#region Enumerations
## Sets the condition for the [Player] to get an instant knockdown.
enum KDConditionTypeEnum{
	
	## Will grant a KD if the [Player] lands a punch that is at least worth the given [member number_of_stars].
	STARS_USED,
	
	## Will grant a KD if the [Player] lands another star punch after the [Enemy] has already received the given [member star_punches_received] amount.
	STAR_PUNCHES_RECEIVED,
	
	## Will grant a KD if the [Player] has already knocked down the [Enemy] a given number of [member knockdowns_required] before the given [member expected_round_time].
	KNOCKDOWNS_BEFORE_ROUND_TIME,
	
	## Will grant a KD if the [Player] hasn't been hit before in the round.
	NEVER_BEEN_HIT,
}

## The type of punch the [Player] has to land to achieve and instant KD.
## Used by [member punch_type_flags].
enum PunchTypeEnum {
	
	## The [Player] has to land a star punch; it can be in any [enum Global.HeightEnum] region
	STAR_PUNCH = 1,
	
	## The [Player] can land any punch, including star punches, as long as it's in the LOWER [enum Global.HeightEnum] region
	LOW_PUNCH = 2,
	
	## The [Player] can land any punch, including star punches, as long as it's in the UPPER [enum Global.HeightEnum] region
	HIGH_PUNCH = 4,
}

## The type of punch the [Player] has to land to achieve and instant KD.
enum OutcomeEnum {
	
	## The [Enemy] will only be knocked down, meaning they'll get back up.
	KNOCKDOWN,
	
	## The [Enemy] will be knocked down and won't get back up.
	FULL_KNOCKOUT,
}
#endregion

#region Exported Variables

@export_category("Instant Knockdown Conditions")

## The state the [Enemy] must be in their [StateMachine] for the instant Knockdown can occur.
@export var expected_state : State

## What condition type to use for granting an instant Knockdown.
@export var knockdown_condition := KDConditionTypeEnum.STARS_USED:
	set(value):
		if knockdown_condition != value :
			knockdown_condition = value
			
			# Makes sure the punch type required is a Star punch if the condition is Stars used
			if knockdown_condition == KDConditionTypeEnum.STARS_USED :
				punch_type_flags |= PunchTypeEnum.STAR_PUNCH
			notify_property_list_changed()

## Sets the property of the punch that the player needs to land for instant knockdown.
## [br]If [param Star Punch] is on/true, then the player needs to land a star punch.
## [br]If [param Low Punch] is on/true, then the player needs to land a punch in the lower region.
## [br]If [param High Punch] is on/true, then the player needs to land a punch in the upper region.
## [br]For example:
## [br]If [param Star Punch] is [code]true[/code],
## [br]and [param High Punch] is [code]true[/code],
## [br]and [param Low Punch] is [code]false[/code], then the player has to land a High Star Punch.
@export_flags("Star Punch", "Low Punch", "High Punch") var punch_type_flags : int = 0 :
	set(value):
			punch_type_flags = value
			
			# Makes sure the punch type required is a Star punch if the condition is Stars used
			if knockdown_condition == KDConditionTypeEnum.STARS_USED :
				punch_type_flags |= PunchTypeEnum.STAR_PUNCH
			notify_property_list_changed()


## The animation that has to be playing for the instant KD will occur.
## If the string is left empty, then it'll skip checking for the animation,
## meaning that the instant knockdown can happen during anny animation.
@export var expected_animation : String = ""

## The number of stars required for the star punch to grant an instant KD.
@export_range (1, 3) var number_of_stars : int = 3

## The number of star punches landed required to grant an instant KD.
@export_range (1, 12) var star_punches_received : int = 6

## The number of star punches landed required to grant an instant KD.
@export_range (1, 6) var knockdowns_required : int = 1

## The round time required to grant an instant KD.
@export_range(10.0, 180.0, 1.0, "suffix:s") var expected_round_time : float

## The outcome/what the [Enemy] will do if all of the conditions are met and the instant knockdown is awarded.
@export var resulting_outcome := OutcomeEnum.KNOCKDOWN

## Button that automatically adds the conditions and variables set above it to the [member active_conditions_dictionary]
@export_tool_button("Add Condition to List", "Add") var add_cond = add_condition_to_dictionary

@export_category("List of Active Conditions")

## The dictionary containing all of the conditions that will be actively checked during the fight.
## Conditions are stores as [InstantKDComponent.KDConditions] Resources.
@export var active_conditions_dictionary : Dictionary[State, KDConditions]

#endregion

## Variable that stores if the punch received was a star punch or not
var is_star_punch : bool = false

## Stores if the [Fighter] is fully knocked out after the instant knockdown.
## It's set here but checked by [EnemyKnockedDown]
var is_fully_knocked_out : bool = false

func _ready() -> void:
	if active_conditions_dictionary == null or active_conditions_dictionary == { }:
		push_warning(get_parent().name, " Instant KD Component: No conditions Stored; enemy will not have any instant knockdown conditions.")

## Grabs the currently set variables and conditions and stores them as a [InstantKDComponent.KDConditions] Resource inside of the [member active_conditions_dictionary]
## Function is called via a button in the inspector.
func add_condition_to_dictionary() -> void:
	
	# Creates a new KDConditions resource to store the values currently set.
	var new_resource : KDConditions = KDConditions.new()
	
	# Only sets the variables that are actually used.
	match knockdown_condition : 
		KDConditionTypeEnum.STARS_USED:
			new_resource.number_of_stars = number_of_stars
			
		KDConditionTypeEnum.STAR_PUNCHES_RECEIVED:
			new_resource.star_punches_received = star_punches_received
				
		KDConditionTypeEnum.KNOCKDOWNS_BEFORE_ROUND_TIME:
			new_resource.knockdowns_required = knockdowns_required
			new_resource.expected_round_time = expected_round_time
	
	# Sets all of the variables of the resource to the ones currently selected in the inspector.
	new_resource.knockdown_condition = knockdown_condition
	new_resource.punch_type_flags = punch_type_flags
	new_resource.expected_animation = expected_animation
	new_resource.resulting_outcome = resulting_outcome
	
	# Adds the resource to the active_conditions_dictionary.
	active_conditions_dictionary[expected_state] = new_resource as KDConditions
	
	# Updates the exported variables in the inspector tab
	notify_property_list_changed()
	return

## Checks if the [member knockdown_condition] has been met.
## Returns true if the [member knockdown_condition] HAVE been met and thus awards an instant KD.
func check_for_instant_knockdown(damage_amount : float, punch_height : int) -> bool:
	
	# Resets the variables back to default before running any checks.
	is_star_punch = false
	is_fully_knocked_out = false
	
	# Checks if the current state the enemy is currently in is one of the states in the active_conditions_dictionary.
	if owner.state_machine.current_state not in active_conditions_dictionary.keys() :
		return false # Returns false if it's NOT one of the states.

	# If the punch received did more than 15.0 hp worth of damage,
	# Then consider it a star punch.
	if damage_amount >= 15.0 : 
		is_star_punch = true
	
	# Grabs the stored condition resource of the current state.
	var stored_conditions : KDConditions = active_conditions_dictionary[owner.state_machine.current_state] 
	
	match stored_conditions.knockdown_condition:
		KDConditionTypeEnum.STARS_USED:
			if FightManager.stars_used >= stored_conditions.number_of_stars:
				return run_required_checks(stored_conditions, punch_height)
				
		KDConditionTypeEnum.STAR_PUNCHES_RECEIVED:
			if FightManager.star_punches_landed >= stored_conditions.star_punches_received:
				return run_required_checks(stored_conditions, punch_height)
				
		KDConditionTypeEnum.KNOCKDOWNS_BEFORE_ROUND_TIME:
			if FightManager.enemy_ko_count >= stored_conditions.knockdowns_required and FightManager.round_time <= stored_conditions.expected_round_time :
				return run_required_checks(stored_conditions, punch_height)
				
		KDConditionTypeEnum.NEVER_BEEN_HIT:
			if Global.player_node.health_component.hp == Global.player_node.health_component.max_hp :
				return run_required_checks(stored_conditions, punch_height)
			
		_: # Fallback
			return false
			
	return false # Fallback

## Runs only the required checks with the given parameters.
func run_required_checks(stored_conditions : KDConditions, punch_height : int) -> bool:
	
	# If the current animation matches the expected animation, then run check_for_punch_type().
	# Otherwise, don't bother running it.
	if check_for_expected_animation(stored_conditions) == true :
		
		# Stores the response of the function.
		var response : bool = check_for_punch_type(stored_conditions, punch_height)
		
		# If it was an instant knockdown, determine whether it's a simple knockdown or a full Knock-Out
		if response == true : 
			select_outcome(stored_conditions)
			
		return response # Returns the response of check_for_punch_type()
		
	return false # Fallback

## Selects the outcome of the Instant Knockdown depending on the condition.
func select_outcome(stored_conditions : KDConditions) -> void:
	match stored_conditions.resulting_outcome :
		OutcomeEnum.KNOCKDOWN:
			# Sets the variable to false since the enemy will just be knocked down
			is_fully_knocked_out = false
			return
			
		OutcomeEnum.FULL_KNOCKOUT:
			print_rich("[color=cyan]FULL KNOCKOUT[/color]")
			# Sets the variable to true so that the enemy can't get back up
			is_fully_knocked_out = true
			return

## Checks the [member KDConditions.punch_type_flags] and compares them to the given data of the player's landed punch.
func check_for_punch_type(stored_conditions : KDConditions, punch_height : int) -> bool:
	
	# Checks if the required punch has the "Star Punch" flag and if the punch received was a star punch.
	if stored_conditions.punch_type_flags & PunchTypeEnum.STAR_PUNCH and is_star_punch == false:
		
		# If the required punch HAS to be a star punch, but the received punch was not,
		# then the condition wasn't meant and it returns false.
		return false
	
	# IF both of the "High Punch" and "Low Punch" flags are set the identically, meaning that either both are true or both are false,
	# Then it means that the punch can be from any height range.
	if stored_conditions.punch_type_flags & PunchTypeEnum.HIGH_PUNCH == stored_conditions.punch_type_flags & PunchTypeEnum.LOW_PUNCH :
		
		return true
	
	# Checks if the required punch has the "High Punch" flag and if the punch received was a high punch.
	if stored_conditions.punch_type_flags & PunchTypeEnum.HIGH_PUNCH and punch_height != Global.HeightEnum.HIGH :
		
		# If the required punch HAS to be a High punch, but the received punch was not,
		# then the condition wasn't meant and it returns false.
		return false
	
	# Checks if the required punch has the "Low Punch" flag and if the punch received was a low punch.
	if stored_conditions.punch_type_flags & PunchTypeEnum.LOW_PUNCH and punch_height != Global.HeightEnum.LOW :
		
		# If the required punch HAS to be a Low punch, but the received punch was not,
		# then the condition wasn't meant and it returns false.
		return false
	
	return false # Fallback just in case.

## Checks if the expected animation is given/not empty.
## If it's empty, it's skips checking if it matches the current animation.
## If it's not empty and an animation is given, then it DOES check if it matches the current animation.
func check_for_expected_animation(stored_conditions : KDConditions) -> bool:
		
		# Checks if no expected animation has been set.
		# If there is no expected animation set, then default to returning true by skipping the check below.
		if stored_conditions.expected_animation.is_empty() == false : 
		
			# If expected animation HAS been set, check to see if the animation
			# that is currently being played matches expected one.
			if owner.anim_state_machine.get_current_node().contains(stored_conditions.expected_animation) == false :
				
				# If it DOES NOT match expected animation, return false.
				return false
			
		print_rich("[color=cyan]Instant KD component:[/color] KD condition met: ", KDConditionTypeEnum.find_key(stored_conditions.knockdown_condition))
		return true

## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "number_of_stars" and knockdown_condition != KDConditionTypeEnum.STARS_USED:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "expected_round_time" and knockdown_condition != KDConditionTypeEnum.KNOCKDOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "knockdowns_required" and knockdown_condition != KDConditionTypeEnum.KNOCKDOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "star_punches_received" and knockdown_condition != KDConditionTypeEnum.STAR_PUNCHES_RECEIVED:
		property.usage = PROPERTY_USAGE_NONE
