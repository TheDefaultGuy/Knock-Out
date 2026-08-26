@icon("res://assets/icons/FluentEmojiHighContrastSweatDroplets.svg")
class_name TiredState extends State

@onready var input_component: InputComponent = %InputComponent
@onready var anim_state_machine = animation_tree["parameters/playback"]

func enter():
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	set_process(false)
	
	animation_tree.set("parameters/conditions/tired", true)
	
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	defense_component.succesful_dodge.connect(succesful_dodge)

func exit():
	animation_tree.set("parameters/conditions/tired", false)
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	defense_component.succesful_dodge.disconnect(succesful_dodge)
	
func perform_defense(move : int, action_name : String):
	if get_parent().get_parent().isKnockdown == true:
		return
	elif get_parent().get_parent().isDodging == false && get_parent().get_parent().isAttacking == false && get_parent().get_parent().isHit == false:
		match move:
			Global.range.LEFT:
				anim_state_machine.travel("dodge_left_start")
				FightManager.sfx_dodge_signal.emit()
			Global.range.RIGHT:
				anim_state_machine.travel("dodge_right_start")
				FightManager.sfx_dodge_signal.emit()
			Global.range.NEUTRAL:
				anim_state_machine.travel("dodge_duck_start")
				FightManager.sfx_duck_signal.emit()
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.
		
func perform_attack(_height : int, _direction : int, _action_name : String, _special : bool):
	pass

func succesful_dodge():
	FightManager.set_stamina()
	transition_to_previous_state()
	
	
func _process(_delta: float) -> void:
	pass
