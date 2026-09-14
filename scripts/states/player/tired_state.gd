@icon("res://assets/icons/FluentEmojiHighContrastSweatDroplets.svg")
class_name Tired extends State

@onready var input_component: InputComponent = %InputComponent
var player = self.owner
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)

	
	animation_tree.set("parameters/neutral/blend_position", 1)
	
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	defense_component.succesful_dodge.connect(succesful_dodge)
	animated_sprite_2d.material.set_shader_parameter("Visible", true)
	FightManager.player_knocked_down_signal.connect(transition_to_knocked_down)
	
func exit() -> void:
	animation_tree.set("parameters/neutral/blend_position", 0)
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	defense_component.succesful_dodge.disconnect(succesful_dodge)
	animated_sprite_2d.material.set_shader_parameter("Visible", false)
	
	FightManager.player_knocked_down_signal.disconnect(transition_to_knocked_down)
	
func perform_defense(move : int, action_name : String) -> void:
	if anim_state_machine.get_current_node() == "neutral":
		animation_tree.set("parameters/dodge/blend_position", move)
		anim_state_machine.travel("dodge")
		FightManager.player_dodged_signal.emit(move)
		if move == Global.range.NEUTRAL:
			FightManager.sfx_duck_signal.emit()
			return
		FightManager.sfx_dodge_signal.emit()
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.
		
func perform_attack(_height : int, _direction : int, _action_name : String) -> void:
	pass

func succesful_dodge() -> void:
	FightManager.set_stamina()
	animation_tree.set("parameters/neutral/blend_position", 0)
	transition_to_neutral()
	
