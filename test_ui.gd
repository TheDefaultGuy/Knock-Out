extends Control

@onready var front_bar: ProgressBar = $"Front Bar"
@onready var back_bar: ProgressBar = $"Back Bar"

## How long the [member accumulation_timer] waits until depleting the white progress bar.
const ACCUMULATION_WAIT_TIME : float = 1.0

var accumulation_timer : Timer = null

var stored_hp : float = 0.0



var hp : float = 100.0:
	set(value):
		handle_timer()
		
		hp = max(0, value)
		print("HP Changed: ", hp)
		
		animate_bar(front_bar, 0.075)
		#front_bar.value = hp
		

func _ready() -> void:
	accumulation_timer = TimerCreator.create_timer_and_add_as_child("Acc Timer", true, ACCUMULATION_WAIT_TIME, false, self)
	accumulation_timer.timeout.connect(_on_timer_timeout)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_punch") or Input.is_action_just_pressed("right_punch"):
		hp -= 5.0


func handle_timer() -> void:
	
	# If the accumulation_timer is stopped, then store the current HP into stored HP.
	if accumulation_timer.is_stopped():
		stored_hp = hp
		
	# Starts the accumulation_timer after storing the HP.
	accumulation_timer.start()

func _on_timer_timeout() -> void:
	# Resets stored HP back to 0.0
	stored_hp = 0.0
	
	# Animates the white bar
	animate_bar(back_bar, 0.5)

## Animates the progress bars depleting.
func animate_bar(bar : ProgressBar, duration : float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(bar, "value", hp , duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
