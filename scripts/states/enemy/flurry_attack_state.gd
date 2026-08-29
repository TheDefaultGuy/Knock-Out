@icon("res://assets/icons/MaterialSymbolsDeliveryTruckSpeedRounded.svg")
## A state in which the enemy will perform an intro animation and then a series of repeated moves,
## Similar to Piston Hondo's "Hondo Rush", Mr Sandman's "Dreamland Express", and Super Macho Man's Clotheslines.
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name FlurryAttackState extends State

@onready var anim_state_machine = animation_tree.get("parameters/playback")

#region Exported Variables
@export_category("🎬 Animations & Moveset")
## The state machine animation that will play in this state that holds all of the attacks.
@export var state_machine_animation : String = "flurry_attack"

## How the delay between each attack is handled.
@export_category("⚙️ Attack Settings")

## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export var number_of_repetitions : int = 3


@export_category("⇄ State Changing Conditions")
## The state the enemy will transition to if the player got knocked out during this state.
@export var KO_state : State
## The state the enemy will transition to if the player survived this state.
@export var survived_state : State

var target_state : State

var attack_count : int = -1
#endregion

#region The Ready, Enter and Exit functions
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)

	anim_state_machine.travel(state_machine_animation)
	if KO_state == null:
		printerr(self.name, " : KO State not set.")
	if survived_state == null:
		survived_state = get_parent().interrupted_state
		
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	target_state = survived_state
	
	animation_tree.animation_finished.connect(increase_count.unbind(1))
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)

	attack_count = -1 # Resets the attack count when re-entering this state
	
func exit() -> void:
	animation_tree.animation_finished.disconnect(increase_count.unbind(1))
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)

	
func _process(_delta: float) -> void:
	if state_machine_animation != null:
		animation_tree.set(str("parameters/",state_machine_animation,"/conditions/ko"), Global.player_node.isKnockdown)
	return
#endregion

## Increases the attack count variable by 1 every time an animation is played in this state.
func increase_count() -> void:
	attack_count += 1
	if attack_count >= number_of_repetitions:
		animation_tree[str("parameters/", state_machine_animation ,"/playback")].travel("End")
		transition(self, target_state)
		

func change_state() -> void:
	target_state = KO_state
