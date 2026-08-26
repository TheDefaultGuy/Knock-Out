@icon("res://assets/icons/MdiSwordCross.svg")
## This component is responsible for performing the attacks.
## It's used by the attack animations in the Move Set Animation Player and iteracts with the defense component.
class_name AttackingComponent extends Node

## Multiplier for the attack's damage. mainly used by the player.
@export_custom(PROPERTY_HINT_NONE, "suffix:x") var attack_multiplier : float = 1.0 

## Function that called by the attack animations
##
## It calls functions in the opposing fighter's defense component, giving it the attacks variables as input.
## Which the attack covers, the dodge range, how much damage it does, etc...
## The defense compomnent then checks if the attack is successful and returns the result.] to the attack component.
func send_attack_call(punch_height : int, punch_range : int, attack_damage : float, punch_direction : int):
	if Global.enemy_node != null and Global.player_node != null:
		match get_parent():
			Global.enemy_node: # Checks wether the one attacking, the parent of this component, is the player or enemy.
				punch(Global.player_node, punch_height, punch_range, attack_damage, punch_direction)
					
			Global.player_node:
				punch(Global.enemy_node, punch_height, punch_range, attack_damage, punch_direction)
				
			_:
				printerr("Attacking Component: ", get_parent().name, " is neither the player or the assigned enemy in global.")
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
		
func punch(input_node : Node2D, punch_height : int, punch_range : int, attack_damage : float, punch_direction : int):
	if input_node.defense_component != null: # Checks to see if the enemy has a defense component.
				if input_node.defense_component.has_method("check_defense") == true: #Checks to see if the defense component has that function
					if input_node.defense_component.call("check_defense", punch_height, punch_range, attack_damage, punch_direction) == true:
						FightManager.succesful_hit_signal.emit() # emits the signal if the defense component responds that the attack landed
						return
						
					else:
						if get_parent().isPlayer == true: # Checks to see if the attacker is the player. If the player missed an attack, lower their stamina.
							FightManager.lower_stamina()
						return
						
				elif input_node.defense_component.has_method("check_defense") == false:
					printerr("Attacking Component: Targetted node's defense component doesn't have the function that's being called.")
	elif input_node.defense_component == null:
		printerr("Attacking Component: No defense component.")
