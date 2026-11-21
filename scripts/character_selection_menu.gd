extends Control

var arena_scene = load("uid://b2o12w57mpc12")

var RICK_BRUISER = load("uid://c4mjuykvitlyo")
var NICK_BRUISER = load("uid://7858o2inqkak")
var NICK_BRUISER_DEBUG = load("uid://ci641r2v5mxlg")

#func _ready() -> void:
	#if OS.is_debug_build() == true:
		#SceneChanger.change_scene(arena_scene, self)
		#FightManager.reset_everything()
		#return


func _on_button_pressed() -> void: # Nick
	SceneChanger.change_to_arena(NICK_BRUISER, self, false)
	FightManager.reset_everything()

func _on_button_2_pressed() -> void:
	SceneChanger.change_to_arena(RICK_BRUISER, self, false)
	FightManager.reset_everything()


func _on_button_3_pressed() -> void:
	SceneChanger.change_to_arena(NICK_BRUISER_DEBUG, self, false)
	FightManager.reset_everything()

func _on_button_4_pressed() -> void:
	print("Playing demo...")
	var demo_data : Dictionary = DemoFileManager._load_demo()
	var fight_data : Dictionary = demo_data["fight_data"]
	
	SceneChanger.change_to_arena(load(fight_data["fighter"]), self, true)
	
