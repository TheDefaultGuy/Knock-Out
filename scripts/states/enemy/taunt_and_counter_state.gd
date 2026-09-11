@icon("res://assets/icons/AtIconsComedyMask.svg")
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
class_name TauntAndCounter extends EnemyState


#region The Ready, Enter and Exit functions.
	
func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required = true
	nested_state_machine = preload("uid://bk1eoynjjkrt")
	nested_machine_name = str(self.name).to_snake_case() 

	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED
	
func _enter_tree() -> void:
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED
	
func _validate_property(property: Dictionary) -> void: 
	#moveset_type = MOVESET_TYPE_ENUM.PREDETERMINED_ORDER
	#attack_timer_required = true
	#moveset_array = ["taunt"]
	update_shown_exported_variables(property)
	#if primary_condition != STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED:
		#printerr(self.name, ' the primary condition MUST be set to "After Player Tired" due to the nature of this state.')

func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	anim_state_machine.travel(nested_machine_name)
	
	current_animation_state_machine = animation_tree[str("parameters/",nested_machine_name,"/playback")]

	start_attack_delay_timer()
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	# Connects the enemy knocked down, player knocked down and stun signals.
	toggle_important_state_signal_connections()
	
	FightManager.succesful_block_signal.connect(start_attack_delay_timer)

	# Toggles on the state change timer.
	toggle_state_change_timer()

	attack_timer.timeout.connect(perform_action)
	
	# Sets the block animation and state machine in the defense component as the block animation in the state machine.
	# This is because the defense component is the one responsible for playing the block animation
	defense_component.current_anim_state_machine = current_animation_state_machine
	FightManager.player_threw_punch_signal.connect(set_blends)
	
func set_blends(height : int, direction : int) -> void:
	animation_tree.set(str("parameters/",str(nested_machine_name),"/hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/block/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/final_hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/stun_hit/blend_position"), Vector2i(direction, height))
	
func exit() -> void:
	
	attack_timer.timeout.disconnect(perform_action)
		
	toggle_important_state_signal_connections()
	
	FightManager.succesful_block_signal.disconnect(start_attack_delay_timer)

	defense_component.reset_current_animations()
	
	FightManager.player_threw_punch_signal.disconnect(set_blends)

	
	## Performs an action, animation or attack after the attack timer has finished.
func perform_action() -> void:
	current_animation_state_machine.travel("taunt")
	await animation_tree.animation_finished # Resets the attack delay timer after attacking
	start_attack_delay_timer()
	return

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): #Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_round_time()
		check_player_stamina()
		check_time_has_passed()
		check_enemy_health()
	#print("Nested current node: ", animation_tree[str("parameters/",nested_machine_name,"/playback")].get_current_node())
#endregion
