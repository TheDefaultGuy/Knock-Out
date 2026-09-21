extends Node
#region Signals
## Signal emitted when the value of something displayed in the UI has changed.
signal update_ui_signal

## Signal emitted when the [Player] is awarded a star punch.
signal star_awarded_signal

## Signal emitted when the [Player] no longer has [member stamina] so that they can transition to the [TiredState].
signal no_stamina_signal 

## Signal emitted so that the [SoundEffectsComponent] plays the given sfx.
@warning_ignore("unused_signal")
signal play_sfx_signal(sfx_name)

## Signal emitted by the [HealthComponent] when the [Player] [member HealthComponent.hp] value drops to 0 and they enter [PlayerKnockedDown] state.
@warning_ignore("unused_signal")
signal player_knocked_down_signal

## Signal emitted by the [HealthComponent] when the [Enemy] [member HealthComponent.hp] value drops to 0 and they enter [EnemyKnockedDown] state.
@warning_ignore("unused_signal")
signal enemy_knocked_down_signal

## Signal emitted when the [Player] or [Enemy] successfully gets back up after being knocked down.
@warning_ignore("unused_signal")
signal fighter_got_up_signal 

## Signal emitted when the [Player] or [Enemy] finishes the spectating animation so that the other one can start to get up.
@warning_ignore("unused_signal")
signal fighter_can_start_getup_signal 

## Signal emitted when either the [Player] or [Enemy] succesfully land a hit.
@warning_ignore("unused_signal")
signal succesful_hit_signal 

## Signal emitted when either the [Player] or [Enemy] succesfully blocked.
@warning_ignore("unused_signal")
signal successful_block_signal 

## Signal emitted when it's time to resume/start fighting.
@warning_ignore("unused_signal")
signal resume_fighting_signal 
#
### Signal emitted when it's time to start the fight.
#@warning_ignore("unused_signal")
#signal start_the_fight_signal 
#
### Signal emitted to let the [Enemy] know when to start their intro animation at the start of the fight.
#@warning_ignore("unused_signal")
#signal start_intro_animation_signal
#
## Signal emitted when a [Fighter] is ready to start fighting. Emitted by both [Player] and [Enemy] once they finish their getting up animations.
signal fighter_ready_signal 

## Signal emitted when a [Fighter] finished the knock down animation and is time to get up.
@warning_ignore("unused_signal")
signal start_ko_count_signal 

## Signal emitted when a [Fighter] fails to get up before 10 or is TKO'd. Means the fight is over and gameplay is over.
@warning_ignore("unused_signal")
signal fight_is_over_signal

## Signal emitted by [StunState] when it's the last hit of Stun.
## Used by [InputComponent] to temporarily disable attacks to avoid unnecessary punches after stun is over.
@warning_ignore("unused_signal")
signal final_stun_hit_signal

## Signal emitted by the [Player] when they dodge.
## Mainly used by [Reactionary] State to read the player's dodge.
@warning_ignore("unused_signal")
signal player_dodged_signal(direction)

@warning_ignore("unused_signal")
signal go_to_results_screen_signal
#endregion

#region Stored variables
## Whether the [Player] has finished any animation and are ready to fight.
## This is used so that even if the [Player] and [Enemy] have different animation lengths, they get synchronized and can start fighting at the same time.
var player_ready_status : bool = true

## Whether the [Enemy] has finished any animation and are ready to fight.
## This is used so that even if the [Player] and [Enemy] have different animation lengths, they get synchronized and can start fighting at the same time.
var enemy_ready_status : bool = true

## Keeps track of whether the fight is over.
var is_fight_over : bool = false

## The number of stars the [Player] currently has.
var star_count : int = 2 :
	# Clamps the value and emits the signal to update the UI everytime the value is set.
	set(value):
		star_count = clampi(value, 0 , 3) 
		update_ui_signal.emit()

## The Player's stamina. Drains if they're hit, block, or miss an attack.
var stamina : int = 10 :
	# Clamps the value and emits the signal to update the UI everytime the value is set.
	set(value):
		stamina = clampi(value, 0 , max_player_stamina)
		update_ui_signal.emit()
		
		if stamina == 0 : # If stamina reaches 0, emit the no_stamina_signal
			no_stamina_signal.emit()

## Number of times the [Player] has been knocked down in the current round.
var player_ko_count : int = 0 : 
	# Clamps the value and emits the signal to update the UI everytime the value is set.
	set(value):
		player_ko_count = clampi(value, 0 , 3)
		print("Playery KD Count: ", player_ko_count)
		if player_ko_count == 3: # Checks for TKO; 3 knockouts
			print_rich("[b][u]\nFightManager: TKO Player[/u][/b]")
			Global.winner = Global.enemy_node
			is_fight_over = true
			

## Number of times the [Enemy] has been knocked down in the current round.
var enemy_ko_count : int = 2 :
	# Clamps the value and emits the signal to update the UI everytime the value is set.
	set(value):
		enemy_ko_count = clampi(value, 0 , 3)
		print("Enemy KD Count: ", enemy_ko_count)
		if enemy_ko_count == 3: # Checks for TKO; 3 knockouts
			print_rich("[b][u]\nFightManager: TKO enemy[/u][/b]")
			Global.winner = Global.player_node
			is_fight_over = true

## Which round of the fight it currently is. 0 = 1st round, 1 = 2nd round , 2 = 3rd round.
var round_idx : int = 0 

## The current round time in seconds.
var round_time : float = 0.0

## The maximum [Player] [member stamina].
var max_player_stamina : int = 12

## The number of stars the [Player] used in their star punch.
## Used by the [AttackingComponent] to calculate the damage of the star punch and by the [InstantKOComponent] to validate if it was a KO.
var stars_used : int = 0

## Keeps track of the amount of star punches the [Player] has used.
## Used mainly by the [InstantKOComponent].
var star_punches_landed : int = 0
#endregion

func _ready() -> void:
	player_knocked_down_signal.connect(increase_player_ko_count)
	enemy_knocked_down_signal.connect(increase_enemy_ko_count)
	fighter_ready_signal.connect(start_the_fight)
	stars_used = 0
	star_punches_landed = 0
	Global.winner = null

## Increases [member enemy_ko_count] by 1.
func increase_enemy_ko_count() -> void:
	enemy_ko_count += 1
	return

## Increases [member player_ko_count] by 1.
func increase_player_ko_count() -> void:
	player_ko_count += 1
	return

## Sets both [member enemy_ko_count] and [member player_ko_count] back to Zero.
func reset_ko_count() -> void:
	enemy_ko_count = 0
	player_ko_count = 0
	return

## Adds a star to the player's [member star_count] and emits [signal star_awarded_signal].
func award_star() -> void:
	print("Fight Manager: player was awarded a star")
	star_count += 1
	star_awarded_signal.emit()
	stars_used = 0
	return

## Resets the player's [member star_count] back to zero after using them.
func use_stars() -> void:
	print("Fight Manager: player used ", star_count, " stars")
	stars_used = star_count
	star_count = 0
	return

## Lowers the players [member stamina] by 1 each time it's called.
func lower_stamina() -> void:
	#print("Fight Manager: Lowering stamina...")
	stamina -= 1

func set_stamina() -> void: 
	stamina = max_player_stamina

## It checks if both [member enemy_ready_status] and [member player_ready_status] are true first.
## Emits the [signal resume_fighting_signal] for both fighters to resume fighting and resets their fighting status.
func start_the_fight() -> void: 
	print("Fighter Ready Signal Emitted.")
	
	if enemy_ready_status == true and player_ready_status == true:
		resume_fighting_signal.emit()
		print("Fight Manager: both fighters ready to fight")
		enemy_ready_status = false
		player_ready_status = false
