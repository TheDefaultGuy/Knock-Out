extends Control

const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

@onready var label: Label = $MarginContainer/VBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match Global.winner:
		Global.player_node:
			label.text = "You won!"
		Global.enemy_node:
			label.text = "You Lost :("
func _on_button_2_pressed() -> void:
	var menu : Control = CHARACTER_SELECTION_MENU.instantiate()
	get_tree().change_scene_to_node(menu)
	self.queue_free()
