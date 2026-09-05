@icon("res://assets/icons/BoxiconsMehBlank.svg")

class_name PlayerNeutral extends State

@onready var input_component: InputComponent = %InputComponent
@onready var player = self.owner
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)

	input_component.allow_inputs = true
	animation_tree.set("parameters/neutral/blend_position", 0)
	animation_tree.set("parameters/conditions/spectating", false)

	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	FightManager.no_stamina_signal.connect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.connect(transition_to_spectating)

	
func exit() -> void:
	input_component.attack_input_signal.disconnect(perform_attack)
	input_component.defense_input_signal.disconnect(perform_defense)
	FightManager.no_stamina_signal.disconnect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_spectating)

## Performs the appropriate defense animation when the input component sends the signal.
func perform_defense(move : int, action_name : String) -> void:
	if anim_state_machine.get_current_node() == "neutral":
				animation_tree.set("parameters/dodge/blend_position", move)
				anim_state_machine.travel("dodge")
				if move == Global.range.NEUTRAL:
					FightManager.sfx_duck_signal.emit()
					return
				FightManager.sfx_dodge_signal.emit()
				return
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.

## Performs the appropriate attack animation when the input component sends the signal.
func perform_attack(height : int, direction : int, action_name : String, special_move : bool) -> void:
	if anim_state_machine.get_current_node() == "neutral": # Checks to see if the player isn't currently dodging.
		if special_move == false:
			animation_tree.set("parameters/attack/blend_position", Vector2i(direction, height))
			anim_state_machine.travel("attack")
			FightManager.sfx_punch_thrown_signal.emit()
			return
		elif special_move == true:
			if FightManager.star_count > 0: # Checks to see if the player has stars to perform a star punch.
				FightManager.use_stars()
				animation_tree.set("parameters/star_punch/blend_position", height)
				anim_state_machine.travel("star_punch")
				FightManager.sfx_star_punch_thrown_signal.emit()
				return
	else:
		input_component.store_unhandled_input(action_name) # If the player is currently already dodging or attacking, it'll store the attack they wanted to do so that it's buffered.	

func _process(_delta: float) -> void:
	if get_parent().current_state == self:
		if anim_state_machine.get_current_node() == "hit":
			animated_sprite_2d.material.set_shader_parameter("Visible", true)
			return
		animated_sprite_2d.material.set_shader_parameter("Visible", false)
