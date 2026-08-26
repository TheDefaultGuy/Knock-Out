@tool
extends Node

signal update_ui_signal
signal star_awarded_signal
signal no_stamina_signal # Signal emitted when the player no longer has stamina so that they can transition to the tired state.

@warning_ignore("unused_signal")
signal sfx_punch_thrown_signal
@warning_ignore("unused_signal")
signal sfx_dodge_signal
@warning_ignore("unused_signal")
signal sfx_punch_hit_signal
@warning_ignore("unused_signal")
signal sfx_duck_signal
@warning_ignore("unused_signal")
signal sfx_star_punch_thrown_signal
@warning_ignore("unused_signal")
signal player_knocked_down_signal
@warning_ignore("unused_signal")
signal enemy_knocked_down_signal
@warning_ignore("unused_signal")
signal fighter_got_up_signal # Signal emitted when the player or enemy successfully gets back up after being knocked down.

@warning_ignore("unused_signal")
signal succesful_hit_signal # Signal emitted when either the player or enemy succesfully land a hit. Mainly used to trigger sound effects.
@warning_ignore("unused_signal")
signal succesful_block_signal # Signal emitted when either the player or enemy succesfully blocked. Mainly used to trigger sound effects.
@warning_ignore("unused_signal")
signal missed_attack_signal # Signal emitted when either the player or enemy completely whiffs a hit. Mainly used to trigger sound effects.

signal resume_fighting_signal # Signal emitted when it's time to resume/start fighting.

@warning_ignore("unused_signal")
signal fighter_ready_signal # Signal emitted when a fighter is ready to start fighting.

@warning_ignore("unused_signal")
signal start_get_up_signal # Signal emitted when a fighter finished the knock down animation and is time to get up.

@warning_ignore("unused_signal")
signal fight_is_over_signal # Signal emitted when a fighter fails to get up before 10 or is TKO'd

# Whether the player and enemy are ready to fight so that the round can start.
var player_ready_status : bool = true
var enemy_ready_status : bool = true

## The number of stars the player currently has.
var star_count : int = 0

## The Player's stamina
var stamina: int = 20 

## Number of times the player has been knocked down in the current round.
var player_ko_count : int = 0

## Number of times the player has been knocked down in the current round.
var enemy_ko_count : int = 0 

## Which round of the fight it currently is. 0 = 1st round, 1 = 2nd round , 2 = 3rd round.
var round_idx : int = 0 

var round_time : float = 0.0

var max_player_stamina : int = 20

func _ready() -> void:
	player_knocked_down_signal.connect(increase_player_ko_count)
	enemy_knocked_down_signal.connect(increase_enemy_ko_count)
	fighter_ready_signal.connect(start_the_fight)


func increase_enemy_ko_count() -> void:
	enemy_ko_count = clampi(enemy_ko_count + 1 , 0 , 3)
	if enemy_ko_count >= 3: # Checks for TKO; 3 knockouts
		print_rich("[b][u]\nFightManager: TKO ENEMY[/u][/b]")
		fight_is_over_signal.emit()
		
func increase_player_ko_count() -> void:
	player_ko_count = clampi(player_ko_count + 1 , 0 , 3)
	if player_ko_count >= 3: # Checks for TKO; 3 knockouts
		print("[b][u]\nFightManager: TKO PLAYER[/u][/b]")
		fight_is_over_signal.emit()
		
func reset_ko_count() -> void:
	enemy_ko_count = 0
	player_ko_count = 0

func award_star() -> void:
	print("Fight Manager: PLAYER WAS AWARDED A STAR")
	star_count = clampi(star_count + 1 , 0 , 3)
	update_ui_signal.emit()
	star_awarded_signal.emit()
	
func use_stars() -> void:
	print("Fight Manager: PLAYER USED THEIR STARS")
	star_count = 0
	update_ui_signal.emit()

## Lowers the players stamina by 1 each time it's called
func lower_stamina() -> void:
	stamina = clampi(stamina - 1, 0 , max_player_stamina)
	if stamina == 0:
		no_stamina_signal.emit()
	update_ui_signal.emit()
	
func set_stamina() -> void: 
		stamina = max_player_stamina
		update_ui_signal.emit()
		
func start_the_fight() -> void: # Emits the signal for both fighters to resume fighting and resets their fighting status.
	if enemy_ready_status == true and player_ready_status == true:
		enemy_ready_status = false
		player_ready_status = false
		resume_fighting_signal.emit()
		print("Fight Manager: READY TO FIGHT")
