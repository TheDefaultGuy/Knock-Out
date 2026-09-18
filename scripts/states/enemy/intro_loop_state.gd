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

func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = true
	nested_state_machine = preload("uid://bpl60rtp2gv5i")
	moveset_array = ["attack"]
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
		

	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self or get_parent().current_state is EnemySpectating:
		animation_tree.set(str("parameters/",nested_machine_name,"/conditions/ko"), Global.player_node.isKnockdown or Global.enemy_node.isKnockdown)
	if get_parent().current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.
