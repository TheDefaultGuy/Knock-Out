class_name SceneChanger extends Node
## Class that helps out with scene transitions.

const ARENA_SCENE = preload("uid://b2o12w57mpc12")


## Changes the current scene.
static func change_scene(target_scene : PackedScene, calling_node : Node) -> void:
	
	# Instantiates the packed scene into a node.
	var target_node : Node = target_scene.instantiate()
	
	# Unpauses the scene tree if it was paused
	if calling_node.get_tree().paused == true:
		calling_node.get_tree().paused = false
	
	# Changes the scene to the target node
	calling_node.get_tree().change_scene_to_node(target_node)
	
	# Deletes the node that called in the first place.
	calling_node.queue_free()

## Changes the current scene to the arena.
static func change_to_arena(fighter_scene : PackedScene, calling_node : Node) -> void:
	
	var arena : Arena = ARENA_SCENE.instantiate()
	arena.enemy_scene = fighter_scene
	
	# Unpauses the scene tree if it was paused
	if calling_node.get_tree().paused == true:
		calling_node.get_tree().paused = false
	
	# Changes the scene to the target node
	calling_node.get_tree().change_scene_to_node(arena)
	
	# Deletes the node that called in the first place.
	calling_node.queue_free()
