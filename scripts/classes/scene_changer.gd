@abstract class_name SceneChanger extends RefCounted
## Class that helps out with scene transitions.

const ARENA_SCENE = preload("uid://b2o12w57mpc12")
const FADE_TRANSITION = preload("uid://dn4xvjaal87r7")


## Changes the current scene.
static func change_scene(target_scene : PackedScene, calling_node : Node) -> void:
	
	# Instantiates the packed scene into a node.
	var target_node : Node = target_scene.instantiate()
	
	# Unpauses the scene tree if it was paused
	if calling_node.get_tree().paused == true:
		calling_node.get_tree().paused = false
	#
	#var fade_scene = FADE_TRANSITION.instantiate()
	#
	#calling_node.add_child(fade_scene)
	#fade_scene.fade_in()
	#
	#await fade_scene.finished_fading
	
	# Changes the scene to the target node
	calling_node.get_tree().change_scene_to_node(target_node)
	
	# Deletes the node that called in the first place.
	calling_node.queue_free()
	
	#var new_fade_scene = FADE_TRANSITION.instantiate()
	#
##	new_fade_scene.color_rect.color.a = 1.0
	#
	#target_node.add_child(new_fade_scene)
	#
	#
	#new_fade_scene.fade_out()

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
