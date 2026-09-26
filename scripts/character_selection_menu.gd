extends Control

var arena_scene = load("uid://b2o12w57mpc12")

const RICK_BRUISER = preload("uid://c4mjuykvitlyo")
const NICK_BRUISER = preload("uid://7858o2inqkak")

func _ready() -> void:
	if OS.is_debug_build() == true:
		SceneChanger.change_scene(arena_scene, self)
		return


func _on_button_pressed() -> void: # Nick
	SceneChanger.change_to_arena(NICK_BRUISER, self)

func _on_button_2_pressed() -> void:
	SceneChanger.change_to_arena(RICK_BRUISER, self)
