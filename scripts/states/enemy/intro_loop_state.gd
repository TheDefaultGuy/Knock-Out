@icon("res://assets/icons/IntroLoop.svg")
@tool

class_name LoopingCharge extends EnemyState

## In this state, the enemy will first perform an intro animation,
## and then loop another animation or a series of animations over and over until either they or the player are knocked down.
## This should be used to recreate attacks like Bald Bull's Bull Charge.[br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

@export var intro_animation : String = "loop_intro"

@export var idle_loop_animation : String = "idle_loop"

@export var restart_animation : String = "restart"

@export var attack_animation : String = "attack"

func _ready() -> void:
	check_for_attack_and_append(attack_animation)
	
	additional_animations_to_add = [ # Adds these animations to the additional_animations_to_add Array so that they can be added to the animation tree
		intro_animation,
		idle_loop_animation,
		restart_animation,
		]
	
	super() # Runs the Base EnemyState _ready() function after running this code.

func enter() -> void:
	super()
	
	current_animation_state_machine.travel(intro_animation)
	await animation_tree.animation_started
	animation_tree.animation_finished.connect(check_animation)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if state_machine.current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

func check_animation(animation_name : String) -> void:

	match remove_library_preffix(animation_name):
		intro_animation:
			current_animation_state_machine.travel(idle_loop_animation)
			return
		attack_animation:
			if Global.player_node.isKnockdown != true or Global.enemy_node.isKnockdown != true :
				current_animation_state_machine.travel(restart_animation)
				return
		restart_animation:
			current_animation_state_machine.travel(idle_loop_animation)
			return
			
## Removes the library name/preffix from the incoming animation so that it can be compared against the ones listed above.
func remove_library_preffix(animation : String) -> String:
	var number_of_preffixes = animation.count("/", 0, 0)
	print(number_of_preffixes)

	print(animation.get_slice("/",number_of_preffixes))
	return animation.get_slice("/",number_of_preffixes)

func override_conditions_and_state_parameters() -> void:

	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required  = true
	#nested_state_machine = preload("uid://bpl60rtp2gv5i")
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	
	moveset_array = [attack_animation]
	
	moveset_type = MOVESET_TYPE_ENUM.PREDETERMINED_ORDER
	
	# Given the nature of this state, these 2 conditions MUST ALWAYS be set and have a target state to transition to.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN
	secondary_condition = STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN
	
	if primary_target_state == null and secondary_target_state != null:
		primary_target_state = secondary_target_state
		push_warning(self.name, " Primary target state wasn't set, but used the secondary target state as a fallback.")
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		push_warning(self.name, " Secondary target state wasn't set, but used the primary target state as a fallback.")
		
## Sets the required conditions as Read Only so that they can't be changed.
func _validate_property(property : Dictionary) -> void:
	if property.name == "primary_condition" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "secondary_condition" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "tertiary_condition" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "block_behavior" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "counter_attack" :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_type" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "moveset_array" :
		property.usage = PROPERTY_USAGE_NONE
	super(property) # Calls the base EnemyState function right after.
