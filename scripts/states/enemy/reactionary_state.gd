@icon("res://assets/icons/TablerEyeExclamation.svg")
@tool
## This is a template state used by enemy boxers.
## In this state, the enemy will react to the player's actions.
## The enemy can dodge if the player throws a punch, throw a fake out punch and then punish if the player dodged.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name Reactionary extends EnemyState

#region Exported Variables and function that handles which variables to show

## The fakeout animation that will play in this state.
@export var fakeout_animation : String = "fakeout"



#region The Ready, Enter and Exit functions.

func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = true
	nested_state_machine = preload("uid://c1biuhgyv30i1")
	nested_machine_name = str(self.name).to_snake_case() 

	block_behavior = BLOCK_BEHAVIOR_ENUM.RESET_TIMER
	

	
func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	anim_state_machine.travel(nested_machine_name)
	
	current_animation_state_machine = animation_tree[str("parameters/",str(nested_machine_name),"/playback")]
	current_animation_state_machine.travel("Start")
	start_attack_delay_timer()

	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	FightManager.player_threw_punch_signal.connect(play_dodge_animation)
	FightManager.player_dodged_signal.connect(play_punish_animation)

	toggle_important_state_signal_connections()
	
	FightManager.succesful_block_signal.connect(start_attack_delay_timer)

	attack_timer.timeout.connect(perform_action)
	# Sets the block animation and state machine in the defense component as the block animation in the state machine.
	# This is because the defense component is the one responsible for playing the block animation
	defense_component.current_block_animation = "dodge"
	defense_component.current_anim_state_machine = current_animation_state_machine

	
func exit() -> void:
	toggle_important_state_signal_connections()
	
	FightManager.succesful_block_signal.disconnect(start_attack_delay_timer)
	
	defense_component.reset_current_animations()
	attack_timer.timeout.disconnect(perform_action)
	FightManager.player_threw_punch_signal.disconnect(play_dodge_animation)
	FightManager.player_dodged_signal.disconnect(play_punish_animation)

	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): #Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_round_time()
		check_player_stamina()
		check_time_has_passed()
		check_enemy_health()
		check_for_knockdowns()
		print("REACTIONARY: ", current_animation_state_machine.get_current_node())
		#print("fakeout timer: ", fakeout_timer.time_left)
#endregion

func play_dodge_animation(height : int, direction : int) -> void:
	animation_tree.set(str("parameters/",str(nested_machine_name),"/dodge/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/stun_hit/blend_position"), Vector2i(direction, height))
	animation_tree.set(str("parameters/",str(nested_machine_name),"/final_hit/blend_position"), Vector2i(direction, height))
	
func play_punish_animation(dodge_direction : int) -> void:
	if animation_tree[str("parameters/",str(nested_machine_name),"/playback")].get_current_node() == "fakeout":
		animation_tree.set(str("parameters/",str(nested_machine_name),"/punish/blend_position"), dodge_direction)
		animation_tree[str("parameters/",str(nested_machine_name),"/playback")].travel("punish")


func perform_action() -> void:
	var moves = ["fakeout", "attack"]
	current_animation_state_machine.travel(moves.pick_random())
	await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
	start_attack_delay_timer()
	return
