# AnyObjectInspector
Inspector tab in game.
The AnyObjectInspector is a at run time compatible version of the Inspector tab used in the editor.
Intended for editing objects in game. 
Simple to use just add the `any_object_inspector.tscn` scene and call `set_selected_object(object)` to have it edit any object at run time. 

Supports Objects like: Object, Resource, Node, Array and Dictionary.
 
Its Configurable so it can only show the vars you want; and non exported one as well (`show_nonExported_vars`).
## Features
- Edit any Object, Resource, Node, Array and Dictionary.
- Works just like the Godot editor.
- It can edit nested Objects.
- Pick what vars will show up (shows all `@export` by default)
- Fillter out by name or type (`allow_list`, `block_list`, `allow_type_list`, `block_type_list`)
- See non-exported variables (`show_nonExported_vars`)
- `@export_catagory` and `@export_group` compatible.
- Updates values from a live object with customizeable refresh rate (`refresh_rate`).
- Modify to your use case (as long its like `any_object_inspector.tscn` in shape).
- Optimized for performance.

## Var Type Compatiblity 
Its compatiple with these var types:

###### \* If intial value is not null. 
###### \*\* Only edit exising values.

|Type|Compatiblity|
|:---------|:---------|
|Object|✅\*|
|Nodes|✅\*|
|Resources|✅\*|
|Arrays|✅\*\*|
|PackedArrays (all variants)|✅\*\*|
|Dictionary|✅\*\*|
|Bool|✅|
|Floats|✅|
|Int|✅|
|Int (Flags)|✅|
|Int (Layers)|✅|
|Int (Enums)|✅|
|Colors|✅|
|Vector2, Vector2i|✅|
|Vector3, Vector3i|✅|
|Vector4, Vector4i|✅|
|Strings|✅|
|String (Enums)|✅|
|StringName|✅|
|StringName (Enums)|✅|
|Untyped vars|✅\*\*|
|RefCounted|✅ (Partial)|
|Self Refrences|Read Only|
|Null Objects|Read Only|
|Empty Arrays|Read Only|
|Empty Dictionary|Read Only|
|Callable|No `@tool_button`|
|AABB|❌|
|Basis|❌|
|Transform2D|❌|
|Transform3D|❌|
|Rect2|❌|
|Quaternion|❌|
|Signals|Out of scope of this addon|
## Known bugs
- Some of godot's built-in PackedArrays will fail to update. This is a known quirk of godot, no known solution as of yet. Hide any PackedArrays till then (`hide_packedArrays`).
###### Godot Addon, Single scene, Non editor addon 
