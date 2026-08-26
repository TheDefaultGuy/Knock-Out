@icon("res://assets/icons/TdesignPersonalInformationFilled.svg")
## This is the base fighter info resource
##
## It stores information about the boxer,
## such as their name, height, weight, place of origin, profile picture, etc..
class_name FighterInfo extends Resource

@export var fighter_name : String
@export_multiline() var fighter_desc : String
@export var fighter_height : int
@export_custom(PROPERTY_HINT_NONE, "suffix:lbs") var fighter_weight : int
@export var fighter_portrait : CompressedTexture2D
