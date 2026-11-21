@icon("res://assets/icons/BoxiconsMehBlank.svg")

class_name PlayerNeutral extends State
## The neutral/default player state where the [Player] can attack, dodge, block and duck normally.
## 
## Since this is a state exclusive to the [Player], NONE of the variables, code, etc... can be changed.
## Everything MUST be kept as is.
## Eventually, once the code for the [Player] is cleaned up, the option to add custom playes might be added.


@onready var input_component: InputComponent = %InputComponent

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

## How much time in seconds dows it take for the [member repeated_punch_count] to return back to 0.
const FATIGUE_RECOVERY_TIME : float = 3.0

## Stores how many pucnhes the player has done with the same arm.
var repeated_punch_count : int = 0

## Timer that sets the [member repeated_punch_count] to 0 once it finishes.
var fatigue_timer : Timer = null

@export var fatigue_curve : Curve

var last_punch_direction : int = 0

func _ready() -> void:
	fatigue_timer = TimerCreator.create_timer_and_add_as_child("Fatigue Timer", true, FATIGUE_RECOVERY_TIME, false, self)
	fatigue_timer.timeout.connect(_on_fatigue_timer_timeout)

func enter() -> void:
	print_rich("[color=yellow][b]Player Entered State: [/b][/color]", self.name)
	
	input_component.allow_inputs = true
	
	animation_tree.set("parameters/neutral/blend_position", 0)
	
	animation_tree.animation_started.connect(check_started_animation)
	animation_tree.animation_finished.connect(check_finished_animation)
	
	input_component.attack_input_signal.connect(perform_attack)
	input_component.defense_input_signal.connect(perform_defense)
	
	FightManager.no_stamina_signal.connect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.connect(transition_to_spectating)
	FightManager.player_knocked_down_signal.connect(transition_to_knocked_down)
	

func exit() -> void:
	animation_tree.animation_started.disconnect(check_started_animation)
	animation_tree.animation_finished.disconnect(check_finished_animation)
	
	input_component.defense_input_signal.disconnect(perform_defense)
	input_component.attack_input_signal.disconnect(perform_attack)
	FightManager.no_stamina_signal.disconnect(transition_to_tired)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.player_knocked_down_signal.disconnect(transition_to_knocked_down)

## Sets the tired shader when the player gets hit.
func check_started_animation(animation : String) -> void:
	if animation.contains("hit") == true:
		animated_sprite_2d.material.set_shader_parameter("Visible", true)

## Removes the tired shader when the player is no longer hit.
func check_finished_animation(animation : String) -> void:
	if animation.contains("hit") == true:
		animated_sprite_2d.material.set_shader_parameter("Visible", false)

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
		
		if move == Global.RangeEnum.NEUTRAL: # Checks if it was a duck instead of a Left or Right Dodge
			
			# Emits the signal for the duck sound effect.
			FightManager.play_sfx_signal.emit("duck") 
			return
			
		# Emits the signal for the dodge sound effect.
		FightManager.play_sfx_signal.emit("dodge")
		return
		
	# If the player is currently already dodging, attacking or hit, it'll store the attack they wanted to do so that it's buffered.
	input_component.store_unhandled_input(action_name) 

## Performs the appropriate attack animation when the [InputComponent] sends the [signal InputComponent.attack_input_signal].
func perform_attack(height : int, direction : int, action_name : String) -> void:
	
	# If the player is in the "neutral" animation, when it's safe to dodge, then play the attack animation.
	if anim_state_machine.get_current_node() == "neutral":
		
		# Checks if the attack is actually a star punch.
		if action_name.contains("star") == true:
			
			if FightManager.star_count > 0: # Checks to see if the player has stars to perform a star punch.
				FightManager.use_stars() # If the player has stars, use them.
				
				# Sets the blend for the star punch animation based on the punch's height.
				animation_tree.set("parameters/star_punch/blend_position", height)
				
				# Plays the actual star punch animation.
				anim_state_machine.travel("star_punch")
				
				# Emits the signal for the sound effect.
				FightManager.play_sfx_signal.emit("star_punch")
				return
		else:
			
			handle_punch_fatigue(direction)
			
			# Sets the blend for the attack animation based on the punch's direction and height.
			animation_tree.set("parameters/attack/blend_position", Vector2i(direction, height))
			
			# Plays the actual attack animation
			anim_state_machine.travel("attack")
			
			return
		
	# If the player is currently already dodging, attacking or hit, it'll store the attack they wanted to do so that it's buffered.
	input_component.store_unhandled_input(action_name)

##  Handles the logic for punches done with the same arm/direction.
func handle_punch_fatigue(direction : int) -> void:
	
	fatigue_timer.start()
	
	# Sets the last punch direction if it hasn't been set.
	if last_punch_direction == Global.RangeEnum.NEUTRAL:
		last_punch_direction = direction
		attacking_component.attack_multiplier = 1.0
		return
		
	# If the attack is the same side as the last punch direction, then increase the repeated punch count.
	if last_punch_direction == direction:
		repeated_punch_count += 1
		
		# Sets the attacking component's attack multiplier based on the curve.
		# This lowers attack damage.
		attacking_component.attack_multiplier = fatigue_curve.sample(repeated_punch_count)
		return
		
	elif last_punch_direction != direction:
		
		# Sets the last punch direction as the new direction.
		last_punch_direction = direction
		
		# If the player is alternating arms, then set the attack multiplier to 1.0.
		if repeated_punch_count == 0 :
			attacking_component.attack_multiplier = 1.0
			return
		
		# Sets the attacking component's attack multiplier based on the INVERSE curve.
		# This INCREASES attack damage, but only once, as repeated_punch_count is set back to 0 right after.
		attacking_component.attack_multiplier = 1 / fatigue_curve.sample(repeated_punch_count)
		repeated_punch_count = 0
		return

func _on_fatigue_timer_timeout() -> void:
	repeated_punch_count = 0
	print("Neutral State: Recovered from punch fatigue")
