@tool
@icon("res://assets/icons/PinheadPillBottleWithGreekCross.svg")
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
@export_placeholder("Don't include the library") var intro_animation : String = "heal_intro" :
	set(value):
		intro_animation = value
		if intro_animation.is_empty() == true:
			printerr(self.name, ": The given Intro Animation is empty. Having no animation will cause this state to fail and not function correctly.")
			return
		if AnimationNodeManager.match_animation_library(intro_animation, animation_player).is_empty() == true:
			printerr(self.name, ": The given Intro Animation is not an animation present in the Animation Player's Library. Having no animation will cause this state to fail and not function correctly.")
			return

## The animation that gets played when the enemy gets hit and fails healing during this state.
@export_placeholder("Don't include the library") var failed_animation : String = "heal_failed" :
	set(value):
		failed_animation = value
		if failed_animation.is_empty() == true:
			printerr(self.name, ": The given Failed Animation is empty. Having no animation will cause this state to fail and not function correctly.")
			return
		if AnimationNodeManager.match_animation_library(failed_animation, animation_player).is_empty() == true:
			printerr(self.name, ": The given Failed Animation is not an animation present in the Animation Player's Library. Having no animation will cause this state to fail and not function correctly.")
			return

## The animation played when the player doesn't stop the heal on time.
@export_placeholder("Don't include the library") var successful_animation : String = "heal_successful" :
	set(value):
		successful_animation = value
		if successful_animation.is_empty() == true:
			printerr(self.name, ": The given Successful Animation is empty. Having no animation will cause this state to fail and not function correctly.")
			return
		if AnimationNodeManager.match_animation_library(successful_animation, animation_player).is_empty() == true:
			printerr(self.name, ": The given Successful Animation is not an animation present in the Animation Player's Library. Having no animation will cause this state to fail and not function correctly.")
			return

## Stores if the [member intro_animation] or rather, any animation has started playing during this state.
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
	
	AnimationManager.force_play_animation(intro_animation, self)
	
	await animation_tree.animation_started
	animation_tree.animation_finished.connect(check_animation)
	
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = failed_animation
	
	has_started = true

func exit() -> void:
	super() # Runs the base EnemyState exit function and then runs everything below.
	
	interruption_status = false
	animation_tree.animation_finished.disconnect(check_animation)
	has_started = false

func override_conditions_and_state_parameters() -> void:
	state_type = StateTypeEnum.SIMPLE
	
	override_idle_animation = false
	
	moveset_type = MovesetTypeEnum.NOT_APPLICABLE
	
	moveset_array = []
	
	attack_timer_required = false
	
	block_behavior = BlockBehaviorEnum.NOT_APPLICABLE
	
	# Given the nature of this state, these 2 conditions MUST ALWAYS be enabled and have corresponding target states.
	primary_condition = StateChangeConditionEnum.AFTER_COMPLETION
	secondary_condition = StateChangeConditionEnum.STATE_INTERRUPTED
	
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		printerr(self.name, " does NOT have secondary target state set, but has used the primary target state as a fallback.")

func check_animation(animation_name : String) -> void:
	#print(animation_name)
	#print(intro_animation)
	match ArrayStringFormatter.remove_animation_library_preffix(animation_name):
		intro_animation:
			anim_state_machine.travel(successful_animation)
			#await animation_tree.animation_started
			return
			
		failed_animation: 
			interruption_status = true
			#anim_state_machine.start("hub_node")
			#await animation_tree.animation_started
			return
			
		successful_animation: 
			interruption_status = false
			#anim_state_machine.start("hub_node")
			#await animation_tree.animation_started
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
	if property.name == "custom_idle_animation":
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "override_idle_animation":
		property.usage |= PROPERTY_USAGE_READ_ONLY
