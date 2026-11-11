extends Control

var arena_scene = load("uid://b2o12w57mpc12")

const RICK_BRUISER = preload("uid://c4mjuykvitlyo")
const NICK_BRUISER = preload("uid://7858o2inqkak")
const NICK_BRUISER_DEBUG = preload("uid://ci641r2v5mxlg")

func _ready() -> void:
	if OS.is_debug_build() == true:
		SceneChanger.change_scene(arena_scene, self)
		FightManager.reset_everything()
		return


func _on_button_pressed() -> void: # Nick
	SceneChanger.change_to_arena(NICK_BRUISER, self)
	FightManager.reset_everything()

func _on_button_2_pressed() -> void:
	SceneChanger.change_to_arena(RICK_BRUISER, self)
	FightManager.reset_everything()


func _on_button_3_pressed() -> void:
	SceneChanger.change_to_arena(NICK_BRUISER_DEBUG, self)
	FightManager.reset_everything()
