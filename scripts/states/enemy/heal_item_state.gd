@icon("res://assets/icons/PinheadPillBottleWithGreekCross.svg")
@tool

class_name ItemHeal extends EnemyState

## A state in which the enemy will attempt to heal with an item,
## similar to Doc Louis with his chocolate and Soda Popinski with his "Soda".
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.[br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.

## The animation that plays when entering the state for the first time.
@export var intro_animation : String = "heal_intro"

## The animation that gets played when the enemy gets hit and fails healing during this state.
@export var failed_animation : String = "heal_failed"

## The animation played when the player doesn't stop the heal on time.
@export var successful_animation : String = "heal_successful"

var has_started : bool = false


func _ready() -> void:
	# Adds these animations to the additional_animations_to_add Array so that they can be added to the animation tree
	additional_animations_to_add = [
		intro_animation,
		failed_animation,
		successful_animation,
		]
	
	super() # Runs the Base EnemyState _ready() function after running this code.

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if state_machine.current_state == self:
		if has_started == true :
			check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.
		return

func enter() -> void:
	
	has_started = false
	super() # Runs the base EnemyState enter function and then runs everything below.
	
	owner.animation_component.play_animation(intro_animation)
	
	await animation_tree.animation_started
	animation_tree.animation_finished.connect(check_animation)
	
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = failed_animation
	
	has_started = true

func exit() -> void:
	super() # Runs the base EnemyState exit function and then runs everything below.
	
	#FightManager.succesful_hit_signal.disconnect(change_to_failed_state)
	interruption_status = false
	animation_tree.animation_finished.disconnect(check_animation)
	has_started = false

func override_conditions_and_state_parameters() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	
	moveset_type = MOVESET_TYPE_ENUM.NOT_APPLICABLE
	
	moveset_array = []
	
	attack_timer_required = false
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	
	# Given the nature of this state, these 2 conditions MUST ALWAYS be enabled and have corresponding target states.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	secondary_condition = STATE_CHANGE_CONDITION.STATE_INTERRUPTED
	
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		printerr(self.name, " does NOT have secondary target state set, but has used the primary target state as a fallback.")

func check_animation(animation_name : String) -> void:
	print(animation_name)
	print(intro_animation)
	match remove_library_preffix(animation_name):
		intro_animation:
			print("AWSWEIJHAOI")
			anim_state_machine.travel(successful_animation)
			await animation_tree.animation_started
			return
			
		failed_animation: 
			interruption_status = true
			#anim_state_machine.start("hub_node")
			await animation_tree.animation_started
			return
			
		successful_animation: 
			interruption_status = false
			#anim_state_machine.start("hub_node")
			await animation_tree.animation_started
			return

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
	if property.name == "moveset_type" :
		property.usage |= PROPERTY_USAGE_READ_ONLY
	super(property) # Calls the base EnemyState function right after.
