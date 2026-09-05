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
class_name FlurryAttack extends State

#@onready var anim_state_machine = animation_tree.get("parameters/playback")

#region Exported Variables

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

var root_state_machine: AnimationNodeStateMachine = null

@onready var state_machine : AnimationNodeStateMachine = preload("uid://bg1hc7fvrio3n")
var machine_name = null
#endregion

#region The Ready, Enter and Exit functions
func _ready() -> void:
	#reset_animation_tree()
	root_state_machine = animation_tree.tree_root
	machine_name = str(name, "_state_machine") 
	## Automatically adds the state machine node to the animation tree.
	root_state_machine.add_node(machine_name, state_machine, Vector2(0,0))
	var connection = AnimationNodeStateMachineTransition.new()
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	connection.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	root_state_machine.call_deferred("add_transition", machine_name, "hub_node", connection)
	
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	
	if KO_state == null:
		printerr(self.name, " : KO State not set.")
	if survived_state == null:
		survived_state = get_parent().interrupted_state
		
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	target_state = survived_state
	
	animation_tree.animation_finished.connect(increase_count.unbind(1))
	FightManager.player_knocked_down_signal.connect(change_state)
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	attack_count = -1 # Resets the attack count when re-entering this state
	await get_tree().create_timer(1.0).timeout
	anim_state_machine.travel(machine_name)

func exit() -> void:
	animation_tree.animation_finished.disconnect(increase_count)
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	FightManager.player_knocked_down_signal.disconnect(change_state)
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	animation_tree.set(str("parameters/",machine_name,"/conditions/ko"), Global.player_node.isKnockdown)

#endregion

## Increases the attack count variable by 1 every time an animation is played in this state.
func increase_count() -> void:
	attack_count += 1
	if attack_count >= number_of_repetitions:
		animation_tree[str("parameters/",machine_name,"/playback")].travel("End")
		transition(self, target_state)
		

func change_state() -> void:
	target_state = KO_state
