@icon("res://assets/icons/MaterialSymbolsFactCheck.svg")

class_name StateChangeCheckManager extends Node
## Stores the functions called by [EnemyState] that check if the conditions for changing states have been met.


## Sets the [member EnemyState.list_of_check_functions] that will be checked by the state based on the conditions set for the state.
## Basically, it'll run the function for checking the [member EnemyState.primary_condition] first, then the [member EnemyState.secondary_condition] and so on.
## This makes it so that if multiple conditions are met, the [member EnemyState.primary_condition] has priority over the [member EnemyState.secondary_condition]
## since it gets checked first. This also has the benefit of only running the functions that are absolutely required.
static func set_condition_check_functions_based_on_conditions(conditions_and_targets_dict : Dictionary, _calling_state : State) -> Array[Callable]:
	# Knockdowns have way more priority than all of the other checks,
	# thus, check_for_knockdowns is required by default and is the very first check that is called.
	var array_of_check_functions: Array[Callable] = [check_for_knockdowns] 
	
	# Checks each condition (primary, secondary, tertiary...), 
	# and then appends the function that checks for that specific condition to the list_of_check_functions array.
	for condition in conditions_and_targets_dict.keys():
		match condition:
			EnemyState.StateChangeConditionEnum.AFTER_PLAYER_TIRED:
				array_of_check_functions.append(check_player_tired)
				
			EnemyState.StateChangeConditionEnum.AFTER_PLAYER_NOT_TIRED:
				array_of_check_functions.append(check_player_not_tired)
				
			EnemyState.StateChangeConditionEnum.AT_ROUND_TIME:
				array_of_check_functions.append(check_round_time)
				
			EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED:
				array_of_check_functions.append(check_time_has_passed)
				
			EnemyState.StateChangeConditionEnum.AFTER_HEALTH_DROPS_BELOW:
				array_of_check_functions.append(check_enemy_health)
				
			EnemyState.StateChangeConditionEnum.AFTER_COMPLETION, EnemyState.StateChangeConditionEnum.STATE_INTERRUPTED:
				array_of_check_functions.append(check_state_completion)
				
	return array_of_check_functions

## Checks to see if the current round time matches [member target_round_time] to change state.
static func check_round_time(calling_state : State) -> bool:
	if FightManager.round_time >= calling_state.target_round_time:
		#prints(FightManager.round_time, calling_state.target_round_time)
		calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AT_ROUND_TIME)
		return true
	return false

## Checks to see if the enemy's HP has dropped below the [member target_hp]
static func check_enemy_health(calling_state : State) -> bool:
	if calling_state.health_component.hp <= calling_state.target_hp:
		calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AFTER_HEALTH_DROPS_BELOW)
		return true
	return false

## Checks to see if the [member state_change_timer] has ran out so that the enemy can change state.
static func check_time_has_passed(calling_state : State) -> bool:
	#print("timepased")
	if calling_state.state_change_timer == null:
		if EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED in calling_state.conditions_and_targets_dict.keys() : # Checks if not having a state change timer is intended behavior.
			printerr(calling_state.name, " has no State Change timer but is calling the check_time_has_passed() function")
		return false
	if calling_state.state_change_timer.time_left == 0.0 :
		calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AFTER_TIME_PASSED)
		return true
	return false

## Checks to see if the [Enemy] is set to change condition after stun.
static func check_state_after_stun(calling_state : State) -> void:
	calling_state.condition_match_change_interrupted_state(EnemyState.StateChangeConditionEnum.AFTER_STUN)
	calling_state.transition_to_stunned()
	return

## Checks the [Player] [member FightManager.Stamina] and then transitions to target state once it's zero.
static func check_player_tired(calling_state : State) -> bool:
	if FightManager.stamina <= 0 :
		calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AFTER_PLAYER_TIRED)
		return true
	return false

## Checks the [Player] [member FightManager.Stamina] and then transitions to target state once it's NOT zero.
static func check_player_not_tired(calling_state : State) -> bool: 
	if FightManager.stamina > 0:
		calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AFTER_PLAYER_NOT_TIRED)
		return true
	return false

## Checks if the state has completed or been interrupted and then changes accordingly.
static func check_state_completion(calling_state : State) -> bool:
	if calling_state.anim_state_machine.get_current_node() == "idle":
		if calling_state.interruption_status == true:
			calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.STATE_INTERRUPTED)
			return true
			
		elif calling_state.interruption_status == false:
			calling_state.condition_match_direct_transition(EnemyState.StateChangeConditionEnum.AFTER_COMPLETION)
			return true
	return false

## Checks if the [Enemy] or the [Player] have been knocked down and then changes to the state of the matching condition.
static func check_for_knockdowns(calling_state : State) -> bool:
	match true:
		Global.enemy_node.is_knocked_down:
			calling_state.condition_match_change_interrupted_state(EnemyState.StateChangeConditionEnum.AFTER_ENEMY_KNOCKED_DOWN)
			calling_state.transition_to_target(calling_state.state_machine.knocked_down_state)
			return true
			
		Global.player_node.is_knocked_down:
			calling_state.condition_match_change_interrupted_state(EnemyState.StateChangeConditionEnum.AFTER_PLAYER_KNOCKED_DOWN)
			calling_state.transition_to_target(calling_state.state_machine.spectating_state)
			return true
	return false

#endregion
