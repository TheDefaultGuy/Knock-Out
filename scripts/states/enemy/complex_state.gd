#@tool
#@icon("res://assets/icons/LucideSkull.svg")
#class_name ComplexState extends EnemyState
#
##region Exported Variables
#
#
#@export_category("🎬 Animations & Moveset")
#
#
#
#
##endregion
#
#
### The timer used to automatically go to the next state after time's up.
#var state_change_timer : Timer = null
### Timer used to automatically perform one of the given attacks.
#var attack_timer : Timer = null
#
### The Root State Machine of the Animation Tree.
### Its the base where all of the animations and nested state machines lie.
#var root_state_machine: AnimationNodeStateMachine = null
#
### The name of the nested state machine, if required.
#var nested_machine_name : StringName = ""
#
### The actual nested state machine
#var nested_state_machine : AnimationNodeStateMachine = null
#
#var current_animation_state_machine = null
#
### Stores the state type.
### This can be overwritten by inherited states.
#var state_type := STATE_TYPE_ENUM.SIMPLE
#
### Whether the state requires an attack timer.
### This can be overwritten by inherited states.
#var attack_timer_required : bool = true
#
	##conditions_and_target_states = [
		##[primary_condition, primary_target_state], 
		##[secondary_condition, secondary_target_state], 
		##[tertiary_condition, tertiary_target_state]
		##]
### Handles showing and hiding applicable exported variables
##func _validate_property(property: Dictionary) -> void: 
	##var conditions = [primary_condition, secondary_condition, tertiary_condition]
	##
	##if property.name == "target_round_time" and STATE_CHANGE_CONDITION.AT_ROUND_TIME not in conditions:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "time_to_wait" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "state_change_timer" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "target_hp" and STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW not in conditions:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "attack_delay_array" and attack_delay_type == ATTACK_DELAY.FLOAT:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "max_wait_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "min_wait_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "primary_target_state" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "secondary_target_state" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "tertiary_target_state" and tertiary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "block_cooldown" and block_behavior != BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "moveset_dictionary" and moveset_type != MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "moveset_array" and moveset_type != MOVESET_TYPE_ENUM.PICK_RANDOM or moveset_type != MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "max_wait_time" and attack_timer_required == false:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "min_wait_time" and attack_timer_required == false:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "attack_delay_type" and attack_timer_required == false:
		##property.usage = PROPERTY_USAGE_NONE
	##if property.name == "attack_delay_array" and attack_timer_required == false:
		##property.usage = PROPERTY_USAGE_NONE
#
#func _ready() -> void:
	#current_animation_state_machine = anim_state_machine
	#state_change_conditions = [primary_condition, secondary_condition, tertiary_condition]
	#
#
	#if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in state_change_conditions:
		#state_change_timer = create_timer("Wait Timer", true, time_to_wait)
		#add_child(state_change_timer)
		#
	#if attack_timer_required == true: # Creates and adds the attack timer as a child and connects it if it's required for the state.
		#attack_timer = create_timer("Attack Delay Timer", false, max_wait_time)
		#add_child(attack_timer)
		#
	#check_for_unassigned_variables()
	#
	#match state_type:
		#STATE_TYPE_ENUM.SIMPLE:
			#call_deferred("add_attack_animation_nodes")
			#return
		#STATE_TYPE_ENUM.NESTED_STATE_MACHINE:
			#call_deferred("add_nested_state_machine_node")
			#return
	#
### Checks to see if the user forgot to assign a state when they assigned a condition.
#func check_for_unassigned_variables() -> void:
	#if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		#printerr(self.name, " : Primary Target State has not been assigned despite having a condition set.")
	#if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		#printerr(self.name, " : Secondary Target State has not been assigned despite having a condition set.")
	#if tertiary_target_state == null and tertiary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		#printerr(self.name, " : Tertiary Target State has not been assigned despite having a condition set.")
	#if animation_tree == null:
		#printerr(self.name, " : Animation tree not set.")
	#if state_type == STATE_TYPE_ENUM.NESTED_STATE_MACHINE and nested_state_machine == null:
		#printerr(self.name, " : Nested State Machine has not been declared despite the state being set as Nested State Machine")
	#if moveset_type == MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY and moveset_dictionary == {}:
		#printerr(self.name, " : Moveset Dictionary does NOT contain any attacks.")
	#if moveset_type == MOVESET_TYPE_ENUM.PICK_RANDOM and moveset_array == []:
		#printerr(self.name, " : Moveset Array does NOT contain any attacks.")
	#if moveset_type == MOVESET_TYPE_ENUM.PREDETERMINED_ORDER and moveset_array == []:
		#printerr(self.name, " : Moveset Array does NOT contain any attacks.")
#
### Function that helps create a custom timer. Since it returns a Timer, it should be used to assign a timer to a variable.
#func create_timer(timer_name : String, one_shot : bool, wait : float) -> Timer:
	#var created_timer = Timer.new()
	#created_timer.name = str(timer_name)
	#created_timer.one_shot = one_shot
	#created_timer.wait_time = wait
	#return created_timer
	#
#
#
### Starts the attack delay timer using a random time.
###
### This function is called right after performing an attack and after the player or the enemy blocks.
#func start_attack_delay_timer() -> void:
	#match attack_delay_type:
		#ATTACK_DELAY.FLOAT:
			#attack_timer.start(randf_range(min_wait_time, max_wait_time)) # Sets a random time between the minimum and maximum values.
		#ATTACK_DELAY.PREDETERMINED:
			#attack_timer.start(attack_delay_array.pick_random()) # Randomly chooses one of the values in the attack delay array.
		#
### Function called when a block occurs.
### Handle attack delay times after a block.
#func handle_block() -> void:
	#match block_behavior:
		#BLOCK_BEHAVIOR_ENUM.RESET_TIMER:  # Restarts the attack timer on Block.
			#start_attack_delay_timer()
			#
		#BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER: # Briefly pauses the attack timer on Block.
			#attack_timer.paused = true
			#await get_tree().create_timer(block_cooldown).timeout
			#attack_timer.paused = false
			#
		#BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE: # If it's not applicable, do nothing.
			#return
			#
### Toggles on and off the state change timer when entering and exiting the state.
#func toggle_state_change_timer() -> void:
	#if state_change_timer == null:
		#return
	#if state_change_timer.is_stopped() == true:
		#state_change_timer.start()
		#return
	#if state_change_timer.time_left > 0.0:
		#state_change_timer.paused = !state_change_timer.paused
	#elif state_change_timer.time_left == 0.0:
		#check_time_has_passed()
		#return
#
##region Check Conditions Functions
### Checks to see if the wait timer has ran out so that the enemy can change state
#func check_round_time() -> void:
	#if FightManager.round_time >= target_round_time:
		#condition_match_direct_transition(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		#return
		#
### Checks to see if the enemy's HP has dropped below the target value.
#func check_enemy_health() -> void:
	#if health_component.hp < target_hp:
		#condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW)
		#return
	#
### Checks to see if the current round time matches the specified round time to change state.
#func check_time_has_passed() -> void:
	#if state_change_timer == null:
		#return
	#if state_change_timer.time_left == 0.0 :
		#condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
		#return
#
### Checks to see if the enemy is set to change condition after stun.
#func check_state_after_stun() -> void:
	#condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_STUN)
	#transition_to_stunned()
	#return
	#
### Checks the player stamina and then transitions to target state once it's zero.
#func check_player_stamina() -> void:
	#if FightManager.stamina <= 0:
		#condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
		#return
	#else:
		#condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_NOT_TIRED)
		#return
##endregion
#
##region Condition match functions
### If the condition is met, then directly go to the target state whenever possible. 
#func condition_match_direct_transition(condition : int) -> void:
	##for i in range(conditions_and_target_states.size()):
		##if conditions_and_target_states[i][0] == condition:
			##transition_to_target(conditions_and_target_states[i][1])
			#
	#match condition:
		#primary_condition:
			#transition_to_target(primary_target_state)
			#return
		#secondary_condition:
			#transition_to_target(secondary_target_state)
			#return
		#tertiary_condition:
			#transition_to_target(tertiary_target_state)
			#return
			#
### When the condition is met, set the interrupted state as the target state.
### This is used for when a condition is met by changing to a different state, such as Stunned, Spectating or Knocked Down.
### Basically, if enemy gets knocked down, instead of the enemy returning to this state after recovering,
### They will instead transition to the target state set in this one.
#func condition_match_change_interrupted_state(condition : int) -> void:
	#match condition:
		#primary_condition:
			#set_and_check_interrupted_state(primary_target_state)
			#return
		#secondary_condition:
			#set_and_check_interrupted_state(secondary_target_state)
			#return
		#tertiary_condition:
			#set_and_check_interrupted_state(tertiary_target_state)
			#return
			#
### Matches the signal received to the condition and then changes to the state of the matching condition.
#func check_state_change_condition(signal_name : StringName) -> void:
	#match signal_name:
		#"enemy_knocked_down_signal":
			#condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN)
			#await animation_tree.animation_finished
			#transition_to_knocked_down()
			#return
#
		#"player_knocked_down_signal":
			#condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			#await animation_tree.animation_finished
			#transition_to_spectating()
			#return
##endregion
#
##region Add attack animation nodes functions
#func add_nested_state_machine_node() -> void:
	#root_state_machine = animation_tree.tree_root
	#
	## Makes the name of the state machine the name of the node itself.
	## This helps avoid state machine nodes with similar names since nodes need unique names
	#nested_machine_name = str(self.name).to_snake_case() 
	#
	## Adds the state machine as a node in the Root state machine in the animation tree.
	#root_state_machine.add_node(nested_machine_name, nested_state_machine, Vector2(300.0,-550.0))
	#
	## Creates the transition that will connect the newly created node to the "hub_node"
	#var connection = AnimationNodeStateMachineTransition.new()
	#
	## Sets the transition to happen at the end of the animation.
	#connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END 
	#
	## Sets the transition to happen automatically.
	#connection.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	#
	#root_state_machine.add_transition(nested_machine_name, "hub_node", connection)
	#return
	#
#
	#
#
##endregion
#
#
### Checks if the player is able to transition and then transitions to the target state once it's possible.
### This is done to avoid cutting off animations.
#func transition_to_target(target_state : State) -> void:
	#if current_animation_state_machine != animation_tree["parameters/playback"]:
		#current_animation_state_machine.travel("End")
	#if anim_state_machine.get_current_node() == "idle" or anim_state_machine.get_current_node() == "idle_guard": # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		#transition(self, target_state)
#
### Checks to see if there is no target state set and then corrects it if there isnt.
#func set_and_check_interrupted_state(target_state) -> void:
	#if target_state == null:
		#get_parent().interrupted_state = self
		#printerr(str(target_state), " is not set in ", str(self.name))
		#return
	#get_parent().interrupted_state = target_state
	#return
	#
### Toggles the signals for going to Spectating, Knocked Down and Stunned state.
#func toggle_important_state_signal_connections() -> void:
	#if FightManager.player_knocked_down_signal.is_connected(check_state_change_condition) == true:
		#FightManager.player_knocked_down_signal.disconnect(check_state_change_condition)
	#else:
		#FightManager.player_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	#
	#if FightManager.enemy_knocked_down_signal.is_connected(check_state_change_condition) == true:
		#FightManager.enemy_knocked_down_signal.disconnect(check_state_change_condition)
	#else:
		#FightManager.enemy_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
		#
	#if defense_component.stunned_signal.is_connected(check_state_after_stun) == true:
		#defense_component.stunned_signal.disconnect(check_state_after_stun)
	#else:
		#defense_component.stunned_signal.connect(check_state_after_stun)
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
### Performs an action, animation or attack after the attack timer has finished.
#func perform_action() -> void:
	#print("Performing Attack...")
#
	#match moveset_type:
		#MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			#current_animation_state_machine.travel(get_weighted_choice(moveset_dictionary))
			#
			#await animation_tree.animation_finished # Resets the attack delay timer after attacking
			#start_attack_delay_timer()
			#return
		#MOVESET_TYPE_ENUM.PICK_RANDOM:
			#if moveset_array.size() == 1: # If theres only 1 move in the array, just choose it.
				#current_animation_state_machine.travel(moveset_array[0])
				#await animation_tree.animation_finished # Resets the attack delay timer after attacking
				#start_attack_delay_timer()
				#return
				#
			#current_animation_state_machine.travel(moveset_array.pick_random())
			#await animation_tree.animation_finished # Resets the attack delay timer after attacking
			#start_attack_delay_timer()
			#return
			#
		#MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			#if moveset_array.size() == 1: # If theres only 1 move in the array, just choose it.
				#current_animation_state_machine.travel(moveset_array[0])
				#await animation_tree.animation_finished # Resets the attack delay timer after attacking
				#start_attack_delay_timer()
				#return
				#
			#moveset_index = (moveset_index + 1) % moveset_array.size() # Wraps back to 0 if it reaches the end.
			#current_animation_state_machine.travel(moveset_array[moveset_index])
			#await animation_tree.animation_finished # Resets the attack delay timer after attacking
			#start_attack_delay_timer()
			#return
		#_:
			#printerr(self.name ," Fallback condition on the perform action function.")
	#
### Does the weight calculation and chooses a random move from the move set dictionary
#func get_weighted_choice(weight_dict: Dictionary) -> String:
	#
	## Calculates the sum of all weights
	#var total_weight: float = 0.0
	#
	#for weight in weight_dict.values():
		#total_weight += weight
	#
	## Picks a random number between 0 and the total weight
	#var rolled_value: float = randf_range(0.0, total_weight)
	#
	## Goes through the dictionary to find which bracket the roll falls into
	#for attack in weight_dict:
		#var weight: float = weight_dict[attack]
		#
		#if rolled_value < weight:
			#return attack # The chosen attack.
			#
		#rolled_value -= weight # Shrink the remaining roll value
	#
	#return str(weight_dict.keys().back()) # Fallback edge case
