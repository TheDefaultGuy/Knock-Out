@icon("res://assets/icons/MdiSwordCross.svg")

class_name AttackingComponent extends Node

## This component is responsible for performing the attacks.
##
## It's used by the attack animations in the Move Set Animation Player and iteracts with the [DefenseComponent].
## Basically, they talk with each other. The attack component gives the [DefenseComponent] all of the data of the attack.
## The range it covers, the height it covers, the amount of damage and the punch direction.
## The defense then checks against the defense variables it has and returns whether or not the attack landed.


## Multiplier for the attack's damage. mainly used by the player.
@export_custom(PROPERTY_HINT_NONE, "suffix:x") var attack_multiplier : float = 1.0 

## Curve used to extrapolate the damage bonus over time after a parry has been performed.
@export var parry_damage_curve : Curve

## How long the parry attack bonus lasts for in seconds.
## This is used for the input of the parry_damage_curve.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var parry_bonus_duration : float = 2.0

## How long the attack flash lasts for in seconds.
var enemy_flash_duration : float = 0.25

## The timer used to determine if a block is a regular block or a parry.
var parry_attack_timer : Timer = null

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	create_parry_timer()
	defense_component.player_parried_signal.connect(parry_damage_bonus)

func _process(_delta: float) -> void:
	if parry_attack_timer.is_stopped() == false and owner is Player:
		attack_multiplier = parry_damage_curve.sample(1 - (parry_attack_timer.time_left / parry_attack_timer.wait_time))

## Function that called by the attack animations
##
## It calls functions in the opposing fighter's defense component, giving it the attacks variables as input.
## Which the attack covers, the dodge range, how much damage it does, etc...
## The defense compomnent then checks if the attack is successful and returns the result.] to the attack component.
func send_attack_call(punch_height : int, punch_range : int, attack_damage : float, punch_direction : int):
	if Global.enemy_node == null or Global.player_node == null:
		printerr("Attacking Component: No enemy node or no player node assigned in global.")
		return false
	
	match owner:
		Global.enemy_node: # Checks wether the one attacking, the parent of this component, is the player or enemy.
			punch(Global.player_node, punch_height, punch_range, attack_damage, punch_direction)
			return
			
		Global.player_node:
			punch(Global.enemy_node, punch_height, punch_range, attack_damage, punch_direction)
			return
			
		_:
			printerr("Attacking Component: ", owner.name, " is neither the player or the assigned enemy in global.")
			return 
	
func punch(input_node : Node2D, punch_height : int, punch_range : int, attack_damage : float, punch_direction : int) -> bool:
	if input_node.defense_component == null: # Checks to see if the enemy has a defense component.
		printerr("Attacking Component: Target node has no defense component.")
		return false
		
	if input_node.defense_component.has_method("check_defense") == false:
		printerr("Attacking Component: Targetted node's defense component doesn't have the function that's being called.")
		return false # Checks to see if the defense component has that function
		
	# If it was a star punch, change the attack damage to reflect the amount of star punches used.
	if owner is Player and str(animation_tree["parameters/playback"].get_current_node()).contains("star") == true: 
		attack_damage = calculate_start_punch_damage(attack_damage)
	
	# Stores the response given by the defense component about whether or not the hit was succesful
	var defense_response : bool = await input_node.defense_component.check_defense(punch_height, punch_range, attack_damage, punch_direction)
	
	match defense_response: 
		true: # Hit landed/was successful
			if str(animation_tree["parameters/playback"].get_current_node()).contains("star") == true: # Checks if it was a star punch animation.
				FightManager.star_punches_landed += 1  # If it was a star punch and the hit was true, then increase the star punch landed variable
				
			FightManager.stars_used = 0
			FightManager.succesful_hit_signal.emit() # emits the signal if the defense component responds that the attack landed
			return defense_response
		
		false: # Punch missed or was blocked.
			if owner is Player: # Checks to see if the attacker is the player. If the player missed an attack, lower their stamina.
				FightManager.lower_stamina()
				FightManager.stars_used = 0
			return defense_response
		_: 
			return false

func attack_flash() -> void:
	if owner is Enemy:
		animated_sprite_2d.material.set_shader_parameter("Visible", true)
		await get_tree().create_timer(enemy_flash_duration).timeout
		animated_sprite_2d.material.set_shader_parameter("Visible", false)
		return
	push_warning("Player cannot do attack flash, only enemies.")

func parry_damage_bonus() -> void:
		parry_attack_timer.start()


func create_parry_timer() -> void:
	parry_attack_timer = Timer.new()
	parry_attack_timer.name = "Attack Delay Timer"
	parry_attack_timer.wait_time = parry_bonus_duration
	parry_attack_timer.one_shot = true
	add_child(parry_attack_timer)
	
## This is the equation used for calculating star punch damage in relation to the amount of stars used.
##
## @tutorial: https://www.desmos.com/calculator/ck5t9wejr0
## Basically, it's not a linear equation, its slightly exponential.
## That way, the first star doesn't have the same weight as the 3rd star, and the more the player holds on to the stars, the more damage they can do.
func calculate_start_punch_damage(attack_damage: float) -> float:
	return snappedf(attack_damage * ( (float(FightManager.stars_used) + 1.0) ** 2.0 / 4.0), 5.0)
