@tool
@icon("res://assets/icons/LucideSkull.svg")

class_name EnemyState extends State

## The base [State] used by all attacking [Enemy] states.
## 
## Depending on the state that inherits it, it's possible to set the conditions
## for transitioning to a different as well as which state to transition to.
## The moveset/attacks that the [Enemy] will perform in the state.
## How the [Enemy] will behave in terms of choosing the attack, how they handle blocking, how they delay attacks, etc..

#region Enumerations
## What kind of state this is and whether it's a simple state or a state that uses a nested state machine.
enum STATE_TYPE_ENUM{
	
	## Means that this state doesn't requite any fancy nested state machines.
	## Usually means a state that does simple things like throw out attacks, block, get hit, get stunned, etc... 
	SIMPLE,
	
	## Means that the state doesn't require a Nested State Machine, but has multiple attacks chained together. 
	CHAINED_ATTACKS,
}

## Enum that stores all of the possible state change conditions.
enum STATE_CHANGE_CONDITION{
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
enum ATTACK_DELAY{
	## Will choose a float value BETWEEN the [member min_delay_time] and [member max_delay_time].
	FLOAT,
	
	## Instead of choosing a number BETWEEN a minumum and a maximum value, it will choose randomly from [member attack_delay_array].
	PREDETERMINED,
}

## How the moves in this state will be selected.
enum MOVESET_TYPE_ENUM{
	
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
enum BLOCK_BEHAVIOR_ENUM{
	
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

#@export var condictionary : Dictionary[NodePath, StateChangeConditions]

@export_category("⇄ State Changing Conditions")

## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the [member primary_target_state]
## If it's not, it will check the [member secondary_condition]
@export var primary_condition := STATE_CHANGE_CONDITION.AFTER_TIME_PASSED : 
	set(value):
		if primary_condition != value :
			primary_condition = value
			notify_property_list_changed()

## The secondary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the [member secondary_target_state]
## If it's not, it will check the [member tertiary_condition]
@export var secondary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE :
	set(value):
		if secondary_condition != value :
			secondary_condition = value
			notify_property_list_changed()

## The tertiary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the [member tertiary_target_state].
@export var tertiary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE :
	set(value): 
		if tertiary_condition != value :
			tertiary_condition = value
			notify_property_list_changed()

@export_category("🎯 Target States")
## The state the [Enemy] will transition to after the [member primary_condition] is met.
@export var primary_target_state : State

## The state the [Enemy] will transition to after the [member secondary_condition] is met.
@export var secondary_target_state : State

## The state the [Enemy] will transition to after the [member tertiary_condition] is met.
@export var tertiary_target_state : State


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

@export_category("🎬 Animations & Moveset")

## What type of moveset is available in this state.
@export var moveset_type := MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY :
	set(value):
		if moveset_type != value :
			moveset_type = value
			notify_property_list_changed()

## The available animations that can be called by the [member attack_timer] in this state stored as a weighted [Dictionary].
## The 1st variable or "key" is a string corresponding to the name of the move, and the 2nd variable corresponds to the weight or chance of that move.
@export var moveset_dictionary : Dictionary[String, float] = {}

## The available animations that can be called by the [member attack_timer] in this state stored as an array.
@export var moveset_array : Array[String] = []

@export_category("⏱ Attack Delays")

## What to do when an attack is blocked by either the [Player] or the [Enemy] when in this state.
@export var block_behavior := BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER :
	set(value):
		if block_behavior != value :
			block_behavior = value
			notify_property_list_changed()
		

## The attack that the [Enemy] will perform after blocking.
@export var counter_attack : String = "counter_uppercut"

## How the delay between each attack is handled.
@export var attack_delay_type := ATTACK_DELAY.FLOAT : 
	set(value):
		if attack_delay_type != value :
			attack_delay_type = value
			#notify_property_list_changed()
		
## The minimum amount of time (in seconds) the [Enemy] will wait before calling [method perform_action].
@export_range(0.0, 6.0, 0.1, "suffix:s") var min_delay_time : float = 1.0 :
	
	# Makes sure the set value is more than or equal to the minimum delay time.
	set(value):
		min_delay_time = value
		if max_delay_time < value :
			max_delay_time = value

## The maximum amount of time (in seconds) the [Enemy] will wait before calling [method perform_action].
@export_range(0.0, 6.0, 0.1, "suffix:s") var max_delay_time : float = 3.0 :
	
	# Makes sure the set value is more than or equal to the minimum delay time.
	set(value):
		if min_delay_time > value : 
			return
		max_delay_time = value

## An array of predetermined attack delay amounts. 
## Instead of choosing a number BETWEEN a minumum and a maximum value, it will choose randomly from the list of provided values instead.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var attack_delay_array : Array[float]
#endregion

#region Stored Variables

## The timer used to automatically go to the next state after time's up.
var state_change_timer : Timer = null

## Timer used to automatically perform one of the given attacks.
var attack_timer : Timer = null

## Dictionary that will store all of the Conditions and Target states.
var conditions_and_targets_dict: Dictionary[int, State] = { }

## Stores the state type.
## This can be overwritten by inherited states.
var state_type := STATE_TYPE_ENUM.SIMPLE

## Whether the state requires an attack timer.
## This can be overwritten by inherited states.
var attack_timer_required : bool = true

## Whether the state has been interrupted or not.
var interruption_status : bool = false

## The array/list of functions the state will check during process
## That way it only runs the functions that check for the conditions its assigned to,
var list_of_check_functions : Array[Callable] = []

## The current index of the [member moveset_array].
## Used so that it can loop back to the start and not look for a value beyond the range of the array
var moveset_index : int = 0

## Stores how much damage the enemy has received during this state so far.
var damage_taken_so_far : float = 0.0

## Stores an array of animations that need to be added to the animation tree,
## but aren't considered part of the moveset.
var additional_animations_to_add : Array[String] = []

@onready var animation_player: AnimationPlayer = %AnimationPlayer
#endregion
func _init() -> void:
	override_conditions_and_state_parameters()
	pass

func _enter_tree() -> void:
	override_conditions_and_state_parameters()
	pass

func _ready() -> void:
	# Array that stores the moves/animations that need to be added as animation nodes to the animation tree.
	var moves_arr : Array[String] = match_moveset_type()
	
	# Checks if there are any additional animations to add.
	if additional_animations_to_add.is_empty() == false :
		
		# Adds the additional animations so that they're added to the animation tree.
		moves_arr += additional_animations_to_add 
	
	# Adds the counter_attack animation to the list of moves if the block behavior is counter attack.
	if block_behavior == BLOCK_BEHAVIOR_ENUM.COUNTER_ATTACK : 
		moves_arr.append(counter_attack)
	
	#print(self.name, list_of_check_functions)
	
	set_conditions_and_targets_dictionary()
	
	if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in conditions_and_targets_dict.keys():
		state_change_timer = create_timer("Wait Timer", true, time_to_change_state)
		add_child(state_change_timer)
		
	# Creates and adds the attack timer as a child and connects it if it's required for the state.
	if attack_timer_required == true: 
		attack_timer = create_timer("Attack Delay Timer", true, max_delay_time)
		add_child(attack_timer)
		
	check_for_unassigned_variables() # Self-explanatory.
	
	
	# Checks the type of state it is so that it can properly set up the animation nodes in the animation tree.
	match state_type: 
		STATE_TYPE_ENUM.SIMPLE:
			if moves_arr.is_empty() == false or moves_arr != null :
				call_deferred("add_attack_animation_nodes", animation_tree.tree_root, moves_arr)
				
		STATE_TYPE_ENUM.CHAINED_ATTACKS:
			if moves_arr.is_empty() == false or moves_arr != null :
				call_deferred("add_chained_attack_animation_nodes", animation_tree.tree_root, moves_arr)
			
	# Sets the check condition functions that the state will run during process function of that state.
	set_condition_check_functions_based_on_conditions() 

#func _process(_delta: float) -> void:
	#if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		#return
	#if get_parent().current_state == self:
		#print(self.name)
		#print(list_of_check_functions)
		#check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

#region Enter and Exit functions
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	
	# Sets the idle blend to not stunned
	animation_tree.set(str("parameters/idle/blend_position"),  0)
	
	# Connects the enemy knocked down, player knocked down and stun signals.
	toggle_stunned_signal_connections() 
	
	# If the player or the enemy blocks an attack, it runs the handle_block() function.
	# This is so that the timer doesn't accidently go off right after a block animation is playing.
	FightManager.successful_block_signal.connect(handle_block)
	
	if attack_timer != null: # Checks if the state even has an attack timer
		attack_timer.timeout.connect(perform_action) # Connects the attack timer if it does exist.
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	state_machine.interrupted_state = self 
	
	if attack_timer != null and attack_timer_required == true :
		# Starts the attack delay timer so that the enemy can start attacking.
		start_attack_delay_timer()
	
	# Toggles the state change timer.
	# If it stopped or wasn't started, then it starts it.
	# If it was already started, the it toggles pause.
	toggle_state_change_timer()
	return

func exit() -> void:
	if attack_timer != null and attack_timer_required == true : # Checks if the state even has an attack timer
		attack_timer.stop() # Full on stops the attack timer since it's leaving the state.
		attack_timer.timeout.disconnect(perform_action)
	
	toggle_state_change_timer()
	
	toggle_stunned_signal_connections() # Disconnects the stun signal.
	
	FightManager.successful_block_signal.disconnect(handle_block) 
	
	# Resets the hit animation and state machine in the defense component back to the default hit animation.
	defense_component.reset_current_animations()
	return
#endregion

#region Check For Stuff Functions
## Checks to see if the user forgot to assign a state when they assigned a condition.
func check_for_unassigned_variables() -> void:
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_error(self.name, " : Primary Target State has not been assigned despite having a condition set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State has not been assigned despite having a condition set.")
	if tertiary_target_state == null and tertiary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Tertiary Target State has not been assigned despite having a condition set.")
	return

## Checks for errors and also returns an array with all of the moves.
func match_moveset_type() -> Array:
	if moveset_type == MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY and moveset_dictionary.is_empty() == true :
		push_error(self.name, " : Moveset Dictionary does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PICK_RANDOM and moveset_array.is_empty() == true:
		push_error(self.name, " : Moveset Array does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PREDETERMINED_ORDER and moveset_array.is_empty() == true:
		push_error(self.name, " : Moveset Array does NOT contain any attacks.")
		
	match moveset_type:
		MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			return moveset_dictionary.keys()
			
		MOVESET_TYPE_ENUM.PICK_RANDOM:
			return moveset_array
			
		MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			return moveset_array
			
		MOVESET_TYPE_ENUM.NOT_APPLICABLE:
			var empty : Array[String] = [] # Since the concept of a moveset doesn't apply, return empty array
			return empty
			
		_:
			printerr(self.name, " match_moveset_type() unnaccounted 5th option, returning moveset_array...")
			return moveset_array

## Checks for a required attack and then appends/adds it to the moveset dictionary or array if it's not found.
func check_for_attack_and_append(attack : String) -> void:
	
	# Checks if the animation is in the moveset array or dictionary (it depends which of the 2 based on the moveset type)
	if attack not in match_moveset_type():
		#print(self.get_script())
		#push_warning(self.name, " did NOT have a required animation in its moveset, which is required for this state. The fakeout animation has been added.")
		
		match moveset_type:
			MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
				moveset_dictionary[attack] = 20.0
				return
				
			MOVESET_TYPE_ENUM.PICK_RANDOM:
				moveset_array.append(attack)
				return 
				
			MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
				moveset_array.append(attack)
				return
			_:
				printerr(self.name, " check_for_attack_and_append() unnaccounted 4th option.")
				return 
	return
#endregion

#region Set Condition Stuff Functions

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

## Sets the [member list_of_check_functions] that will be checked by the state based on the conditions set for the state.
##
## Basically, it'll run the function for checking the [member primary_condition] first, then the [member secondary_condition] and so on.
## This makes it so that if multiple conditions are met, the [member primary_condition] has priority over the [member secondary_condition]
## since it gets checked first. This also has the benefit of only running the functions that are absolutely required.
func set_condition_check_functions_based_on_conditions() -> void:
	# Knockdowns have way more priority than all of the other checks,
	# thus, check_for_knockdowns is required by default and is the very first check that is called.
	list_of_check_functions = [check_for_knockdowns] 
	
	# Checks each condition (primary, secondary, tertiary...), 
	# and then appends the function that checks for that specific condition to the list_of_check_functions array.
	for condition in conditions_and_targets_dict.keys():
		match condition:
			STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED:
				list_of_check_functions.append(check_player_tired)
			STATE_CHANGE_CONDITION.AFTER_PLAYER_NOT_TIRED:
				list_of_check_functions.append(check_player_not_tired)
			STATE_CHANGE_CONDITION.AT_ROUND_TIME:
				list_of_check_functions.append(check_round_time)
			STATE_CHANGE_CONDITION.AFTER_TIME_PASSED:
				list_of_check_functions.append(check_time_has_passed)
			STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW:
				list_of_check_functions.append(check_enemy_health)
			STATE_CHANGE_CONDITION.AFTER_COMPLETION, STATE_CHANGE_CONDITION.STATE_INTERRUPTED:
				list_of_check_functions.append(check_state_completion)
			#STATE_CHANGE_CONDITION:
				#list_of_check_functions.append()
			#STATE_CHANGE_CONDITION:
				#list_of_check_functions.append()
				
	return
#endregion

#region Timer Related Functions
## Function that helps create a custom [Timer]. Since it returns a [Timer], it should be used to assign a timer to a variable.
func create_timer(timer_name : String, one_shot : bool, wait : float) -> Timer:
	var created_timer = Timer.new()
	created_timer.name = str(timer_name)
	created_timer.one_shot = one_shot
	created_timer.wait_time = wait
	return created_timer

## Starts the [member attack_delay_timer] using a random time value.
##
## This function is called right after performing an attack and after the [Player] or the [Enemy] blocks.
func start_attack_delay_timer() -> void:
	
	 # Checks if the attack timer even exists.
	if attack_timer == null :
		return
	
	match attack_delay_type: # Matches the selected attack delay type
		ATTACK_DELAY.FLOAT:
			attack_timer.start(randf_range(min_delay_time, max_delay_time)) # Sets the time as a random float value between the minimum and maximum values.
			return
			
		ATTACK_DELAY.PREDETERMINED:
			attack_timer.start(attack_delay_array.pick_random()) # Randomly chooses one of the values in the attack delay array.
			return
			
	return

## Function called when a block occurs.
##
## Handle attack delay times after a block.
func handle_block() -> void:
	match block_behavior:
		BLOCK_BEHAVIOR_ENUM.RESET_TIMER:  # Restarts the attack timer on Block.
			await animation_tree.animation_finished
			start_attack_delay_timer()
			return
			
		BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER: # Briefly pauses the attack timer on Block.
			if attack_timer != null : # Checks if the attack timer even exists.
				attack_timer.paused = true # Pauses the timer briefly while the block animation plays
				await animation_tree.animation_finished
				attack_timer.paused = false
			return
		
		BLOCK_BEHAVIOR_ENUM.COUNTER_ATTACK:
			await animation_tree.animation_finished
			play_attack_start_attack_timer(counter_attack)
			return
		
		BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE: # If it's not applicable, do nothing.
			return

## Toggles on and off the [member state_change_timer] when entering and exiting the state.
func toggle_state_change_timer() -> void:
	if state_change_timer == null : # Do nothing if there's no state change timer
		return
		
	if state_change_timer.is_stopped() == true :
		state_change_timer.start()
		return
		
	if state_change_timer.time_left > 0.0 :
		state_change_timer.paused = !state_change_timer.paused
		return
	elif state_change_timer.time_left == 0.0 :
		state_change_timer.wait_time = time_to_change_state
		return
#endregion

#region Check For Conditions Functions
## Goes through all of the functions in the [member list_of_check_functions] and calls each one.
## Also checks if any of the conditions are true and stops checking any condition that is lower priority.
func check_all_assigned_conditions() -> void:
	#print("check_all_assigned_conditions")
	
	# Runs each of the check functions in the order of priority.
	# Only runs the functions that check for the conditions the state has set.
	for check_function in list_of_check_functions: 
	
	# If the check function is returning true, then don't run any other check function after it.
		if check_function.call() == true: 
			return
			
## Checks to see if the current round time matches [member target_round_time] to change state.
func check_round_time() -> bool:
	if FightManager.round_time >= target_round_time:
		prints(FightManager.round_time, target_round_time)
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		return true
	return false

## Checks to see if the enemy's HP has dropped below the [member target_hp]
func check_enemy_health() -> bool:
	if health_component.hp <= target_hp:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW)
		return true
	return false

## Checks to see if the [member state_change_timer] has ran out so that the enemy can change state.
func check_time_has_passed() -> bool:
	#print("timepased")
	if state_change_timer == null:
		if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in conditions_and_targets_dict.keys() : # Checks if not having a state change timer is intended behavior.
			printerr(self.name, " has no State Change timer but is calling the check_time_has_passed() function")
		return false
	if state_change_timer.time_left == 0.0 :
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
		return true
	return false

## Checks to see if the [Enemy] is set to change condition after stun.
func check_state_after_stun() -> void:
	condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_STUN)
	transition_to_stunned()
	return

## Checks the [Player] [member FightManager.Stamina] and then transitions to target state once it's zero.
func check_player_tired() -> bool:
	if FightManager.stamina <= 0 :
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
		return true
	return false

## Checks the [Player] [member FightManager.Stamina] and then transitions to target state once it's NOT zero.
func check_player_not_tired() -> bool: 
	if FightManager.stamina > 0 :
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_NOT_TIRED)
		return true
	return false

## Checks if the state has completed or been interrupted and then changes accordingly.
func check_state_completion() -> bool:
	if anim_state_machine.get_current_node() in ["End", "idle"] :
		if interruption_status == true :
			condition_match_direct_transition(STATE_CHANGE_CONDITION.STATE_INTERRUPTED)
			return true
			
		elif interruption_status == false :
			condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_COMPLETION)
			return true
	return false

## Checks if the [Enemy] or the [Player] have been knocked down and then changes to the state of the matching condition.
func check_for_knockdowns() -> bool:
	match true:
		Global.enemy_node.is_knocked_down:
			condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN)
			transition_to_target(state_machine.knocked_down_state)
			return true
			
		Global.player_node.is_knocked_down:
			condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			transition_to_target(state_machine.spectating_state)
			return true
	return false

#endregion

#region Condition Match Functions
## If the condition is met, then directly go to the target state whenever possible. 
func condition_match_direct_transition(condition : int) -> void:
	# Iterates through the conditions_and_targets_dict instead of matching since its much easier to scale amount of possible conditions and target states.
	for key in conditions_and_targets_dict.keys() : 
		if key == condition :
			print("Condition Met: ", STATE_CHANGE_CONDITION.find_key(condition))
			#print("Target state: ", conditions_and_targets_dict[key].name)
			
			set_and_check_interrupted_state(conditions_and_targets_dict[key]) # Sets interrupted state as a fallback.
			
			transition_to_target(conditions_and_targets_dict[key]) # Finally transitions to the target
			return # Very important return since multiple conditions can be met.
			
## When the condition is met, set the [member StateMachine.interrupted_state] as the target state.
## This is used for when a condition is met by changing to a different state, such as [StunState], [EnemySpectating] or [EnemyKnockedDown.
## Basically, if [Enemy] gets knocked down, instead of the enemy returning to this state after recovering,
## They will instead transition to the target state set in this one.
func condition_match_change_interrupted_state(condition : int) -> void:
	# Iterates through the conditions_and_targets_dict instead of matching since its much easier to scale amount of possible conditions and target states.
	for key in conditions_and_targets_dict.keys(): 
		if key == condition:
			#print("Condition Met: ", STATE_CHANGE_CONDITION.find_key(condition))
			
			set_and_check_interrupted_state(conditions_and_targets_dict[key])
			
			return # Very important return since multiple conditions can be met.

#endregion

#region Add Attack Animation Nodes Functions

## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
func add_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String]) -> void:
	
	var new_origin = node_position_origin + (self.get_index() * node_positional_offset)
	
	if root_node.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
		
	array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		# If there is already an Animation node with that animation name, skip it.
		if root_node.has_node(str(attack)): 
			print("Already has the following animation: ", attack)
			continue
		if attack == "": # Catches empty strings
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		node_animation.animation = match_animation_library(attack)
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		root_node.add_node(str(attack), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -60.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		
		# Connects the animation to the "hub_node", where all attack animations connect to.
		root_node.call_deferred("add_transition", str(attack), "hub_node", create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO))
	return

## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
func add_chained_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array[String]) -> void:
	
	var new_origin = node_position_origin + (self.get_index() * node_positional_offset)
	
	if root_node.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
	
	array_remove_empty_entries(moveset) # Removes any empty entries to avoid any problems.
	
	# Makes a copy of the moveset array and then reverses it so that the attacks get added from last to first.
	# This is because it'll play the first move in the array, which has to be the last one added so that
	# It automatically goes to the next one.
	var reveresed_moveset = moveset.duplicate()
	reveresed_moveset.reverse()
	
	var modified_moveset : Array = format_moveset_for_unique_names(reveresed_moveset)
	
	# Adds the "hub_node" so that it can be connected to it.
	var node_array : Array = ["hub_node"]
	node_array += modified_moveset
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for i in range(reveresed_moveset.size()):
		
		if reveresed_moveset[i] == "": # Catches empty strings
			push_warning("add_chained_attack_animation_nodes(): Found an empty string.")
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		node_animation.animation = match_animation_library(reveresed_moveset[i])
		
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		root_node.add_node(str(modified_moveset[i]), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -80.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		if i == 0:
			# Connects the animation to the "hub_node", where all attack animations connect to.
			root_node.call_deferred("add_transition", str(modified_moveset[i]), str(node_array[i]), create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO))
		else:
			# Adds "Disabled" transitions so that thee nodes can still be easily deleted by the existing function.
			root_node.call_deferred("add_transition", str(modified_moveset[i]) , "hub_node", create_node_transition(AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED))
	return

func format_moveset_for_unique_names(array : Array) -> Array:
	var modified_arr : Array = []
	
	for i in range(array.size()): # Formats the names so that they're all unique.
		modified_arr.append(str(abs(i - array.size()), "_", get_index(), "_") + str(array[i]))
	return modified_arr

## Short little function that removes any duplicate entries in an Array.
func array_remove_duplicates(array: Array) -> Array:
	var output : Array = []
	for element in array: # Loops through the array
		if not element in output: # Checks if the item isn't in the output Array.
			output.append(element) # Adds the item to the output Array
	return output

## Short little function that removes any empty entries in an Array.
func array_remove_empty_entries(array: Array) -> Array:
	var output : Array = []
	for element in array:
		if element != "" or element != null:
			output.append(element)
			continue
	return output


## Creates and returns an Animation Node State Machine Transition.
func create_node_transition(mode) -> AnimationNodeStateMachineTransition:
	# Creates the transition that will connect the newly created node to the "hub_node"
	var connection : AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	
	# Sets the transition to happen at the end of the animation.
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END 
	
	# Sets the transition to happen automatically.
	connection.advance_mode = mode
	return connection

## Formats the string of the given attack animation so that it includes the preffix of the animation Library it belongs to.
func match_animation_library(attack : String) -> String:
	if attack == "" or attack == null: # Checks for empty strings and null values.
		printerr(self.name, ' empty or null attack animation string match_animation_library() function.')
		return ""
	
	for library in animation_player.get_animation_library_list(): # Grabs all of the animation libraries
		
		# Grabs the list of animations from each given animation library so that the libraries can be checked one by one.
		var animation_list = animation_player.get_animation_library(library).get_animation_list()
		
		for animation in animation_list: # Iterates through all of the animation in the library/list.
			
			if animation == attack: # Checks if the animation matches the attack.
				
				if library == "": # If it's the global library, the return the name of the animation without the forward slash "/"
					return str(animation)
					
				# Returns the name of the animation alongside the preffix of the animation library it belongs to.
				return str(library,"/",animation)
				
			continue # Go back to the start of the loop if the given attack name doesn't match the current animation name.
		
		continue # Go back to the start of the loop if the given attack name isn't in the current Library.
		
	printerr(self.name, " given attack animation name is not in any animation library: ", attack)
	return attack
#endregion

#region Transition related functions
## Checks if the [Player] is able to transition and then transitions to the target state once it's possible.
## This is done to avoid cutting off animations.
func transition_to_target(target_state : State) -> void:
	if attack_timer != null :
		attack_timer.stop() # Stops the attack timer to avoid shenanigans.
		
	#print("\ntransition_to_target function: ")
	#print("CURRENT NODE AT START: ",anim_state_machine.get_current_node())
	#print("target_state: ", target_state)
	#print("IS target_state SPECTATING: ", target_state is EnemySpectating)

	# Checks to see if the enemy is already in a "safe animation" so that it doesn't interrupt a hit, block, or any other animation.
	if anim_state_machine.get_current_node() in ["idle", "idle_guard", "End"]:
		
		
		transition(target_state)
		return
	
	else:
		#print("Not on a safe animation to transition on.")
		
		# If the current animation node isn't one of the "safe animations" like "idle", "idle_guard" or "End,
		# Then wait till the animation finishes playing, then travel to the "hub_node" and then return.
		# This will force the animation tree to land on one of the "safe animation" nodes so that it can then transition state.
		
		# If the target state is EnemyKnockedDown, then travel to the "knockdown" animation
		# and transition to the knockdown state.
		# This cuts off any animation and is required since going into Knockdown has way more priority than anything else.
		if target_state is EnemyKnockedDown : 
			#print("Traveling to knockdown")
			anim_state_machine.travel("knockdown")
			transition(target_state)
			return
		
		#print("PRE-AWAIT ANIMATION FINISHED")
		await animation_tree.animation_finished # Waits until the current attack/animation is finished before changing state.
		#print("POST-AWAIT ANIMATION FINISHED")
		
		
		#print("CURRENT NODE AFTER WAITING: ", anim_state_machine.get_current_node())

		# If the enemy is gonna enter Spectating, then it transitions after the current attack animation is finished.
		if target_state is EnemySpectating : 
			#print("Traveling to move_to_spectate")
			anim_state_machine.travel("move_to_spectate")
			transition(target_state)
			return
			
		if anim_state_machine.get_current_node() not in ["knockdown", "get_up", "move_to_spectate", "spectating"] :
			anim_state_machine.travel("hub_node") # Travels to the "hub_node" to go to the next state.
			transition(target_state)
			return
	return


## Checks to see if there is no target state set and then corrects it if there isnt.
func set_and_check_interrupted_state(target_state) -> void:
	if target_state == null : # Checks if the target state hasn't been set.
		
		# Sets the state itself as the interrupted state as a fallback.
		state_machine.interrupted_state = self 
		
		printerr("target_state  is not set in ", str(self.name))
		return
	
	# If the target state HAS been set, then it set the interrupted state.
	state_machine.interrupted_state = target_state
	return
	
## Toggles the signals for going to [StunState].
func toggle_stunned_signal_connections() -> void:
	if defense_component.stunned_signal.is_connected(check_state_after_stun) == true:
		defense_component.stunned_signal.disconnect(check_state_after_stun)
	else:
		defense_component.stunned_signal.connect(check_state_after_stun)
#endregion

#region Attacking related functions
## Performs an action/animation/attack after the [member attack_delay_timer] has finished.
func perform_action() -> void:
	match moveset_type:
		MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			play_attack_start_attack_timer(get_weighted_choice(moveset_dictionary))
			return
			
		MOVESET_TYPE_ENUM.PICK_RANDOM:
			play_attack_start_attack_timer(moveset_array.pick_random())
			return
			
		MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			moveset_index = (moveset_index + 1) % moveset_array.size() # Wraps back to 0 if it reaches the end.
			play_attack_start_attack_timer(moveset_array[moveset_index])
			return
			
		_:
			printerr(self.name ," Fallback condition on the perform_action() function.")
			return

## Helper function to make [method perform_action] more readable.
func play_attack_start_attack_timer(animation : String) -> void:
	if attack_timer != null : # Checks if the attack timer exists.
		attack_timer.stop()
	
	if animation == null :
		printerr(self.name, " play_attack_start_attack_timer(): given animation returned null.")
		return
	
	# Travels to the given animation on the animation tree.
	anim_state_machine.travel(animation)
	
	# Waits for the attack animation to finish before restarting the attack delay timer.
	await animation_tree.animation_finished
	
	start_attack_delay_timer() # Resets the attack delay timer after attacking
	
## Does the weight calculation and chooses a random move from the [member moveset_dictionary].
func get_weighted_choice(weight_dict: Dictionary) -> String:
	
	# Calculates the sum of all weights
	var total_weight : float = 0.0
	
	for weight in weight_dict.values():
		total_weight += weight
	
	# Picks a random number between 0 and the total weight
	var random_value : float = randf_range(0.0, total_weight)
	
	# Goes through the dictionary to find which bracket the roll falls into
	for attack in weight_dict:
		var weight : float = weight_dict[attack]
		
		if random_value < weight:
			return attack # The chosen attack.
			
		random_value -= weight # Shrink the remaining roll value
	
	return str(weight_dict.keys().back()) # Fallback edge case

#endregion

## Handles showing and hiding applicable exported variables in the inspector.
##
## If a specific condition is set, then it'll hide the variables that dont get used.
func _validate_property(property : Dictionary) -> void:
	if Engine.is_editor_hint() == false: # Doesn't run the check outside of the Editor
		return
	
	set_conditions_and_targets_dictionary()
	var conditions : Array = conditions_and_targets_dict.keys() # Grabs all of the conditions and puts them in an array for easier checking.

	if property.name == "target_round_time" and STATE_CHANGE_CONDITION.AT_ROUND_TIME not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_change_state" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "state_change_timer" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_hp" and STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "attack_delay_array" and attack_delay_type == ATTACK_DELAY.FLOAT:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "max_delay_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_delay_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		property.usage = PROPERTY_USAGE_NONE
		
	if property.name == "primary_target_state" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_target_state" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "tertiary_target_state" and tertiary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
		
		
	if property.name == "max_delay_time" and attack_timer_required == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_delay_time" and attack_timer_required == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "attack_delay_type" and attack_timer_required == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "attack_delay_array" and attack_timer_required == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_dictionary" and moveset_type != MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_array" and moveset_type not in [MOVESET_TYPE_ENUM.PICK_RANDOM, MOVESET_TYPE_ENUM.PREDETERMINED_ORDER]:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_condition" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "tertiary_condition" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "counter_attack" and block_behavior != BLOCK_BEHAVIOR_ENUM.COUNTER_ATTACK:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_damage_taken" and STATE_CHANGE_CONDITION.AFTER_TAKEN_AMOUNT_OF_DAMAGE not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	
	#Global.exported_properties_changed_signal.emit()
	return

## Overrides the default conditions and parameters for the state depending on the nature of the state.
## Each state should have it's own version of this function.
func override_conditions_and_state_parameters() -> void:
	pass
