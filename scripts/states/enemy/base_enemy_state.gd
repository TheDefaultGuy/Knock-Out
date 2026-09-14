@tool
@icon("res://assets/icons/LucideSkull.svg")
class_name EnemyState extends State

#region Exported Variables
@export_category("⇄ State Changing Conditions")

## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the primary target state.
## If it's not, it will check the secondary condition.
@export var primary_condition := STATE_CHANGE_CONDITION.AT_ROUND_TIME: 
	set(value):
		if primary_condition != value:
			primary_condition = value
			notify_property_list_changed()

## The secondary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the secondary target state.
@export var secondary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
	set(value):
		if secondary_condition != value:
			secondary_condition = value
			notify_property_list_changed()
## The ertiary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the ertiary target state.
@export var tertiary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
	set(value):
		if tertiary_condition != value:
			tertiary_condition = value
			notify_property_list_changed()
		
@export_category("🎯 Target States")
## The state the enemy will transition to after the primary condition is met.
@export var primary_target_state : State

## The state the enemy will transition to after the secondary condition is met.
@export var secondary_target_state : State

## The state the enemy will transition to after the tertiary condition is met.
@export var tertiary_target_state : State


@export_category("*️⃣ State Changing Arguments")
## The time in the round (in seconds) where the enemy changes to the target state.
@export_range(10.0, 180.0, 1.0, "suffix:s") var target_round_time : float

## The amount of time the enemy waits (in seconds) before changing to the target state.
@export_range(1.0, 120.0, 1.0, "suffix:s") var time_to_wait : float = 5.0

## The HP the enemy has to reach before changing to the target state.
@export_range(1.0, 100.0, 1.0, "suffix:hp") var target_hp : float = 30.0

@export_category("🎬 Animations & Moveset")
## What type of moveset is available in this state.
@export var moveset_type := MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
	set(value):
		if moveset_type != value:
			moveset_type = value
			notify_property_list_changed()

## The available animations that can be called by the attack timer in this state stored as a weighted Dictionary.
## The 1st variable or "key" is a string corresponding to the name of the move, and the 2nd variable corresponds to the weight or chance of that move.
@export var moveset_dictionary : Dictionary[String, float] = {}

## The available animations that can be called by the attack timer in this state stored as an array.
@export var moveset_array : Array[String] = []

## The current index of the moveset array.
## Used so that it can loop back to the start and not look for a value beyond the range of the array
var moveset_index : int = 0


@export_category("⏱ Attack Delays")
## What to do when an attack is blocked by either the player or the enemy when in this state.
@export var block_behavior := BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER

## How long will the attack timer be paused for if the enemy or player blocks.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var block_cooldown : float = 0.5

## How the delay between each attack is handled.
@export var attack_delay_type := ATTACK_DELAY.FLOAT: 
	set(value):
		if attack_delay_type != value:
			attack_delay_type = value
			notify_property_list_changed()
		
## The minimum amount of time (in seconds) the enemy will wait before performing an action.
@export_range(0.2, 6.0, 0.2, "suffix:s") var min_wait_time : float = 1.0

## The maximum amount of time (in seconds) the enemy will wait before performing an action.
@export_range(0.2, 6.0, 0.2, "suffix:s") var max_wait_time : float = 3.0

## An array of predetermined attack delay amounts. 
## Instead of choosing a number BETWEEN a minumum and a maximum value, it will choose randomly from the list of provided values instead.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var attack_delay_array : Array[float]
#endregion

#region Enumerations
## What kind of state this is and whether it's a simple state or a state that uses a nested state machine.
enum STATE_TYPE_ENUM{
	
	## Means that this state doesn't requite any fancy nested state machines.
	## Usually means a state that does simple things like throw out attacks, block, get hit, get stunned, etc... 
	SIMPLE,
	
	## Means that this state DOES require a nested state machine to work.
	NESTED_STATE_MACHINE
}

## Enum that stores all of the possible state change conditions.
enum STATE_CHANGE_CONDITION{
	## The enemy will change to the target state AFTER the specified amount of time has elapsed.
	## Different to At Round Time since this can happen at different points in the round.
	AFTER_TIME_PASSED,
	
	## The enemy will change to the target state AT the specified ROUND time.
	AT_ROUND_TIME,
	
	## The enemy will change to the target state after they've been knocked down.
	AFTER_ENEMY_KNOCKED_DOWN,
	
	## The enemy will change to the target state after the player has been knocked down.
	AFTER_PLAYER_KNOCKED_DOWN,
	
	## The enemy will change to the target state once the player is in the tired state.
	AFTER_PLAYER_TIRED,
	
	## The enemy will change to the target state when their health drops below a given value.
	AFTER_HEALTH_DROPS_BELOW,
	
	## The enemy will change to the target state once the player leaves the tired state.
	AFTER_PLAYER_NOT_TIRED,
	
	## The enemy will change to the target state after entering stun.
	AFTER_STUN,
	
	## The enemy will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_LANDED,
	
	## The enemy will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_MISSED,
	
	## The enemy will change to the target state after completing the state. ONLY USE FOR STATES THAT DON'T LOOP.
	AFTER_COMPLETION,
	
	## The enemy will change to the target state after being interrupted in this state.
	STATE_INTERRUPTED,
	
	## The enemy will never change from this state.
	DO_NOT_CHANGE
}

## The behavior fo th attack delay, or the time between each attack.
enum ATTACK_DELAY{
	## Will choose a float value BETWEEN the minimum and maximum wait time.
	FLOAT,
	
	## Instead of choosing a number BETWEEN a minumum and a maximum value, it will choose randomly from a list of provided values instead.
	PREDETERMINED
}

## How the moves in this state will be selected.
enum MOVESET_TYPE_ENUM{
	## Randomly choose an animation from a weighted dictionary.
	WEIGHTED_DICTIONARY,
	
	## Will Randomly Choose a move from an array with equal probabilities.
	PICK_RANDOM,
	
	## The moves will be in a sequencial looping order that is predetermined from an array.
	PREDETERMINED_ORDER,
	
	## Means that the state doesn't really have a moveset perse.
	## Mainly used for special states without attacks or complex states 
	## that require nested animation state machines.
	NOT_APPLICABLE
}

## What to do when either the player or the enemy blocks an attack.
enum BLOCK_BEHAVIOR_ENUM{
	## When a block occurs, it momentarily pauses the attack delay timer and then resumes after the block animation has finished.
	PAUSE_TIMER,
	## When a block occurs, it fully resets the attack delay timer. This can cause potential indefinite stalling.
	RESET_TIMER,
	## Don't do anything when a block occurs. This is for states where blocking shouldn't happen (since they aren't effective) or affect the enemy's behavior.
	NOT_APPLICABLE
}
#endregion

#region Stored Variables
@onready var animation_player: AnimationPlayer = %AnimationPlayer

## The timer used to automatically go to the next state after time's up.
var state_change_timer : Timer = null
## Timer used to automatically perform one of the given attacks.
var attack_timer : Timer = null

## The Root State Machine of the Animation Tree.
## Its the base where all of the animations and nested state machines lie.
var root_state_machine: AnimationNodeStateMachine = null

## The name of the nested state machine, if required.
var nested_machine_name : StringName = ""

## The actual nested state machine
var nested_state_machine : AnimationNodeStateMachine = null

## Dictionary that will store all of the Conditions and Target states.
var conditions_and_targets_dict: Dictionary[int, State] = { }

## The current animation state machine that the animations will be called/traveled to from.
var current_animation_state_machine = null

## Stores the state type.
## This can be overwritten by inherited states.
var state_type := STATE_TYPE_ENUM.SIMPLE

## Whether the state requires an attack timer.
## This can be overwritten by inherited states.
var attack_timer_required : bool = true

## Whether the state has been interrupted or not.
var interruption_status : bool = false
#endregion

#region Constants
## Offset added to each animation node's position so that they dont all overlap.
const node_positional_offset := Vector2(175.0, 0.0)
## The point in the animation tree where the nodes will be added.
const node_position_origin := Vector2(-1000.0,-500.0) 
#endregion

func _ready() -> void:
	nested_machine_name = str(self.name).to_snake_case() 
	
	var moves_arr : Array = match_moveset_type()
	
	set_conditions_and_targets_dictionary()
	
	current_animation_state_machine = anim_state_machine
	
	if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in conditions_and_targets_dict.keys():
		state_change_timer = create_timer("Wait Timer", true, time_to_wait)
		add_child(state_change_timer)
		
	if attack_timer_required == true: # Creates and adds the attack timer as a child and connects it if it's required for the state.
		attack_timer = create_timer("Attack Delay Timer", true, max_wait_time)
		add_child(attack_timer)
		
	check_for_unassigned_variables()
	
	match state_type:
		STATE_TYPE_ENUM.NESTED_STATE_MACHINE:
			call_deferred("add_nested_state_machine_node")
			call_deferred("add_attack_nodes_to_nested_state_machine", nested_state_machine, moves_arr)
		STATE_TYPE_ENUM.SIMPLE:
			call_deferred("add_attack_animation_nodes", animation_tree.tree_root, moves_arr)
			
#region Check For Stuff Functions
## Checks to see if the user forgot to assign a state when they assigned a condition.
func check_for_unassigned_variables() -> void:
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		printerr(self.name, " : Primary Target State has not been assigned despite having a condition set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State has not been assigned despite having a condition set.")
	if tertiary_target_state == null and tertiary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Tertiary Target State has not been assigned despite having a condition set.")
	if animation_tree == null:
		printerr(self.name, " : Animation tree not found/is null.")
	if state_type == STATE_TYPE_ENUM.NESTED_STATE_MACHINE and nested_state_machine == null:
		printerr(self.name, " : Nested State Machine has not been declared despite the state being set as Nested State Machine")
	return

## Checks for errors and also returns an array with all of the moves.
func match_moveset_type() -> Array:
	if moveset_type == MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY and moveset_dictionary == {} and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Dictionary does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PICK_RANDOM and moveset_array == [] and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Array does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PREDETERMINED_ORDER and moveset_array == [] and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Array does NOT contain any attacks.")
		
	match moveset_type:
		MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			return moveset_dictionary.keys()
		MOVESET_TYPE_ENUM.PICK_RANDOM:
			return moveset_array
		MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			return moveset_array
		_:
			printerr(self.name, " match_moveset_type() unnaccounted 4th option, returning moveset_array...")
			return moveset_array

## Checks for a required attack and then appends/adds it to the moveset dictionary or array if it's not found.
func check_for_attack_and_append(attack : String) -> void:
	if attack not in match_moveset_type():
		
		push_warning(self.name, " did NOT have a fakeout animation in its moveset, which is required for this state. The fakeout animation has been added.")
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
				printerr(self.name, " append_attack() unnaccounted 4th option.")
				return 
	return

## Sets the conditions and targets dictionary.
func set_conditions_and_targets_dictionary() -> void:
	conditions_and_targets_dict = {
		primary_condition: primary_target_state,
		secondary_condition: secondary_target_state,
		tertiary_condition: tertiary_target_state
		}
#endregion

#region Timer Related Functions
## Function that helps create a custom timer. Since it returns a Timer, it should be used to assign a timer to a variable.
func create_timer(timer_name : String, one_shot : bool, wait : float) -> Timer:
	var created_timer = Timer.new()
	created_timer.name = str(timer_name)
	created_timer.one_shot = one_shot
	created_timer.wait_time = wait
	return created_timer

## Starts the attack delay timer using a random time.
##
## This function is called right after performing an attack and after the player or the enemy blocks.
func start_attack_delay_timer() -> void:
	match attack_delay_type:
		ATTACK_DELAY.FLOAT:
			attack_timer.start(randf_range(min_wait_time, max_wait_time)) # Sets a random time between the minimum and maximum values.
		ATTACK_DELAY.PREDETERMINED:
			attack_timer.start(attack_delay_array.pick_random()) # Randomly chooses one of the values in the attack delay array.
		
## Function called when a block occurs.
## Handle attack delay times after a block.
func handle_block() -> void:
	match block_behavior:
		BLOCK_BEHAVIOR_ENUM.RESET_TIMER:  # Restarts the attack timer on Block.
			await animation_tree.animation_finished
			start_attack_delay_timer()
			
		BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER: # Briefly pauses the attack timer on Block.
			attack_timer.paused = true
			await animation_tree.animation_finished
			attack_timer.paused = false
			
		BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE: # If it's not applicable, do nothing.
			return
			
## Toggles on and off the state change timer when entering and exiting the state.
func toggle_state_change_timer() -> void:
	if state_change_timer == null:
		return
	if state_change_timer.is_stopped() == true:
		state_change_timer.start()
		return
	if state_change_timer.time_left > 0.0:
		state_change_timer.paused = !state_change_timer.paused
	elif state_change_timer.time_left == 0.0:
		state_change_timer.wait_time = time_to_wait
		return
#endregion

#region Check For Conditions Functions
## Checks to see if the wait timer has ran out so that the enemy can change state.
func check_round_time() -> void:
	if FightManager.round_time >= target_round_time:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		return

## Checks to see if the enemy's HP has dropped below the target value.
func check_enemy_health() -> void:
	if health_component.hp <= target_hp:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW)
		return

## Checks to see if the current round time matches the specified round time to change state.
func check_time_has_passed() -> void:
	if state_change_timer == null:
		if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in [primary_condition, secondary_condition, tertiary_condition]: # Checks if not having a state change timer is intended behavior.
			printerr(self.name, " has no State Change timer but is calling the check_time_has_passed() function")
		return
	if state_change_timer.time_left == 0.0 :
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
		
		return

## Checks to see if the enemy is set to change condition after stun.
func check_state_after_stun() -> void:
	condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_STUN)
	transition_to_stunned()
	return

## Checks the player stamina and then transitions to target state once it's zero.
func check_player_stamina() -> void:
	if FightManager.stamina <= 0:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
		return
	elif FightManager.stamina > 0:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_NOT_TIRED)
		return

## Checks if the state has completed or been interrupted and then changes accordingly.
func check_state_completion() -> void:
	#print("BASE STATE FUNC: ", current_animation_state_machine.get_current_node())
	#print("interruption_status: ", interruption_status)
	if current_animation_state_machine.get_current_node() == "End" :
		if interruption_status == true:
			condition_match_direct_transition(STATE_CHANGE_CONDITION.STATE_INTERRUPTED)
			return
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_COMPLETION)
		return

## Checks if the Enemy or the Player have been knocked down and then changes to the state of the matching condition.
func check_for_knockdowns() -> void:
	match true:
		Global.enemy_node.isKnockdown:
			condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN)
			transition_to_target(get_parent().knocked_down_state)
		Global.player_node.isKnockdown:
			condition_match_change_interrupted_state(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			transition_to_target(get_parent().spectating_state)
	return

#endregion

#region Condition Match Functions
## If the condition is met, then directly go to the target state whenever possible. 
func condition_match_direct_transition(condition : int) -> void:
	# Iterates through the conditions_and_targets_dict instead of matching since its much easier to scale amount of possible conditions and target states.
	for key in conditions_and_targets_dict.keys(): 
		if key == condition:
			print("Condition Met: ", STATE_CHANGE_CONDITION.find_key(condition))
			print("Target state: ", conditions_and_targets_dict[key].name)
			transition_to_target(conditions_and_targets_dict[key])
			set_interrupted_state(conditions_and_targets_dict[key]) # Also sets interrupted state as a fallback.
			return # Very important return since multiple conditions can be met.
			
## When the condition is met, set the interrupted state as the target state.
## This is used for when a condition is met by changing to a different state, such as Stunned, Spectating or Knocked Down.
## Basically, if enemy gets knocked down, instead of the enemy returning to this state after recovering,
## They will instead transition to the target state set in this one.
func condition_match_change_interrupted_state(condition : int) -> void:
	# Iterates through the conditions_and_targets_dict instead of matching since its much easier to scale amount of possible conditions and target states.
	for key in conditions_and_targets_dict.keys(): 
		if key == condition:
			print("Condition Met: ", STATE_CHANGE_CONDITION.find_key(condition))
			set_interrupted_state(conditions_and_targets_dict[key])
			return # Very important return since multiple conditions can be met.

## Just sets the interrupted state.
func set_interrupted_state(state : State) -> void:
	get_parent().interrupted_state = state
#endregion

#region Add Attack Animation Nodes Functions
## Adds a nested animation state machine node to the root animation state machine.
func add_nested_state_machine_node() -> void:
	root_state_machine = animation_tree.tree_root
	
	if root_state_machine.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
	
	# Makes the name of the state machine the name of the node itself.
	# This helps avoid state machine nodes with similar names since nodes need unique names
	nested_machine_name = str(self.name).to_snake_case() 
	
	if root_state_machine.has_node(nested_machine_name): # Checks to see if the root state machine already has a nested state machine of that name
		push_warning("Root State Machine already has a Nested State Machine of the same name: ", str(nested_machine_name))
		return
	
	var new_origin = node_position_origin + (self.get_index() * node_positional_offset)
	
	# Adds the state machine as a node in the Root state machine in the animation tree.
	root_state_machine.add_node(nested_machine_name, nested_state_machine, new_origin)
	
	root_state_machine.add_transition(nested_machine_name, "hub_node", create_node_transition())
	return
	
## Automatically adds all of the attack names as nodes in the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
func add_attack_animation_nodes(root_node : AnimationRootNode, moveset : Array) -> void:
	
	var new_origin = node_position_origin + (self.get_index() * node_positional_offset)
	
	if root_node.has_node("hub_node") == false:
		printerr(self.name, ': ROOT state machine does NOT have a "hub_node" to attach the attacks to.')
		return
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		# If there is already an Animation node with that animation name, skip it.
		if root_node.has_node(str(attack)): 
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
		root_node.call_deferred("add_transition", str(attack), "hub_node", create_node_transition())
	return

## Automatically adds all of the attack names as nodes in a Nested State machine that is in the Root State Machine of the animation tree.
## Theoretically allows attack animations to be in nested nodes by giving it the nested
## State machine as an argument instead of the root state machine.
func add_attack_nodes_to_nested_state_machine(target_node : AnimationNodeStateMachine, moveset : Array) -> void:
	
	var new_origin = node_position_origin + (self.get_index() * node_positional_offset) # Offsets the node's position based on the child index.
	
	if target_node.has_node("hub_node") == false:
		push_warning(self.name, ': target node does not have a "hub_node" to attach the attacks to.')
		return
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		# If there is already an Animation node with that animation name, skip it.
		if target_node.has_node(str(attack)): 
			continue
			
		if attack == "": # Catches empty strings
			continue
			
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		node_animation.animation = match_animation_library(attack)
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		target_node.add_node(str(attack), node_animation, new_origin) 
		
		new_origin += Vector2(0.0, -60.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		
		# Connects the animation to the "hub_node", where all attack animations connect to.
		target_node.call_deferred("add_transition", str(attack), "hub_node", create_node_transition())
	return

	
## Idea for this function would be to make a loop of attacks for flurry state
func add_looping_attacks_to_nested_state_machine(target_node : AnimationNodeStateMachine, moveset : Array) -> void:
	
	#if target_node.has_node("hub_node") == false:
		#push_warning(self.name, ': target node does not have a "hub_node" to attach the attacks to.')
		#return
	
	
	# Adds the state machine as a node in the Root state machine in the animation tree.
	var loop_node := AnimationNodeStateMachine.new()
	
	target_node.add_node(str("nested_machine_name_loop",get_index()), loop_node, Vector2(0.0, 0.0))
	
	var angle_diff := 360.0 / float(moveset.size())
	const r := 100.0

	var stored_angle := 0.0
	
	var stored_attack_name : String = ""
	
	var stored_index : int = 0
	
	# Iterates through each of the attacks in the moveset dictionary to add their animations to the root state machine.
	for attack in moveset:
		
		var x = r * cos(deg_to_rad(stored_angle))
		var y = r * sin(deg_to_rad(stored_angle))
		var new_origin = Vector2(x, y)
		
		# If there is already an Animation node with that animation name, skip it.
		if loop_node.has_node(str(attack)): 
			continue
		
		# Creates a new AnimationNodeAnimation that'll be added to the Root State Machine
		var node_animation : AnimationNodeAnimation = AnimationNodeAnimation.new()
		
		# Sets the Node's animation as the attack animation given.
		node_animation.animation = match_animation_library(attack)
		
		# Adds the state machine as a node in the Root state machine in the animation tree.
		loop_node.add_node(str(attack), node_animation, new_origin) 
		
		stored_angle += angle_diff
		
		
		
		#new_origin += Vector2(0.0, -60.0) # Offsets each node's position so that they dont all overlap in the animation tree.
		if moveset[stored_index - 1] != "" or moveset[stored_index - 1] != null:
			# Connects the animation to the "hub_node", where all attack animations connect to.
			target_node.call_deferred("add_transition", moveset[stored_index - 1], attack, create_node_transition())
		
		stored_index = (stored_index + 1) % moveset.size() # Wraps back to 0 if it reaches the end.
	return
	
## Creates and returns an Animation Node State Machine Transition.
func create_node_transition() -> AnimationNodeStateMachineTransition:
	# Creates the transition that will connect the newly created node to the "hub_node"
	var connection : AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
	
	# Sets the transition to happen at the end of the animation.
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END 
	
	# Sets the transition to happen automatically.
	connection.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	return connection

## Formats the string of the given attack animation so that it includes the preffix of the animation Library it belongs to.
func match_animation_library(attack : String) -> String:
	if attack == "" or attack == null: # Checks for empty strings and null values.
		printerr(self.name, ' empty or null attack animation string match_animation_library() function.')
		return ""
	
	for library in animation_player.get_animation_library_list(): # Grabs all of the animation libraries
		
		# Grabs the list of animations from each given animation library so that the libraries can be checked one by one.
		var animation_list = animation_player.get_animation_library(library).get_animation_list()
		
		for animation in animation_list:
			
			if animation == attack:
				
				if library == "": # If it's the global library, the return the name of the animation without the forward slash "/"
					return str(animation)
					
				# Returns the name of the animation alongside the preffix of the animation libray it belongs to.
				return str(library,"/",animation)
				
			continue # Go back to the start of the loop if the given attack name doesn't match the current animation name.
		
		continue # Go back to the start of the loop if the given attack name isn't in the current Library.
		
	printerr(self.name, " given attack animation name is not in any animation library: ", attack)
	return attack
#endregion

#region Transition related functions
## Checks if the player is able to transition and then transitions to the target state once it's possible.
## This is done to avoid cutting off animations.
func transition_to_target(target_state : State) -> void:
	if current_animation_state_machine.get_current_node() in ["idle", "idle_guard", "End"] or target_state is EnemyKnockedDown: # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		if current_animation_state_machine != animation_tree["parameters/playback"]:
			current_animation_state_machine.travel("End")
			current_animation_state_machine = animation_tree["parameters/playback"]
		transition(self, target_state)

## Checks to see if there is no target state set and then corrects it if there isnt.
func set_and_check_interrupted_state(target_state) -> void:
	if target_state == null:
		get_parent().interrupted_state = self
		printerr(str(target_state), " is not set in ", str(self.name))
		return
	get_parent().interrupted_state = target_state
	return
	
## Toggles the signals for going to Spectating, Knocked Down and Stunned state.
func toggle_stunned_signal_connections() -> void:
	if defense_component.stunned_signal.is_connected(check_state_after_stun) == true:
		defense_component.stunned_signal.disconnect(check_state_after_stun)
	else:
		defense_component.stunned_signal.connect(check_state_after_stun)
#endregion

#region Attacking related functions
## Performs an action/animation/attack after the attack timer has finished.
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

## Helper function to make perform_action() more readable.
func play_attack_start_attack_timer(animation : String) -> void:
	current_animation_state_machine.travel(animation)
	
	# Waits for the attack animation to finish before restarting the attack delay timer.
	await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.

	start_attack_delay_timer() # Resets the attack delay timer after attacking
	
## Does the weight calculation and chooses a random move from the moveset dictionary.
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
## If a specific condition is set, then it'll hide the variables that dont get used.
## This is stored as a seperate function in the Enemy State Class since some state have to override
## some of the variables before updated the exported variables.
func update_shown_exported_variables(property : Dictionary) -> void:
	if Engine.is_editor_hint() == false: #Doesnt run the check outside of the Editor
		return
	
	set_conditions_and_targets_dictionary()
	var conditions = conditions_and_targets_dict.keys()
	
	if property.name == "target_round_time" and STATE_CHANGE_CONDITION.AT_ROUND_TIME not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_wait" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "state_change_timer" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_hp" and STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "attack_delay_array" and attack_delay_type == ATTACK_DELAY.FLOAT:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "max_wait_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_wait_time" and attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		property.usage = PROPERTY_USAGE_NONE
		
	if property.name == "primary_target_state" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_target_state" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "tertiary_target_state" and tertiary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
		
	if property.name == "block_cooldown" and block_behavior != BLOCK_BEHAVIOR_ENUM.PAUSE_TIMER:
		property.usage = PROPERTY_USAGE_NONE
		
	if property.name == "max_wait_time" and attack_timer_required == false:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_wait_time" and attack_timer_required == false:
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
	return
