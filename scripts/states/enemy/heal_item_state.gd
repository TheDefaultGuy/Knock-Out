@icon("res://assets/icons/PinheadPillBottleWithGreekCross.svg")
@tool
## A state in which the enemy will attempt to heal with an item,
## similar to Doc Louis with his chocolate and Soda Popinski with his "Soda".
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name ItemHeal extends State


#region Exported Variables
## How the delay between each attack is handled.
#@export_category("⚙️ Attack Settings")



@export_category("⇄ State Changing Conditions")
## The state the enemy will transition to if the player got knocked out during this state.
@export var failed_heal_state : State
### The state the enemy will transition to if the player survived this state.
@export var successful_heal_state : State
var check_animation_status : bool = false

var target_state : State

var root_state_machine: AnimationNodeStateMachine = null
@onready var state_machine : AnimationNodeStateMachine = preload("uid://dt6b8hv77b0dh")
var machine_name = null

#endregion

#region The Ready, Enter and Exit functions
func _ready() -> void:
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
	animation_tree.set("parameters/conditions/stunned", false)
	
	
	anim_state_machine.travel(machine_name)
	
	if failed_heal_state == null:
		printerr(self.name, " : Failed Healed State not set.")
	if successful_heal_state == null:
		successful_heal_state = get_parent().interrupted_state
		
	## Sets the interrupted state as the successful heal state by default.
	## gets overridden by the failed heal state if the enemy gets hit during this state.
	target_state = successful_heal_state
	
	animation_tree.animation_finished.connect(check_animation)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	FightManager.succesful_hit_signal.connect(change_to_failed_state)
	
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = "item_hit"
	defense_component.current_anim_state_machine = animation_tree[str("parameters/", str(machine_name) ,"/playback")]
	check_animation_status = true
	
func exit() -> void:
	# Resets the hit animation and state machine in the defense component back to the default hit animation.
	defense_component.reset_current_animations()
	animation_tree.animation_finished.disconnect(check_animation)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	FightManager.succesful_hit_signal.disconnect(change_to_failed_state)
	
#endregion

## Checks if it's no longer in the animation state machine, which would mean it finished the animation.
func check_animation(_animation_name : StringName) -> void:
	if check_animation_status == true:
		if anim_state_machine.get_current_node() != machine_name:
			transition(self, target_state)

## If the player got hit, then the interrupted state will be set to the failed healed state.
func change_to_failed_state() -> void:
	target_state = failed_heal_state
