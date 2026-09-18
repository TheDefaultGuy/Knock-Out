extends Node
## Holds constants and nodes that are used by almost all components.
##
## [DefenseComponent] and [AttackingComponent] use [enum height] and [enum range] for having a consistent and readable way
## to determine the height of attacks, the range they conver, the direction of the attack, the dodge position, etc...

## The possible heights for attacks.
enum height{
	
	## For lower body or gut punches
	LOW = 0,
	
	## For upper or face punches
	HIGH = 1,
	
	## For moves that cover both upper and lower regions..
	BOTH = 2,
	}

## The range (X - axis) for attack range, dodge direction, or punch direction.
enum range{
	
	## Left, from the players point of reference
	LEFT = -1,
	
	## Dead Center, from the players point of reference
	NEUTRAL = 0,
	
	## Right, from the players point of reference
	RIGHT = 1,
	}

## Used to store the [Player] as [Node2D]
var player_node : Node2D = null 

## Used to store the [Enemy] as [Node2D]
var enemy_node : Node2D = null
