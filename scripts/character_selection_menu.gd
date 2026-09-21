extends Control

var arena_scene = load("uid://b2o12w57mpc12")

const RICK_BRUISER = preload("uid://c4mjuykvitlyo")
const NICK_BRUISER = preload("uid://7858o2inqkak")

func _on_button_pressed() -> void: # Nick
	
	var arena : Arena = arena_scene.instantiate()
	
	arena.enemy_scene = NICK_BRUISER
	get_tree().change_scene_to_node(arena)


func _on_button_2_pressed() -> void:
	var arena : Arena = arena_scene.instantiate()
	
	arena.enemy_scene = RICK_BRUISER
	get_tree().change_scene_to_node(arena)
