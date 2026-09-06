@icon("res://assets/icons/AtIconsComedyMask.svg")
@tool
## This is a template state used by enemy boxers.
## In this state, the enemy will keep looping the same animation, but react to the player's attacks.
## This is used to recreate boxers like Don Flamenco, where they taunt and only attack when attacked at first.
## You can set conditions to transition to another state if desired.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name TauntAndCounter extends State

#region Exported Variables and function that handles which variables to show
@export_category("🎬 Animations & Moveset")

## The taunt animation that will play in this state.
@export var taunt_animation : String = "taunt"
## The block animation that will lead to the counter attack.
@export var block_animation : String = "block_react"


@export_category("⏱ Taunt Delays")
## The minimum amount of time (in seconds) the enemy will wait before taunting.
@export_range(1.0, 8.0, 0.2, "suffix:s") var min_wait_time : float = 2.0
## The maximum amount of time (in seconds) the enemy will wait before taunting.
@export_range(1.0, 8.0, 0.2, "suffix:s") var max_wait_time : float = 5.0

@export_category("⇄ State Changing Conditions")
## The primary condition and the first one being checked.
## If the condition is met, it will transition to the primary target state.
## If it's not, it will check the secondary condition.
@export var primary_condition := STATE_CHANGE_CONDITION.AT_ROUND_TIME: 
	set(value):
		primary_condition = value
		notify_property_list_changed()
	
## The secondary condition and the second one being checked.
## If the condition is met, it will transition to the secondary target state.
@export var secondary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
	set(value2):
		secondary_condition = value2
		notify_property_list_changed()
		
## The state the enemy will transition to after the primary condition is met.
@export var primary_target_state : State
## The state the enemy will transition to after the secondary condition is met.
@export var secondary_target_state : State
## The time in the round (in seconds) where the enemy changes to the target state.
@export_range(10.0, 180.0, 1.0, "suffix:s") var target_round_time : float
## The amount of time the enemy waits (in seconds) before changing to the target state.
@export_range(5.0, 120.0, 1.0, "suffix:s") var time_to_wait : float = 5.0

var wait_timer : Timer = null
var taunt_timer : Timer = null

var root_state_machine: AnimationNodeStateMachine = null
var machine_name = null
@onready var state_machine : AnimationNodeStateMachine = preload("uid://bk1eoynjjkrt")

## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	var conditions = [primary_condition, secondary_condition]
	 
	
	if property.name == "target_round_time" and STATE_CHANGE_CONDITION.AT_ROUND_TIME not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_wait" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "wait_timer" and STATE_CHANGE_CONDITION.AFTER_TIME_PASSED not in conditions:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "primary_target_state" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_target_state" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
#endregion

#region The Ready, Enter and Exit functions.
func _ready() -> void:
	create_timers()
	machine_name = str(name).to_snake_case()
	call_deferred("add_attack_animation_nodes")
	
func add_attack_animation_nodes() -> void:
	root_state_machine = animation_tree.tree_root
	machine_name = str(name).to_snake_case()
	root_state_machine.add_node(machine_name, state_machine, Vector2(300.0,-550.0))
	var connection = AnimationNodeStateMachineTransition.new()
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	connection.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	root_state_machine.add_transition(machine_name, "hub_node", connection)
	#state_machine.get_node("taunt").animation = str(taunt_animation)
	#state_machine.get_node("block_react").animation = str(block_animation)
	
func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/stunned", false)
	animation_tree.set("parameters/conditions/spectating", false)

	anim_state_machine.travel(machine_name)
	animation_tree[str("parameters/",machine_name,"/playback")].travel("Start")
	start_attack_delay_timer()
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	

	

	FightManager.player_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	
	FightManager.no_stamina_signal.connect(check_state_change_condition.bind(FightManager.no_stamina_signal.get_name()))
	FightManager.succesful_block_signal.connect(start_attack_delay_timer)
	defense_component.stunned_signal.connect(transition_to_stunned)
	
	wait_timer.start()
	taunt_timer.timeout.connect(perform_taunt)
	
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		printerr(self.name, " : Primary Target State not set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State not set.")
	if animation_tree == null:
		printerr(self.name, " : Animation tree not set.")

	# Sets the block animation and state machine in the defense component as the block animation in the state machine.
	# This is because the defense component is the one responsible for playing the block animation
	defense_component.current_block_animation = str("block_react")
	defense_component.current_anim_state_machine = animation_tree[str("parameters/",machine_name,"/playback")]

	
func exit() -> void:
	taunt_timer.timeout.disconnect(perform_taunt)
	taunt_timer.stop()
	
	if wait_timer != null: # Shenanigans to pause the wait timer when transitioning to another scene.
		wait_timer.stop()
		if wait_timer.time_left <= 0:
			wait_timer.wait_time = time_to_wait
		else:
			wait_timer.wait_time = wait_timer.time_left
		
		
	FightManager.player_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.no_stamina_signal.disconnect(check_state_change_condition.bind(FightManager.no_stamina_signal.get_name()))
	FightManager.succesful_block_signal.disconnect(start_attack_delay_timer)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
	defense_component.reset_current_animations()
	animation_tree[str("parameters/",machine_name,"/playback")].travel("End")
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): #Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_round_time()
		check_stamina()
		check_wait_timer()
#endregion

## Starts the attack delay timer using a random time.
##
## This function is called right after performing an attack and after the player or the enemy blocks.
func start_attack_delay_timer() -> void:
	taunt_timer.start(randf_range(min_wait_time, max_wait_time)) # Starts the timer when entering the state and sets a random wait time.

func perform_taunt() -> void:
	animation_tree[str("parameters/",machine_name,"/playback")].travel("taunt")
	start_attack_delay_timer()

## Checks to see if the current round time matches the specified round time to change state.
func check_round_time() -> void: 
	if FightManager.round_time >= target_round_time:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		return

## Checks the player's stamina and transitions out of state if it's at 0.
func check_stamina() -> void:
	if FightManager.stamina <= 0:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
	return

func check_wait_timer() -> void:
	if wait_timer.time_left == 0.0:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
	return


func check_state_change_condition(signal_name : StringName) -> void:
	match signal_name:
		"enemy_knocked_down_signal":
			condition_match_set_inter_state(STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN)
			await animation_tree.animation_finished
			transition_to_knocked_down()
			return
			
		"player_knocked_down_signal":
			condition_match_set_inter_state(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			await animation_tree.animation_finished
			transition_to_spectating()
			return
		_:
			return
## Helper function to make the script more readable.
func condition_match_direct_transition(condition : int) -> void:
	match condition:
		primary_condition:
			transition_to_target(primary_target_state)
			return
		secondary_condition:
			transition_to_target(secondary_target_state)
			return
			
## Helper function to make this more readable.
func condition_match_set_inter_state(condition : int) -> void:
	match condition:
		primary_condition:
			get_parent().interrupted_state = primary_target_state
			return
		secondary_condition:
			get_parent().interrupted_state = secondary_target_state
			return

## Function called when the conditions to change state are met.
## The functions waits until the enemy is back in the "idle" animation,
## that way it doesn't awkwardly interrupt any other animations.
func transition_to_target(target_state : State) -> void:
	if anim_state_machine.get_current_node() == "idle" or anim_state_machine.get_current_node() == "idle_guard": # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		transition(self, target_state)

## Creates the timers with code so that you don't have to make timer node and then manually assign it.
func create_timers() -> void:
	taunt_timer = Timer.new()
	taunt_timer.name = "Taunt Delay Timer"
	add_child(taunt_timer)
	wait_timer = Timer.new()
	wait_timer.name = "Wait Timer"
	wait_timer.one_shot = true
	add_child(wait_timer)
	wait_timer.wait_time = time_to_wait
