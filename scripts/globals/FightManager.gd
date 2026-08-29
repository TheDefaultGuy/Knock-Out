@tool
extends Node
#region Signals
## Signal emitted when the value of something displayed in the UI has changed.
signal update_ui_signal

## Signal emitted when the player is awarded a star punch.
signal star_awarded_signal

## Signal emitted when the player no longer has stamina so that they can transition to the tired state.
signal no_stamina_signal 

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
## Signal emitted when the player or enemy successfully gets back up after being knocked down.
signal fighter_got_up_signal 

@warning_ignore("unused_signal")
## Signal emitted when either the player or enemy succesfully land a hit. Mainly used to trigger sound effects.
signal succesful_hit_signal 

@warning_ignore("unused_signal")
## Signal emitted when either the player or enemy succesfully blocked. Mainly used to trigger sound effects.
signal succesful_block_signal 

@warning_ignore("unused_signal")
## Signal emitted when either the player or enemy completely whiffs a hit. Mainly used to trigger sound effects.
signal missed_attack_signal 

## Signal emitted when it's time to resume/start fighting.
signal resume_fighting_signal 

@warning_ignore("unused_signal")
## Signal emitted when it's time to start the fight.
signal start_the_fight_signal 

@warning_ignore("unused_signal")
## Signal emitted to let the enemy boxer know when to start their intro animation at the start of the fight.
signal start_intro_animation_signal

@warning_ignore("unused_signal")
## Signal emitted when a fighter is ready to start fighting. Emitted by both player and enemy once they finish their getting up animations.
signal fighter_ready_signal 

@warning_ignore("unused_signal")
## Signal emitted when a fighter finished the knock down animation and is time to get up.
signal start_get_up_signal 

@warning_ignore("unused_signal")
## Signal emitted when a fighter fails to get up before 10 or is TKO'd. Means the fight is over and gameplay is over.
signal fight_is_over_signal
#endregion

#region Stored variables
## Whether the player has finished any animation and are ready to fight.
## This is used so that even if the player and enemy have different animation lengths, they get synchronized and can start fighting at the same time.
var player_ready_status : bool = true

## Whether the enemy has finished any animation and are ready to fight.
## This is used so that even if the player and enemy have different animation lengths, they get synchronized and can start fighting at the same time.
var enemy_ready_status : bool = true

## The number of stars the player currently has.
var star_count : int = 2

## The Player's stamina
var stamina: int = 20 

## Number of times the player has been knocked down in the current round.
var player_ko_count : int = 0

## Number of times the player has been knocked down in the current round.
var enemy_ko_count : int = 0 

## Which round of the fight it currently is. 0 = 1st round, 1 = 2nd round , 2 = 3rd round.
var round_idx : int = 0 

## The current round time in seconds.
var round_time : float = 0.0

## The maximum players stamina.
var max_player_stamina : int = 20

## The number of stars the player used in their star punch.
## Used by the Attack Component to calculate the damage of the star punch and by the Instant KO Component to validate if it was a KO.
var stars_used : int = 0

## Keeps track of the amount of star punches the player has used.
## Used mainly by the Instant KO Component
var star_punches_landed : int = 0
#endregion

func _ready() -> void:
	player_knocked_down_signal.connect(increase_player_ko_count)
	enemy_knocked_down_signal.connect(increase_enemy_ko_count)
	fighter_ready_signal.connect(start_the_fight)
	stars_used = 0
	star_punches_landed = 0
	
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
## Adds a star to the player's star count and emits the signals related to it.
func award_star() -> void:
	print("Fight Manager: player was awarded a star")
	star_count = clampi(star_count + 1 , 0 , 3)
	update_ui_signal.emit()
	star_awarded_signal.emit()
	stars_used = 0
	
## Resets the player's star count back to zero after using them.
func use_stars() -> void:
	print("Fight Manager: player used ", star_count, " stars")
	stars_used = star_count
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
		
## Emits the signal for both fighters to resume fighting and resets their fighting status.
func start_the_fight() -> void: 
	if enemy_ready_status == true and player_ready_status == true:
		enemy_ready_status = false
		player_ready_status = false
		resume_fighting_signal.emit()
		print("Fight Manager: both fighters ready to fight")
