@icon("res://assets/icons/MdiSwordCross.svg")
## This component is responsible for performing the attacks.
## It's used by the attack animations in the Move Set Animation Player and iteracts with the defense component.
class_name AttackingComponent extends Node

## Multiplier for the attack's damage. mainly used by the player.
@export_custom(PROPERTY_HINT_NONE, "suffix:x") var attack_multiplier : float = 1.0 

var enemy_flash_duration := 0.25

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
## Function that called by the attack animations
##
## It calls functions in the opposing fighter's defense component, giving it the attacks variables as input.
## Which the attack covers, the dodge range, how much damage it does, etc...
## The defense compomnent then checks if the attack is successful and returns the result.] to the attack component.
func send_attack_call(punch_height : int, punch_range : int, attack_damage : float, punch_direction : int, star_punch : bool):
	if Global.enemy_node != null and Global.player_node != null:
		match owner:
			Global.enemy_node: # Checks wether the one attacking, the parent of this component, is the player or enemy.
				punch(Global.player_node, punch_height, punch_range, attack_damage, punch_direction, star_punch)
					
			Global.player_node:
				punch(Global.enemy_node, punch_height, punch_range, attack_damage, punch_direction, star_punch)
				
			_:
				printerr("Attacking Component: ", owner.name, " is neither the player or the assigned enemy in global.")
				return
	
#region Trouble Shooting if statements
	elif Global.enemy_node != null and Global.player_node == null:
		printerr("Attacking Component: No player node assigned in global.")
		return
	elif Global.enemy_node == null and Global.player_node != null:
		printerr("Attacking Component: No enemy node assigned in global.")
		return
	elif Global.enemy_node == null and Global.player_node == null:
		printerr("Attacking Component: No enemy node AND no player node assigned in global.")
		return
#endregion
		
func punch(input_node : Node2D, punch_height : int, punch_range : int, attack_damage : float, punch_direction : int, star_punch : bool):
	if input_node.defense_component != null: # Checks to see if the enemy has a defense component.
				if input_node.defense_component.has_method("check_defense") == true: # Checks to see if the defense component has that function
					
					if owner is Player and star_punch == true: # If it was a star punch, change the attack damage to reflect the amount of star punches used.
						
						# This is the equation used for calculating star punch damage in relation to the amount of stars used: https://www.desmos.com/calculator/ck5t9wejr0
						# Basically, it's not a linear equation, its slightly exponential.
						# That way, the first star doesn't have the same weight as the 3rd star, and the more the player holds on to the stars, the more damage they can do.
						attack_damage = snappedf(attack_damage * ( (float(FightManager.stars_used) + 1.0) ** 2.0 / 4.0), 5.0)
					
					if input_node.defense_component.call("check_defense", punch_height, punch_range, attack_damage, punch_direction) == true:
						if star_punch == true: # If it was a star punch and the hit was true, then increase the star punch landed variable
							FightManager.star_punches_landed += 1
						FightManager.stars_used = 0
						FightManager.succesful_hit_signal.emit() # emits the signal if the defense component responds that the attack landed
						return
						
					else:
						if owner is Player: # Checks to see if the attacker is the player. If the player missed an attack, lower their stamina.
							FightManager.lower_stamina()
							FightManager.stars_used = 0
						return
						
				elif input_node.defense_component.has_method("check_defense") == false:
					printerr("Attacking Component: Targetted node's defense component doesn't have the function that's being called.")
	elif input_node.defense_component == null:
		printerr("Attacking Component: No defense component.")

func attack_flash() -> void:
	if owner is Enemy:
		animated_sprite_2d.material.set_shader_parameter("Visible", true)
		await get_tree().create_timer(enemy_flash_duration).timeout
		animated_sprite_2d.material.set_shader_parameter("Visible", false)
		return
	push_warning("Player cannot do attack flash, only enemies.")
