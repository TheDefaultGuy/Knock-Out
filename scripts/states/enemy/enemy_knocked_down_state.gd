@icon("res://assets/icons/StreamlineSleepSolid.svg")
## This is the state in which the enemy is knocked down.
## It is a required state for all enemies.
class_name EnemyKnockedDownState extends State



@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_getup_time : float = 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_getup_time : float = 9.0

func _ready() -> void:
	FightManager.start_get_up_signal.connect(start_get_up_timer)
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.enemy_ready_status = false

func exit() -> void:
	FightManager.start_get_up_signal.disconnect(start_get_up_timer)
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)

	
func start_get_up_timer() -> void:
	if get_parent().current_state != self:
		return
	await get_tree().create_timer(randf_range(min_getup_time, max_getup_time)).timeout
	anim_state_machine.travel("get_up")
	health_component.reset_hp()
	
