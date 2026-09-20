@icon("res://assets/icons/TablerEyeExclamation.svg")
@tool
class_name Reactionary extends EnemyState

## In this state, the enemy will react to the player's actions.
## 
## The enemy can dodge if the player throws a punch, throw a fake out punch and then punish if the player dodged.[br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

## The fakeout animation that will play in this state.
@export var fakeout_animation: String = "fakeout"

@export var left_dodge_punish: String = "punish_left"
@export var right_dodge_punish: String = "punish_right"
@export var duck_punish: String = "punish_duck"

func _ready() -> void:
	
	check_for_attack_and_append(fakeout_animation)
	
	additional_animations_to_add = [ # Adds these animations to the additional_animations_to_add Array so that they can be added to the animation tree
		left_dodge_punish,
		right_dodge_punish,
		duck_punish,
		]
	super()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if state_machine.current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

func enter() -> void: 
	super() # Runs the base EnemyState enter function and then runs everything below.
	
	# Plays the punish animation when the player dodges.
	FightManager.player_dodged_signal.connect(play_punish_animation)
	
	# Sets the block animation and state machine in the defense component as the block animation in the state machine.
	# This is because the defense component is the one responsible for playing the block animation
	defense_component.current_block_animation = "dodge"

func exit() -> void:
	
	super()  # Runs the base EnemyState exit function and then runs everything below.

	FightManager.player_dodged_signal.disconnect(play_punish_animation)

func play_punish_animation(dodge_direction : int) -> void:
	if anim_state_machine.get_current_node() == str(fakeout_animation) :
		match dodge_direction :
			Global.range.LEFT:
				anim_state_machine.travel(left_dodge_punish)
				return
				
			Global.range.RIGHT:
				anim_state_machine.travel(right_dodge_punish)
				return
				
			Global.range.NEUTRAL:
				anim_state_machine.travel(duck_punish)
				return

func override_conditions_and_state_parameters() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required  = true
	
	moveset_type = MOVESET_TYPE_ENUM.PICK_RANDOM
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.COUNTER_ATTACK
	

## Sets the required conditions as Read Only so that they can't be changed.
func _validate_property(property : Dictionary) -> void:
	if property.name == "block_behavior" :
		property.usage |= PROPERTY_USAGE_READ_ONLY

	super(property) # Calls the base EnemyState function right after.
