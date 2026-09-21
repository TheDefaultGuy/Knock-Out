extends Button
@export var i := self
var privater_dictionary = {"sus":10}
@export var dictionary = {"saps":^"aaaaaaaaaaaaaaa"}

var hiddenVar = 1
@export var n_float := 0.0
@export var n_int := 1
@export var dictionary3 := {
			"Dictionary":"example",
			"string":"foo baa",
			"stringname":&"name",
			"path":^"/yellowbrick/road",
			"answer":42,
			"vector":Vector3(10,1,3),
			false:"true",
			67:"bruh",
			"67":"21",
			'mix':array,
			"abc":["a",'b','c','d','e','f','g'],
			10:[1,2,3,4,5,6,7,8,9,10],
			"English Dictionary":{
				"Cool":"this",
				"mama":"mima",
				"stuart":4,
				"true":false,
				"egg":{
					"egg":"nog",
					"yolk":{
						"folk":{
							"e":"a"
						}
					}
				}
				},
		}
@export_enum("apple","pear","orange") var string_enum := ""
@export_flags_2d_navigation() var example_layers:int = 10
@export_flags("do","re","mi:5","fa","sol","foo:100","baa") var bitflags:int = 5
@export_flags("Fire", "Water", "Earth", "Wind") var spell_elements = 0

@export var texture_A:Texture2D
@export var texture_null:Texture2D
@export_group("Arrays")
@export var array = ["a",1,2,3,"b","c"]
@export var packedString :PackedStringArray = ["a","b","c","add","ssb","ccc"]
@export var b :PackedByteArray = [1,2,34,4,5,]
@export var c :PackedColorArray = [Color.AQUAMARINE,Color.REBECCA_PURPLE]
@export var f :PackedFloat32Array = [2.3]
@export var ff :PackedFloat64Array = [1.5]
@export var ii :PackedInt32Array = [2]
@export var iii :PackedInt64Array = [1]
@export var v2 :PackedVector2Array = [Vector2()]
@export var v3 :PackedVector3Array = [Vector3()]
@export var v4 :PackedVector4Array = [Vector4()]

@export_group("Vectors")
@warning_ignore("unused_private_class_variable")
@export var _Vector2i = Vector2i()
@warning_ignore("unused_private_class_variable")
@export var _Vector3 = Vector3()
@warning_ignore("unused_private_class_variable")
@export var _Vector4 = Vector4()


@export_group("Unsupported")
@export var aabb:AABB
@export var basis:Basis
@export var transform2d:Transform2D
@export var transform3d:Transform3D
@export var rect2:Rect2
@export var quaternion:Quaternion
#@export_tool_button("hello_world tool button","AABB") var bnt := hello_world
#func hello_world(): print("hello_world") 


func _pressed() -> void:
	%AnyObjectInspector.set_selected_object(self)
func _ready() -> void:
	texture_A = %TextureRect.texture
	if not Engine.is_editor_hint():
		#%AnyObjectInspector.set_selected_object(self)
		_pressed()

func _on_button_2_pressed() -> void:
	%AnyObjectInspector.set_selected_object(
		dictionary3
	)
	#pass


func _on_button_3_pressed() -> void:
	%AnyObjectInspector.set_selected_object(
		null
	)


func _on_button_4_pressed() -> void:
	%AnyObjectInspector.set_selected_object(
		array
	)


func _on_button_5_pressed() -> void:
	%AnyObjectInspector.set_selected_object(
		1.0
	)


func _on_button_6_pressed() -> void:
	%AnyObjectInspector.set_selected_object(
		[dictionary3,dictionary,{},{'foo':'baa'},{"spinn":true}]
	)
