class_name NeutralPlayerState extends State

@onready var input_component: InputComponent = %InputComponent
@onready var anim_state_machine = animation_tree["parameters/playback"]

func enter():
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	set_process(false)
	input_component.allow_inputs = true
	animation_tree.set("parameters/neutral/blend_position", 0)
	animation_tree.set("parameters/conditions/spectating", false)

	
	## Sets the interrupted state in the state machine as itself.
	## That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	#get_parent().interrupted_state = self 
	
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	FightManager.no_stamina_signal.connect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.connect(transition_to_spectating)
	
func exit():
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	FightManager.no_stamina_signal.disconnect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_spectating)
	
func perform_defense(move : int, action_name : String):
	if get_parent().get_parent().isKnockdown == true:
		return
	elif get_parent().get_parent().isDodging == true && get_parent().get_parent().isHit == false:
		pass
	elif get_parent().get_parent().isDodging == false && get_parent().get_parent().isAttacking == false && get_parent().get_parent().isHit == false:
		#print("hit status: ", get_parent().get_parent().isHit)
				animation_tree.set("parameters/dodge/blend_position", move)
				anim_state_machine.travel("dodge")
				if move == Global.range.NEUTRAL:
					FightManager.sfx_duck_signal.emit()
					return
				FightManager.sfx_dodge_signal.emit()
					
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.
	
func perform_attack(height : int, direction : int, action_name : String, special_move : bool):
	if get_parent().get_parent().isKnockdown == true:
		return
	if get_parent().get_parent().isDodging == false && get_parent().get_parent().isAttacking == false && get_parent().get_parent().isHit == false: # Checks to see if the player isn't currently dodging.
		if special_move == false:
			animation_tree.set("parameters/attack/blend_position", Vector2i(direction, height))
			anim_state_machine.travel("attack")
			FightManager.sfx_punch_thrown_signal.emit()

		elif special_move == true:
			if FightManager.star_count > 0: # Checks to see if the player has stars to perform a star punch.
				FightManager.use_stars()
				animation_tree.set("parameters/star_punch/blend_position", Vector2i(direction, height))
				anim_state_machine.travel("star_punch")
				FightManager.sfx_star_punch_thrown_signal.emit()

	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.
		
