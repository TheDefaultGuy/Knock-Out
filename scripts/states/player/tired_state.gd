@icon("res://assets/icons/FluentEmojiHighContrastSweatDroplets.svg")
class_name TiredState extends State

@onready var input_component: InputComponent = %InputComponent
@onready var anim_state_machine = animation_tree["parameters/playback"]

func enter():
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	set_process(false)
	
	animation_tree.set("parameters/neutral/blend_position", 1)
	
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	defense_component.succesful_dodge.connect(succesful_dodge)

func exit():
	animation_tree.set("parameters/neutral/blend_position", 0)
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	defense_component.succesful_dodge.disconnect(succesful_dodge)
	
func perform_defense(move : int, action_name : String):
	if get_parent().get_parent().isKnockdown == true:
		return
	elif get_parent().get_parent().isDodging == false && get_parent().get_parent().isAttacking == false && get_parent().get_parent().isHit == false:
		animation_tree.set("parameters/dodge/blend_position", move)
		anim_state_machine.travel("dodge")
		if move == Global.range.NEUTRAL:
			FightManager.sfx_duck_signal.emit()
			return
		FightManager.sfx_dodge_signal.emit()
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.
		
func perform_attack(_height : int, _direction : int, _action_name : String, _special : bool):
	pass

func succesful_dodge():
	FightManager.set_stamina()
	transition_to_previous_state()
	
	
func _process(_delta: float) -> void:
	pass
