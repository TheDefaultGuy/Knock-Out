extends Control

const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	match Global.winner:
		Global.WinnerEnum.PLAYER:
			%Label.text = str("You won!\n Points: ", PointsManager.points)
			
		Global.WinnerEnum.ENEMY:
			%Label.text = str("You Lost :(\n Points: ", PointsManager.points)
		
		_:
			%Label.text = str("Ran out of time\n Points: ", PointsManager.points)

func _on_button_2_pressed() -> void:
	print("Pressed button")
	SceneChanger.change_scene(load("uid://bvyokq5qbudmq"), self)
