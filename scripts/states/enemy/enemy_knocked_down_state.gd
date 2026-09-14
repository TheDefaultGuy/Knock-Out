@icon("res://assets/icons/StreamlineSleepSolid.svg")
## This is the state in which the enemy is knocked down.
## It is a required state for all enemies.
class_name EnemyKnockedDown extends State

var get_up_timer : Timer = null

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_getup_time : float = 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_getup_time : float = 8.0

func _ready() -> void:

	get_up_timer = Timer.new()
	get_up_timer.autostart = false
	get_up_timer.one_shot = true
	add_child(get_up_timer)
	get_up_timer.timeout.connect(get_up)
	
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.enemy_ready_status = false
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	
func exit() -> void:
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	get_up_timer.stop()

func get_up() -> void:
	anim_state_machine.travel("get_up")
	health_component.reset_hp()
	
func start_get_up_timer() -> void:
	print("START GETUP TIMER")
	get_up_timer.start(randf_range(min_getup_time, max_getup_time))

	
	
