extends Control

const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	match Global.winner:
		Global.WinnerEnum.PLAYER:
			%Label.text = "You won!"
			
		Global.WinnerEnum.ENEMY:
			%Label.text = "You Lost :("
		
		_:
			%Label.text = "Ran out of time"

func _on_button_2_pressed() -> void:
	print("Pressed button")
	SceneChanger.change_scene(load("uid://bvyokq5qbudmq"), self)
