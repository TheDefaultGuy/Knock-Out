@tool
class_name StateChangeManager extends Node

#region Exported Variables and function that handles which variables to show

var state_to_check : State = null

## Enum that stores all of the possible state change conditions.
enum STATE_CHANGE_CONDITION{
	## The enemy will change to the target state AT the specified ROUND time.
	AT_ROUND_TIME,
	
	## The enemy will change to the target state after they've been knocked down.
	AFTER_ENEMY_KNOCKED_DOWN,
	
	## The enemy will change to the target state after the player has been knocked down.
	AFTER_PLAYER_KNOCKED_DOWN,
	
	## The enemy will change to the target state AFTER the specified amount of time has elapsed.
	## Different to At Round Time since this can happen at different points in the round.
	AFTER_TIME_PASSED,
	
	## The enemy will change to the target state once the player is in the tired state.
	AFTER_PLAYER_TIRED,
	
	## The enemy will change to the target state when their health drops below a given value.
	AFTER_HEALTH_DROPS_BELOW,
	
	## The enemy will change to the target state once the player leaves the tired state.
	AFTER_PLAYER_NOT_TIRED,
	
	## The enemy will never change from this state.
	DO_NOT_CHANGE
}

## What to do when either the player or the enemy blocks an attack.
enum BLOCK_BEHAVIOR{
	## When a block occurs, it momentarily pauses the attack delay timer and then resumes after the block animation has finished.
	PAUSE_TIMER,
	## When a block occurs, it fully resets the attack delay timer. This can cause potential indefinite stalling.
	RESET_TIMER
}


@export_category("⇄ State Changing Conditions")

## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the primary target state.
## If it's not, it will check the secondary condition.
@export var primary_condition := STATE_CHANGE_CONDITION.AT_ROUND_TIME: 
	set(value):
		primary_condition = value
		notify_property_list_changed()
	
## The secondary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the secondary target state.
@export var secondary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
	set(value2):
		secondary_condition = value2
		notify_property_list_changed()

		
@export_category("🎯 Target States")
## The state the enemy will transition to after the primary condition is met.
@export var primary_target_state : State

## The state the enemy will transition to after the secondary condition is met.
@export var secondary_target_state : State

@export_category("*️⃣ State Changing Arguments")
## The time in the round (in seconds) where the enemy changes to the target state.
@export_range(10.0, 180.0, 1.0, "suffix:s") var target_round_time : float

## The amount of time the enemy waits (in seconds) before changing to the target state.
@export_range(5.0, 120.0, 1.0, "suffix:s") var time_to_wait : float = 5.0


var stored_round_time : float

## Timer used to transition to the target state.
var wait_timer : Timer = null

var root_state_machine: AnimationNodeStateMachine = null



## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "target_round_time" and primary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME and secondary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_wait" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "wait_timer" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "target_health" and primary_condition != STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW and secondary_condition != STATE_CHANGE_CONDITION.AFTER_HEALTH_DROPS_BELOW :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "primary_target_state" and primary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "secondary_target_state" and secondary_condition == STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		property.usage = PROPERTY_USAGE_NONE
#endregion

#region The Ready, Enter and Exit functions.
func _ready() -> void:
	create_timers()
	#root_state_machine = animation_tree.tree_root

	
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		printerr(self.name, " : Primary Target State not set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State not set.")
	#if animation_tree == null:
		#printerr(self.name, " : Animation tree not set.")

func enter() -> void:

	
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	#animation_tree.set("parameters/idle/blend_position", 0)
	#animation_tree.set("parameters/conditions/spectating", false)
	#FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	#FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	FightManager.player_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	
	# If the player or the enemy blocks an attack, it resets the attack delay timer
	## This is so that the timer doesn't accidently go off right after a block animation is playing.
	#FightManager.succesful_block_signal.connect(handle_block)

	#defense_component.stunned_signal.connect(transition_to_stunned)
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	

	
	wait_timer.start()
	wait_timer.paused = false
	
func exit() -> void:
	if wait_timer != null: # Shenanigans to pause the wait timer when transitioning to another scene.
		wait_timer.paused = true
		if wait_timer.time_left <= 0.0:
			wait_timer.wait_time = time_to_wait # Resets thet time if the timer has already reached zero.
		else:
			wait_timer.wait_time = wait_timer.time_left # Sets the time left to the time that was remaining on exit. Basically pauses the timer.
		
	#FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	#FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	FightManager.player_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	
	# If the player or the enemy blocks an attack, it resets the attack delay timer
	# This is so that the timer doesn't accidently go off right after a block animation is playing.
	#FightManager.succesful_block_signal.disconnect(handle_block)

	
#func _process(_delta: float) -> void:
	#if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		#return
	#if get_parent().current_state == state_to_check:
		#check_round_time()
		#check_stamina()
		#check_wait_time()
#endregion




	
## Checks to see if the current round time matches the specified round time to change state.
func check_wait_time() -> void:
	if wait_timer.time_left <= 0.0 :
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
		return

## Checks to see if the wait timer has ran out so that the enemy can change state
func check_round_time() -> void:
	if FightManager.round_time >= target_round_time:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		return

## Matches the signal received to the condition and then changes to the state of the matching condition.
func check_state_change_condition(signal_name : StringName) -> void:
	match signal_name:
		"enemy_knocked_down_signal":
			condition_match_set_inter_state(STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN)
			return

		"player_knocked_down_signal":
			condition_match_set_inter_state(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			return

## Checks the player stamina and then transitions to target state once it's zero.
func check_stamina() -> void:
	if FightManager.stamina <= 0:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
		return
	else:
		condition_match_direct_transition(STATE_CHANGE_CONDITION.AFTER_PLAYER_NOT_TIRED)
		return

## Creates the timers with code so that you don't have to make timer node and then manually assign it.
func create_timers() -> void:
	wait_timer = Timer.new()
	wait_timer.name = "Wait Timer"
	wait_timer.one_shot = true
	add_child(wait_timer)
	wait_timer.wait_time = time_to_wait
	
#region Helper Functions
## Helper function to make this more readable.
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
			

## Helper function that checks if the player is idle and transitions to the target state.
func transition_to_target(target_state : State) -> void:
	print("transition to: ", target_state.name)
	#if anim_state_machine.get_current_node() == "idle": # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		#transition(self, target_state)
#endregion
