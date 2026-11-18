extends Control

const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	
	# Does the math to convert the seconds to M:SS:MSS format.
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	var time_left = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])
	
	
	match Global.winner:
		Global.WinnerEnum.PLAYER:
			%Label.text = str("You won!\n Points: ", PointsManager.points, "\n", str(time_left))
			
		Global.WinnerEnum.ENEMY:
			%Label.text = str("You Lost :(\n Points: ", PointsManager.points)
		
		_:
			%Label.text = str("Ran out of time\n Points: ", PointsManager.points)

func _on_button_2_pressed() -> void:
	print("Pressed button")
	SceneChanger.change_scene(load("uid://bvyokq5qbudmq"), self)
