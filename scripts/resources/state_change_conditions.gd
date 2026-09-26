@tool
class_name StateChangeConditions extends Resource

#region Enumerations
## What kind of state this is and whether it's a simple state or a state that uses a nested state machine.
enum StateTypeEnum{
	
	## Means that this state doesn't requite any fancy nested state machines.
	## Usually means a state that does simple things like throw out attacks, block, get hit, get stunned, etc... 
	SIMPLE,
	
	## Means that the state doesn't require a Nested State Machine, but has multiple attacks chained together. 
	CHAINED_ATTACKS,
}

## Enum that stores all of the possible state change conditions.
enum StateChangeConditionEnum{
	## The [Enemy] will change to the target state AFTER the specified [member time_to_change_state] has elapsed.
	## Different to At Round Time since this can happen at different points in the round.
	AFTER_TIME_PASSED,
	
	## The [Enemy] will change to the target state AT the specified [member target_round_time].
	AT_ROUND_TIME,
	
	## The [Enemy] will change to the target state after they've been knocked down.
	AFTER_ENEMY_KNOCKED_DOWN,
	
	## The [Enemy] will change to the target state after the [Player] has been knocked down.
	AFTER_PLAYER_KNOCKED_DOWN,
	
	## The [Enemy] will change to the target state once the [Player] is in the [TiredState].
	AFTER_PLAYER_TIRED,
	
	## The [Enemy] will change to the target state the moment their health drops below [member target_hp].
	AFTER_HEALTH_DROPS_BELOW,
	
	## The [Enemy] will change to the target state after taking a given amount of damage during the state and during [StunState].
	AFTER_TAKEN_AMOUNT_OF_DAMAGE,
	
	## The [Enemy] will change to the target state once the [Player] leaves the [TiredState].
	AFTER_PLAYER_NOT_TIRED,
	
	## The [Enemy] will change to the target state after entering [StunState].
	AFTER_STUN,
	
	### The [Enemy] will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_LANDED,
	
	### The [Enemy] will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_MISSED,
	
	## The [Enemy] will change to the target state after completing the state.
	## [u]ONLY USE FOR STATES THAT DON'T LOOP.[/u]
	AFTER_COMPLETION,
	
	## The [Enemy] will change to the target state after being interrupted in this state.
	STATE_INTERRUPTED,
	
	## The [Enemy] will never change from this state.
	DO_NOT_CHANGE,

}

## The behavior for the attack delay, or the time between each attack.
enum AttackDelayTypeEnum{
	## Will choose a float value BETWEEN the [member min_delay_time] and [member max_delay_time].
	FLOAT,
	
	## Instead of choosing a number BETWEEN a minumum and a maximum value, it will choose randomly from [member attack_delay_array].
	PREDETERMINED,
}

## How the moves in this state will be selected.
enum MovesetTypeEnum{
	
	## Randomly choose an animation from the weighted [member moveset_dictionary].
	WEIGHTED_DICTIONARY,
	
	## Will Randomly Choose a move the [member moveset_array] with equal probabilities.
	PICK_RANDOM,
	
	## The moves will be in a sequencial looping order that is predetermined from the [member moveset_array].
	PREDETERMINED_ORDER,
	
	## Means that the state doesn't really have a moveset.
	## Mainly used for special states without attacks or complex states 
	## that require nested animation state machines.
	NOT_APPLICABLE,
}

## What to do when either the [Player] or the [Enemy] blocks an attack.
enum BlockBehaviorEnum{
	
	## When a block occurs, it momentarily pauses the [member attack_delay_timer] and then resumes after the block animation has finished.
	PAUSE_TIMER,
	
	## When a block occurs, it fully resets the [member attack_delay_timer]. This can cause potential indefinite stalling.
	RESET_TIMER,
	
	## When a block occurs, the enemy will retaliate with an attack.
	COUNTER_ATTACK,
	
	## Don't do anything when a block occurs. This is for states where blocking shouldn't happen (since they aren't effective) or affect the enemy's behavior.
	NOT_APPLICABLE,
}
#endregion

#region Constants
## Offset added to each animation node's position so that they dont all overlap.
const node_positional_offset := Vector2(175.0, 0.0)

## The point in the animation tree where the nodes will be added.
const node_position_origin := Vector2(-1000.0,-500.0) 
#endregion

#region Exported Variables




@export_category("⇄ State Changing Conditions")

## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the [member primary_target_state]
## If it's not, it will check the [member secondary_condition]
@export var primary_condition := StateChangeConditionEnum.AFTER_TIME_PASSED : 
	set(value):
		if primary_condition != value :
			primary_condition = value
			notify_property_list_changed()

## The secondary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the [member secondary_target_state]
## If it's not, it will check the [member tertiary_condition]
@export var secondary_condition := StateChangeConditionEnum.DO_NOT_CHANGE :
	set(value):
		if secondary_condition != value :
			secondary_condition = value
			notify_property_list_changed()

## The tertiary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the [member tertiary_target_state].
@export var tertiary_condition := StateChangeConditionEnum.DO_NOT_CHANGE :
	set(value): 
		if tertiary_condition != value :
			tertiary_condition = value
			notify_property_list_changed()

@export_category("🎯 Target States")
## The state the [Enemy] will transition to after the [member primary_condition] is met.
var primary_target_state : State

## The state the [Enemy] will transition to after the [member secondary_condition] is met.
var secondary_target_state : State

var tertiary_target_state : State




@export_category("*️⃣ State Changing Arguments")
### Basically, ignore/override the conditions of the current state and transition to this state, 
### regardless of the current state, whenever the conditions of this state are met.
#@export var override_current_state : bool = false

## The time in the round (in seconds) where the [Enemy] changes to the target state.
@export_range(10.0, 180.0, 1.0, "suffix:s") var target_round_time : float = 20.0

## The amount of time the [Enemy] waits (in seconds) before changing to the target state.
@export_range(1.0, 90.0, 1.0, "suffix:s") var time_to_change_state : float = 5.0

## The HP the [Enemy] has to reach before changing to the target state.
@export_range(1.0, 100.0, 1.0, "suffix:hp") var target_hp : float = 30.0

## The HP the [Enemy] has to loose in this state before changing to the target state.
@export_range(1.0, 100.0, 1.0, "suffix:hp") var target_damage_taken : float = 30.0
#endregion

## Dictionary that will store all of the Conditions and Target states.
var conditions_and_targets_dict: Dictionary[int, State] = { }

## Sets [member conditions_and_targets_dict].
##
## Setting it as a dictionary makes scalability much easier and code much cleaner.
func set_conditions_and_targets_dictionary() -> void:
	conditions_and_targets_dict = {
		primary_condition: primary_target_state,
		secondary_condition: secondary_target_state,
		tertiary_condition: tertiary_target_state
		}
	return


## Handles showing and hiding applicable exported variables in the inspector.
##
## If a specific condition is set, then it'll hide the variables that dont get used.
func _validate_property(property : Dictionary) -> void:
	if Engine.is_editor_hint() == false: # Doesn't run the check outside of the Editor
		return
	
	set_conditions_and_targets_dictionary()
	var conditions : Array = conditions_and_targets_dict.keys() # Grabs all of the conditions and puts them in an array for easier checking.

	if property.name == "target_round_time" and StateChangeConditionEnum.AT_ROUND_TIME not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_change_state" and StateChangeConditionEnum.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "state_change_timer" and StateChangeConditionEnum.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_hp" and StateChangeConditionEnum.AFTER_HEALTH_DROPS_BELOW not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	#if property.name == "attack_delay_array" and attack_delay_type == AttackDelayTypeEnum.FLOAT:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "max_delay_time" and attack_delay_type == AttackDelayTypeEnum.PREDETERMINED:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "min_delay_time" and attack_delay_type == AttackDelayTypeEnum.PREDETERMINED:
		#property.usage = PROPERTY_USAGE_NONE
		
	if property.name == "primary_target_state" and primary_condition == StateChangeConditionEnum.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_target_state" and secondary_condition == StateChangeConditionEnum.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "tertiary_target_state" and tertiary_condition == StateChangeConditionEnum.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
		
		
	#if property.name == "max_delay_time" and attack_timer_required == false:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "min_delay_time" and attack_timer_required == false:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "attack_delay_type" and attack_timer_required == false:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "attack_delay_array" and attack_timer_required == false:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "moveset_dictionary" and moveset_type != MovesetTypeEnum.WEIGHTED_DICTIONARY:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "moveset_array" and moveset_type not in [MovesetTypeEnum.PICK_RANDOM, MovesetTypeEnum.PREDETERMINED_ORDER]:
		#property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_condition" and primary_condition == StateChangeConditionEnum.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "tertiary_condition" and secondary_condition == StateChangeConditionEnum.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	#if property.name == "counter_attack" and block_behavior != BlockBehaviorEnum.COUNTER_ATTACK:
		#property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_damage_taken" and StateChangeConditionEnum.AFTER_TAKEN_AMOUNT_OF_DAMAGE not in conditions:
		property.usage = PROPERTY_USAGE_NONE
