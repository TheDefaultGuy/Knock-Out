@abstract class_name ArrayStringFormatter extends RefCounted
## Abstract class with static functions that handle formatting arrays or strings.

## Short little function that removes any duplicate entries in an Array.
static func array_remove_duplicates(array: Array) -> Array:
	var output : Array = []
	
	# Iterates through each element of the array
	for element in array: 
		
		# Checks if the element isn't in the output Array.
		if not element in output: 
			
			# Adds the element to the output Array if it isn't.
			output.append(element) 
			
			continue
			
	# Returns the finished output array without duplicates
	return output

## Short little function that removes any empty entries in an Array.
static func array_remove_empty_entries(array: Array) -> Array:
	var output : Array = []
	
	# Iterates through each element of the array
	for element in array:
		
		# Checks if the element isn't an empty string or null.
		if element != "" or element != null:
			
			# Adds the element to the output Array if it isn't.
			output.append(element)
			
			continue
			
	# Returns the finished output array without empty entries.
	return output
	
## Removes the library name/preffix from the incoming animation so that it can be compared against the ones listed above.
static func remove_animation_library_preffix(animation : String) -> String:
	
	# Counts the number of slashes "/" in the string.
	var number_of_preffixes = animation.count("/", 0, 0) 
	
	# Returns the whole string after the given number of slashes "/"
	return animation.get_slice("/",number_of_preffixes)
