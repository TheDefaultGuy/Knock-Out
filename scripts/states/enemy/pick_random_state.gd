@icon("res://assets/icons/MdiDice.svg")
@tool
## This isn't a real state where the enemy attacks.
## Its just a pseudo-state you can choose to randomly choose one of the three states.
class_name PickRandomState extends EnemyState

## Stores the possible states and then one gets picked at random.
var state_array : Array[State] = []

func _init() -> void:
	moveset_dictionary = {"" : 0.0}
	primary_condition = STATE_CHANGE_CONDITION.DO_NOT_CHANGE
	secondary_condition = STATE_CHANGE_CONDITION.DO_NOT_CHANGE
	tertiary_condition = STATE_CHANGE_CONDITION.DO_NOT_CHANGE
	
	
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
		
### Handles showing and hiding applicable exported variables
#func _validate_property(property: Dictionary) -> void:
	#if property.name not in ["primary_target_state", "secondary_target_state", "tertiary_target_state"]:
		#property.usage = PROPERTY_USAGE_NO_EDITOR
	#if property.name in ["primary_target_state", "secondary_target_state", "tertiary_target_state"]:
		#property.usage = PROPERTY_USAGE_DEFAULT
