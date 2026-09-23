class_name KDConditions extends Resource
## Stores the variables and conditions for the given [member InstantKDComponent.expected_state] as an editable [Resource].
## Used by [InstantKDComponent].
	

## What condition type to use for granting an instant Knockdown.
@export var knockdown_condition := InstantKDComponent.KD_CONDITION_TYPE.STARS_USED :
	set(value):
		if knockdown_condition != value :
			knockdown_condition = value
			
			# Makes sure the punch type required is a Star punch if the condition is Stars used
			if knockdown_condition == InstantKDComponent.KD_CONDITION_TYPE.STARS_USED : 
				punch_type_flags |= InstantKDComponent.PUNCH_TYPE_ENUM.STAR_PUNCH
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
			if knockdown_condition == InstantKDComponent.KD_CONDITION_TYPE.STARS_USED :
				punch_type_flags |= InstantKDComponent.PUNCH_TYPE_ENUM.STAR_PUNCH
			notify_property_list_changed()

## The animation that has to be playing for the instant KD will occur.
@export var expected_animation : String = "jab"

## The number of stars required for the star punch to grant an instant KD.
@export_range (1, 3) var number_of_stars : int = 3

## The number of star punches landed required to grant an instant KD.
@export_range (1, 12) var star_punches_received : int = 6

## The number of star punches landed required to grant an instant KD.
@export_range (1, 6) var knockdowns_required : int = 1

## The round time required to grant an instant KD.
@export_range(10.0, 180.0, 1.0, "suffix:s") var expected_round_time : float

## The outcome/what the [Enemy] will do if all of the conditions are met and the instant knockdown is awarded.
@export var resulting_outcome := InstantKDComponent.OUTCOME_ENUM.KNOCKDOWN

	## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "number_of_stars" and knockdown_condition != InstantKDComponent.KD_CONDITION_TYPE.STARS_USED:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "expected_round_time" and knockdown_condition != InstantKDComponent.KD_CONDITION_TYPE.KNOCKDOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "knockdowns_required" and knockdown_condition != InstantKDComponent.KD_CONDITION_TYPE.KNOCKDOWNS_BEFORE_ROUND_TIME:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "star_punches_received" and knockdown_condition != InstantKDComponent.KD_CONDITION_TYPE.STAR_PUNCHES_RECEIVED:
		property.usage = PROPERTY_USAGE_NONE
