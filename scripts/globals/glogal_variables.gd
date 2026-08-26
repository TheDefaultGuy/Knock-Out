extends Node
# Used to store the player's and enemy as Node2Ds
var player_node : Node2D = null 
var enemy_node : Node2D = null
# The heights for attacks.
# LOW is for lower body punches
# HIGH is for High head punches
# BOTH is for moves like crouching upper cuts that cover both ducking and blocking face.
enum height{LOW = 0, HIGH = 1, BOTH = 2}

# The range (X - axis) for attacks.
enum range{LEFT = -1, NEUTRAL = 0, RIGHT = 1}
