@icon("res://assets/icons/EmojioneMonotoneDizzy.svg")
@tool
## This is the state in which the enemy is stunned and can't fight back.
##
## It is a required state for all enemies.
##
## The stun behavior is customizable.
## FIXED TIMER DURATION: after a given amount of time,
## The enemy will automatically leave the stun state, regardless of how many punches the player lands.
## FIXED NUMBER OF PUNCHES: which means that stun will allow the player to land a given number of punches guaranteed.
## If the player stops attacking for some reason, it'll leave the stun state after the given stun duration has elapsed.
## INCREASING_NUMBER_OF_PUNCHES : Instead of a fixed number of punches, it'll only allow a small number of punches at first,
## but every time the enemy enters the stun state, the amount of punches they'll allow will increase by one, until they reach the max desired cap.
## Basically, the more the enemy enters stun state during the match, the longer the stun will be.
## Resets after a new round.
class_name StunState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

#region Exported Variables and function that handles which variables to show.
## How stun will work/behave for the fighter.
enum BEHAVIOR_TYPE{
	## Stun will last a given amount of time.
	## After time is up, they will automatically switch state.
	FIXED_TIME_DURATION,
	## Stun will last for a fixed given number of punches, or after the given time has passed.
	## Every time a punch lands the timer for the stun duration will restart.
	FIXED_NUMBER_OF_PUNCHES,
	## Stun will last for a given number of punches,
	## but will increase by 1 for each time the enemy enters stun state.
	## The more the enemy enters stun, the longer stun will be for the rest of the match.
	## That, or after the given time has passed.
	## Every time a punch lands the timer for the stun duration will restart.
	INCREASING_NUMBER_OF_PUNCHES
}

var stun_timer : Timer = null

@export_category("💫 Stun Behavior")
@export var stun_behavior := BEHAVIOR_TYPE.FIXED_TIME_DURATION: 
	set(value):
		stun_behavior = value
		notify_property_list_changed()

## This variable works slightly differently depending on what behavior is selected:
##
## FIXED_TIME_DURATION: How long stun lasts for in seconds before automatically changing to next state
## regardless of how many punches the player has landed.
## FIXED_NUMBER_OF_PUNCHES and INCREASING_NUMBER_OF_PUNCHES: How long does the player have to NOT punch for the enemy to recover automatically.
@export_range(0.5, 3.0, 0.25, "suffix:s") var stun_duration : float = 2.0 
## The minimum amount of punches that stun will last for.
@export_custom(PROPERTY_HINT_NONE, "suffix:punches") var min_stun_length : int = 2
## The maximum amount of punches that stun will last for.
@export_custom(PROPERTY_HINT_NONE, "suffix:punches") var max_stun_length : int = 15
## The fixed amount of punches that stun will last for.
@export_custom(PROPERTY_HINT_NONE, "suffix:punches") var fixed_stun_length : int = 5

@export_category("🍾 Heal After Recovering?")
## Whether the enemy transitions to a healing state after stun is over 
@export var heal_after_stun : bool = false
## The amount of time the enemy waits (in seconds) before changing to the target state.
@export_range(5.0, 100.0, 1.0, "suffix:hp") var target_health : float = 80.0

## The state in which the enemy attempts to heal.
@export var heal_state : ItemHealState 

var target_state : State

## How many punches the player has landed during this state.
var punch_count: int = 0
## How many punches the player can land before the enemy changes state.
var stun_punch_length: int = 0

var stun_over : bool = false

## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "fixed_stun_length" and stun_behavior != BEHAVIOR_TYPE.FIXED_NUMBER_OF_PUNCHES:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "max_stun_length" and stun_behavior != BEHAVIOR_TYPE.INCREASING_NUMBER_OF_PUNCHES:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_stun_length" and stun_behavior != BEHAVIOR_TYPE.INCREASING_NUMBER_OF_PUNCHES:
		property.usage = PROPERTY_USAGE_NONE
#endregion
		
#region Ready, Enter, Exit, and Process functions.
func _ready() -> void:
	create_timers()
	# Sets the stun punch length based on the desired behavior.
	match stun_behavior:
		BEHAVIOR_TYPE.FIXED_NUMBER_OF_PUNCHES:
			stun_punch_length = fixed_stun_length
		BEHAVIOR_TYPE.INCREASING_NUMBER_OF_PUNCHES:
			stun_punch_length = clamp(min_stun_length - 1, 0, max_stun_length)# minus 1 because the enter functions adds 1.
		

## Creates the timers with code so that you don't have to make timer node and then manually assign it.
func create_timers() -> void:
	stun_timer = Timer.new()
	stun_timer.name = "Stunned Timer"
	get_parent().get_parent().add_child.call_deferred(stun_timer)


func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", false)
	animation_tree.set("parameters/idle/blend_position", 1)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	FightManager.succesful_hit_signal.connect(increase_punch_count)
	stun_timer.timeout.connect(stun_timer_over)
	# Resets punch count everytime the enemy enters stun.
	punch_count = 0
	stun_over = true
	target_state = get_parent().interrupted_state
	
	match stun_behavior:
		BEHAVIOR_TYPE.FIXED_TIME_DURATION:
			stun_timer.start(stun_duration)
			
			# Increases the length of the stun in terms of pucnhes eeverytime the enemy enters stun state.
		BEHAVIOR_TYPE.INCREASING_NUMBER_OF_PUNCHES:
			stun_punch_length = clamp(stun_punch_length + 1, min_stun_length, max_stun_length)

func exit() -> void:
	animation_tree.set("parameters/idle/blend_position", 0)
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	FightManager.succesful_hit_signal.disconnect(increase_punch_count)
	stun_timer.timeout.disconnect(stun_timer_over)
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state != self:
		return
	check_health_condition()
	if anim_state_machine.get_current_node() == "idle" and stun_over == true: # Checks to see if the enemy is idle so that it doesn't interrupt a hit, block, or any other animation.
		animation_tree.set("parameters/conditions/recovered", true)
		transition(self, target_state)
#endregion

## Increases the punch count by one everytime the player lands a punch during stun.
func increase_punch_count() -> void:
	if stun_behavior == BEHAVIOR_TYPE.FIXED_NUMBER_OF_PUNCHES or stun_behavior == BEHAVIOR_TYPE.INCREASING_NUMBER_OF_PUNCHES:
		stun_timer.start(stun_duration)
		punch_count = punch_count + 1
		if punch_count >= stun_punch_length:
			transition(self, target_state)

func stun_timer_over() -> void:
	stun_over = true
	

func reset_stun_length() -> void:
	pass
	
## Checks the enemy's own HP and transitions to heal state once it reaches it.
func check_health_condition() -> void:
	if health_component.hp <= target_health and heal_after_stun == true:
		target_state = heal_state
