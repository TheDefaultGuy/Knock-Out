@icon("res://assets/icons/TablerEyeExclamation.svg")
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
class_name ReactionaryState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

#region Exported Variables and function that handles which variables to show
@export_category("🎬 Animations & Moveset")
## The idling animation that will play in this state.
@export var state_machine_animation : String = "reactionary"


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
	
	## The enemy will never change from this state.
	DO_NOT_CHANGE
}

@export_category("⏱ Taunt Delays")
## A Multipurpose timer that can be used by various states.
@export var general_timer : Timer
## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_wait_time : float = 2.0
## The maximum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_wait_time : float = 5.0

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
@export_range(1.0, 90.0, 1.0, "suffix:s") var time_to_wait : float

@export var wait_timer : Timer


## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "target_round_time" and primary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME and secondary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_wait" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "wait_timer" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
#endregion

#region The Ready, Enter and Exit functions.
func _ready() -> void:
	if general_timer == null:
		printerr(self.name, " : General Timer not set.")
	
	if wait_timer != null:
		wait_timer.wait_time = time_to_wait
		wait_timer.one_shot = true
	
func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/stunned", false)
	animation_tree.set("parameters/conditions/spectating", false)

	
	anim_state_machine.travel(state_machine_animation)
	start_attack_delay_timer()
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	
	FightManager.player_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.no_stamina_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.succesful_block_signal.connect(start_attack_delay_timer)
	defense_component.stunned_signal.connect(transition_to_stunned)
	
	if wait_timer != null:
		wait_timer.start()
		wait_timer.timeout.connect(_on_wait_timer_timeout)
	
	
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		printerr(self.name, " : Primary Target State not set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State not set.")
	if animation_tree == null:
		printerr(self.name, " : Animation tree not set.")
	if primary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED or secondary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED:
		if wait_timer == null:
			printerr(self.name, " : Wait Timer not set.")
			
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = str("item_hit")
	defense_component.current_anim_state_machine = animation_tree[str("parameters/", state_machine_animation ,"/playback")]
	defense_component.lower_blocking_status = true
	defense_component.upper_blocking_status = true
func exit() -> void:
	general_timer.timeout.disconnect(perform_action)
	general_timer.stop()
	
	if wait_timer != null: # Shenanigans to pause the wait timer when transitioning to another scene.
		wait_timer.stop()
		if wait_timer.time_left <= 0:
			wait_timer.wait_time = time_to_wait
		else:
			wait_timer.wait_time = wait_timer.time_left
		wait_timer.timeout.disconnect(_on_wait_timer_timeout)
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	
	FightManager.player_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.no_stamina_signal.disconnect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.succesful_block_signal.disconnect(start_attack_delay_timer)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): #Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_round_time()
	
#endregion

## Starts the attack delay timer using a random time.
##
## This function is called right after performing an attack and after the player or the enemy blocks.
func start_attack_delay_timer() -> void:
	general_timer.start(randf_range(min_wait_time, max_wait_time)) # Starts the timer when entering the state and sets a random wait time.

func perform_action() -> void:
	#anim_state_machine.travel(taunt_animation)
	start_attack_delay_timer()


func check_round_time() -> void: # Checks to see if the current round time matches the specified round time to change state.
	if FightManager.round_time >= target_round_time:
		condition_match(STATE_CHANGE_CONDITION.AT_ROUND_TIME)
		return
			
func _on_wait_timer_timeout() -> void:
	condition_match(STATE_CHANGE_CONDITION.AFTER_TIME_PASSED)
	return

func check_state_change_condition(signal_name : StringName) -> void:
	match signal_name:
		"enemy_knocked_down_signal":
			match STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN:
				primary_condition:
					get_parent().interrupted_state = primary_target_state
					return
				secondary_condition:
					get_parent().interrupted_state = secondary_target_state
					return
		"player_knocked_down_signal":
			condition_match(STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN)
			return
				
		"no_stamina_signal":
			condition_match(STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED)
			return
## Helper function to make this more readable.
func condition_match(condition : int) -> void:
	match condition:
		primary_condition:
			transition_to_target(primary_target_state)
			return
		secondary_condition:
			transition_to_target(secondary_target_state)
			return
			
func transition_to_target(target_state : State) -> void:
	if anim_state_machine.get_current_node() == "idle": # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		transition(self, target_state)
