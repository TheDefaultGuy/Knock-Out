@icon("res://assets/icons/FluentEmojiHighContrastSweatDroplets.svg")
class_name TiredState extends State

## The tired state where the [Player] can only dodge and cannot attack.
## 
## Since this is a state exclusive to the [Player], NONE of the variables, code, etc... can be changed.
## Everything MUST be kept as is.
## Eventually, once the code for the [Player] is cleaned up, the option to add custom players might be added.

@onready var input_component: InputComponent = %InputComponent
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	
	animation_tree.set("parameters/neutral/blend_position", 1)
	
	input_component.defense_input_signal.connect(perform_defense)
	defense_component.succesful_dodge.connect(succesful_dodge)
	
	animated_sprite_2d.material.set_shader_parameter("Visible", true)
	
	FightManager.player_knocked_down_signal.connect(transition_to_knocked_down)

func exit() -> void:
	animation_tree.set("parameters/neutral/blend_position", 0)
	
	input_component.defense_input_signal.disconnect(perform_defense)
	defense_component.succesful_dodge.disconnect(succesful_dodge)
	
	animated_sprite_2d.material.set_shader_parameter("Visible", false)
	
	FightManager.player_knocked_down_signal.disconnect(transition_to_knocked_down)

## Performs the appropriate defense animation when the [InputComponent] sends the [signal InputComponent.defense_input_signal].
func perform_defense(move : int, action_name : String) -> void:
	
	# If the player is in the "neutral" animation, when it's safe to dodge, then play the dodge animation.
	if anim_state_machine.get_current_node() == "neutral" : 
		
		# Sets the dodge blend position/dodge direction based on the given move value given by the input component.
		animation_tree.set("parameters/dodge/blend_position", move)
		
		# Plays the actual dodge animation
		anim_state_machine.start("dodge")
		
		# Emits the signal
		FightManager.player_dodged_signal.emit(move)
		
		if move == Global.range.NEUTRAL: # Checks if it was a duck instead of a Left or Right Dodge
			
			# Emits the signal for the duck sound effect.
			FightManager.play_sfx_signal.emit("duck") 
			return
			
		# Emits the signal for the dodge sound effect.
		FightManager.play_sfx_signal.emit("dodge")
		return
		
	# If the player is currently already dodging, attacking or hit, it'll store the attack they wanted to do so that it's buffered.
	input_component.store_unhandled_input(action_name) 

## Runs after the successful_dodge_signal was emitted.
func succesful_dodge() -> void:
	FightManager.set_stamina()
	transition_to_neutral()
