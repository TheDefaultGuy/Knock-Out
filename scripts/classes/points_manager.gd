@abstract class_name PointsManager extends RefCounted

## The amount of points the player has earned throughout the match.
static var points : int = 0 :
	set(value):
		# Makes sure points dont go into the negatives.
		points = max(0, value)
		
		# Sends the signal so that the UI gets updated.
		FightManager.update_ui_signal.emit()

#region Point Values
## Points awarded when the [Player] performs a dodge.
const DODGE : int = 5

## Points awarded when the [Player] lands a regular punch on the [Enemy].
const REGULAR_PUNCH : int = 10

## Points awarded when the [Player] is awarded a star.
const STAR_GIVEN : int = 40

## Points awarded when the [Player] lands a star punch on the [Enemy].
const STAR_PUNCH : int = 90

## Points awarded when the [Player] knocksdown the [Enemy].
const KNOCKDOWN : int = 1000

## Points awarded when the [Player] succesfully performs a parry.
const PARRY : int = 20

## Points awarded when the [Player] performs an instant knockdown to the [Enemy].
const INSTANT_KD : int = 1000
#endregion
