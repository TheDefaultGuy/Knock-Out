@tool
@icon("res://assets/icons/MaterialSymbolsDeliveryTruckSpeedRounded.svg")
class_name SequentialAttacks extends EnemyState

## A state in which the [Enemy] will perform a sequence of attacks or animations.
##
## This can be used to chain pre-existing attacks together or to make a "Flurry" attack state like
## Piston Hondo's "Hondo Rush", Mr Sandman's "Dreamland Express", or Super Macho Man's Clotheslines.[br]
##
## In this state, the [Enemy] will perform each attack in the [param moveset_array] one after the other.
## After finishing the last attack or the player being knocked out, it will transition to the next state.
## You can manually do repeated moves by adding duplicate moves in the [param moveset_array].
## This is how you can achieve something like the "Hondo Rush" or "Dreamland Express".
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

## Stores how many attacks/animations have been finished in this state.
var attack_count : int = 0

var modified_moveset : Array = []

## Variable that stores whether or not the attack animations of this state have started playing.
var started_attacking : bool = false

#region The Ready, Enter and Exit functions

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if state_machine.current_state == self:
		if started_attacking == true: # Only checks for state completion after it's started attacking.
			check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.


func enter() -> void:
	super() # Runs the base EnemyState enter function and then runs everything below.
	
	interruption_status = false
	
	started_attacking = false
	animation_tree.animation_finished.connect(increase_count)
	animation_tree.animation_started.connect(set_attacking)
	
	# Shenanigans to make sure the animation name when traveling is the same format and order
	# as the special formatted array that avoids duplicate animation nodes.
	var reversed_moveset = moveset_array.duplicate()
	reversed_moveset.reverse()
	
	modified_moveset = AnimationNodeManager.format_moveset_for_unique_names(reversed_moveset, self)
	modified_moveset.reverse()
	
	# Travels to the first attack/animation
	anim_state_machine.travel(modified_moveset[0])
	

func exit() -> void:
	super() # Runs the base EnemyState exit function and then runs everything below.
	
	# Disconnecting signals.
	animation_tree.animation_finished.disconnect(increase_count)
	animation_tree.animation_started.disconnect(set_attacking)

#endregion

## Just sets the variable when an animation has started:
func set_attacking(_animation) ->void:
	started_attacking = true 

## Increases the attack count variable by 1 every time an animation is played in this state.
func increase_count(_animation) -> void:
	# Sets this variable true so that it can start checking for state completion in the process functions
	
	attack_count += 1 # Increases the attack count index everytime an animation/attack is finished
	
	if attack_count == moveset_array.size():
		print("Attacks are over")
		return
		
	# It manually travels to each attack animation node since linking them can cause problems when the player gets knocked down.
	if attack_count >= 0 and attack_count < modified_moveset.size():
		anim_state_machine.travel(modified_moveset[attack_count])

func override_conditions_and_state_parameters() -> void:
	state_type = StateTypeEnum.CHAINED_ATTACKS
	attack_timer_required = false
	
	moveset_type = MovesetTypeEnum.PREDETERMINED_ORDER
	
	# Overrides the state change condition so that this state can function properly.
	primary_condition = StateChangeConditionEnum.AFTER_COMPLETION
	secondary_condition = StateChangeConditionEnum.AFTER_PLAYER_KNOCKED_DOWN
	moveset_type = MovesetTypeEnum.PREDETERMINED_ORDER

func _validate_property(property: Dictionary) -> void: 
	attack_timer_required = false
	super(property)
