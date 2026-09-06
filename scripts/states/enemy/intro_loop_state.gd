@icon("res://assets/icons/IntroLoop.svg")
@tool
## This is a template state used by enemy boxers.
##
## In this state, the enemy will first perform an intro animation,
## and then loop another animation or a series of animations over and over until either they or the player are knocked down.
## This should be used to recreate attacks like Bald Bull's Bull Rush, where the enemy won't stop until somebody is knocked down.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name IntroThenLoop extends State

#@onready var anim_state_machine = animation_tree.get("parameters/playback")


#region Exported Variables
#@export_category("🎬 Animations & Moveset")
#

## How the delay between each attack is handled.
@export_category("⏱ Attack Delays")
## The minimum amount of time (in seconds) the enemy will wait before attacking.
@export_range(1.0, 8.0, 0.2, "suffix:s") var min_wait_time : float = 3.0
## The maximum amount of time (in seconds) the enemy will wait before attacking.
@export_range(1.0, 8.0, 0.25, "suffix:s") var max_wait_time : float = 8.0

@export_category("⇄ State Changing Conditions")
## The state the enemy will transition to after the conditions are met.
@export var target_state : State

var wait_timer : Timer = null

@onready var state_machine : AnimationNodeStateMachine = preload("uid://bpl60rtp2gv5i")
var root_state_machine: AnimationNodeStateMachine = null
var machine_name = null
#endregion

#region The Ready, Enter and Exit functions
func _ready() -> void:
	# Creates the timers with code so that you don't have to make timer node and then manually assign it.
	wait_timer = Timer.new()
	wait_timer.name = "Wait Timer"
	wait_timer.one_shot = true
	add_child(wait_timer)
	wait_timer.timeout.connect(perform_action)
	#reset_animation_tree()
	## Automatically adds the state machine node to the animation tree.
	
	machine_name = str(name).to_snake_case()
	call_deferred("add_attack_animation_nodes")
	
func add_attack_animation_nodes() -> void:
	root_state_machine = animation_tree.tree_root
	machine_name = str(name).to_snake_case()
	root_state_machine.add_node(machine_name, state_machine, Vector2(300.0,-550.0))
	var connection = AnimationNodeStateMachineTransition.new()
	connection.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	connection.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	root_state_machine.add_transition(machine_name, "hub_node", connection)


func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/spectating", false)
	
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	defense_component.stunned_signal.connect(transition_to_stunned)

	if target_state == null:
		printerr(self.name, " : Target State not set.")
		target_state = get_parent().interrupted_state
	if animation_tree == null:
		printerr(self.name, " : Animation tree not set.")
		

	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = target_state
	anim_state_machine.travel(machine_name)
	animation_tree[str("parameters/",machine_name,"/playback")].travel("Start")
	start_loop_timer()
	
func exit() -> void:
	#anim_state_machine.travel(machine_name)
	wait_timer.stop()
	wait_timer.timeout.disconnect(perform_action)
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
#endregion

	## Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	## This is because the defense component is the one responsible for playing the hit animation
	#defense_component.current_hit_animation = str("item_hit")
	#defense_component.current_anim_state_machine = animation_tree[str("parameters/", machine_name ,"/playback")]
	
func perform_action() -> void:
	animation_tree.get(str("parameters/",machine_name,"/playback")).travel("attack")
	start_loop_timer()
	
func change_state() -> void:
	get_parent().interrupted_state = target_state

## Function that is manually called by the "idle" animation of this state.
## It'll choose a random time between  the min and max values and once that time is up, it'll perform the next attack.
func start_loop_timer() -> void:
	wait_timer.start(randf_range(min_wait_time, max_wait_time))
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	animation_tree.set(str("parameters/",machine_name,"/conditions/ko"), Global.player_node.isKnockdown)
