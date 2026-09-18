extends Control

const ARENA_SCENE = preload("uid://b2o12w57mpc12")

const NICK_BRUISER = preload("uid://7858o2inqkak")
const RICK_BRUISER = preload("uid://c4mjuykvitlyo")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void: # Nick
	var arena : Arena = ARENA_SCENE.instantiate()
	arena.enemy_scene = NICK_BRUISER
	get_tree().change_scene_to_node(arena)


func _on_button_2_pressed() -> void:
	var arena : Arena = ARENA_SCENE.instantiate()
	arena.enemy_scene = RICK_BRUISER
	get_tree().change_scene_to_node(arena)
