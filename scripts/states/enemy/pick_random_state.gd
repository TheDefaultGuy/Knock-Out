@icon("res://assets/icons/MdiDice.svg")
@tool
class_name PickRandomState extends EnemyState


## Pseudo-state where it randomly choose one of the three states.
##
## This isn't a real state where the enemy attacks.
## As soon as the enemy enters this "state", it picks a random one,
## and then transitions immeadiately to the chosen state.


## Stores the possible states and then one gets picked at random.
var state_array : Array[State] = []

func override_conditions_and_state_parameters() -> void:
	
	moveset_type = MOVESET_TYPE_ENUM.NOT_APPLICABLE
	attack_timer_required = false
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	secondary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	tertiary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	
func enter() -> void:
	state_array = []
	if primary_target_state != null:
		state_array.append(primary_target_state)
	if secondary_target_state != null:
		state_array.append(secondary_target_state)
	if tertiary_target_state != null:
		state_array.append(tertiary_target_state)
	if state_array != []:
		transition_to_target(state_array.pick_random())
		return
	elif state_array.size() == 0:
		printerr(self.name, " no target states set. There needs to be at least 2 target states for this State to function properly as intended.")
		transition_to_previous_state()
		return
	elif state_array.size() == 1:
		printerr(self.name, " only one target state set. There needs to be at least 2 target states for this State to function properly as intended.")
		transition_to_target(state_array[0])
		return
	
## Sets the required conditions as Read Only so that they can't be changed.
func _validate_property(property : Dictionary) -> void:
	if property.name == "primary_target_state" :
		property.usage |= PROPERTY_USAGE_DEFAULT
	if property.name == "secondary_target_state" :
		property.usage |= PROPERTY_USAGE_DEFAULT
	if property.name == "tertiary_target_state" :
		property.usage |= PROPERTY_USAGE_DEFAULT
		
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
