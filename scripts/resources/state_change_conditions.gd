@tool
class_name StateChangeConditions extends Resource

#region Exported Variables




@export_category("⇄ State Changing Conditions")

## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the [member primary_target_state]
## If it's not, it will check the [member secondary_condition]
@export var state_change_condition := EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED : 
	set(value):
		if state_change_condition != value:
			state_change_condition = value
			notify_property_list_changed()


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


## Handles showing and hiding applicable exported variables in the inspector.
##
## If a specific condition is set, then it'll hide the variables that dont get used.
func _validate_property(property : Dictionary) -> void:
	if Engine.is_editor_hint() == false: # Doesn't run the check outside of the Editor
		return
	
	if property.name == "target_round_time" and EnemyState.StateChangeConditionEnum.AT_ROUND_TIME != state_change_condition:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_change_state" and EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED != state_change_condition:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "state_change_timer" and EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED != state_change_condition:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_hp" and EnemyState.StateChangeConditionEnum.AFTER_HEALTH_DROPS_BELOW != state_change_condition:
		property.usage = PROPERTY_USAGE_NONE
	#if property.name == "attack_delay_array" and attack_delay_type == AttackDelayTypeEnum.FLOAT:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "max_delay_time" and attack_delay_type == AttackDelayTypeEnum.PREDETERMINED:
		#property.usage = PROPERTY_USAGE_NONE
	#if property.name == "min_delay_time" and attack_delay_type == AttackDelayTypeEnum.PREDETERMINED:
		#property.usage = PROPERTY_USAGE_NONE
		
		
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

	#if property.name == "counter_attack" and block_behavior != BlockBehaviorEnum.COUNTER_ATTACK:
		#property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_damage_taken" and EnemyState.StateChangeConditionEnum.AFTER_TAKEN_AMOUNT_OF_DAMAGE != state_change_condition:
		property.usage = PROPERTY_USAGE_NONE
