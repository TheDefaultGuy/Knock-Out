@icon("res://assets/icons/MdiAlarmBell.svg")
## This is the component in charge of storing and checking the conditions for instant Knock-Out tricks for enemy fighters.
##
##
class_name InstantKOComponent extends Node

## Sets the condition for the player to get an instant KO.
enum KO_CONDITION{
	## Will grant a KO if the player lands a  punch that is at least worth the given star amount.
	STARS_USED,
	## Will grant a KO if the player lands another star punch after the enemy has already received the given star punch amount.
	STAR_PUNCHES_RECEIVED,
	## Will grant a KO if the player has already knocked down the enemy a given number of times before the given round time.
	KOS_BEFORE_ROUND_TIME,
	## Will grant a KO if the player hasn't been hit before in the round.
	NEVER_BEEN_HIT,
	## Will grant a KO if the enemy is stunned.
	STUNNED
}

enum PUNCH_TYPE{
	LOW_REGULAR_PUNCH,
	HIGH_REGULAR_PUNCH,
	LOW_STAR_PUNCH,
	HIGH_STAR_PUNCH
}

@export_category("Instant KO Conditions")
## What condition type to use for granting an instant KO.
@export var KO_condition := KO_CONDITION.STARS_USED
#@export var conditional_animation : String = "jab"
## The number of stars required for the star punch to grant an instant KO.
@export_range (1, 3) var number_of_stars : int = 3
## The number of star punches landed required to grant an instant KO.
@export_range (1, 12) var star_punches_landed : int = 6
## The punch type required to grant an instant KO.
@export var punch_condition : = PUNCH_TYPE.HIGH_STAR_PUNCH
## The round time required to grant an instant KO.
@export_range(10.0, 180.0, 1.0, "suffix:s") var ko_round_time : float
