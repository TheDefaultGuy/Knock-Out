extends Control

const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	match Global.winner:
		Global.WinnerEnum.PLAYER:
			%Label.text = "You won!"
			
		Global.WinnerEnum.ENEMY:
			%Label.text = "You Lost :("


func _on_button_2_pressed() -> void:
	var menu : Control = CHARACTER_SELECTION_MENU.instantiate()
	get_tree().change_scene_to_node(menu)
	self.queue_free()
