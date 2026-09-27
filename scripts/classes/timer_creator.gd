@abstract class_name TimerCreator extends Node
## Creates a [Timer] with the given parameters, adds it as a child and then returns the finished timer.

## Function that helps create a custom [Timer]. Since it returns a [Timer], it should be used to assign a timer to a variable.
static func create_timer_and_add_as_child(timer_name : String, one_shot : bool, wait : float, autostart : bool, calling_node : Node) -> Timer:
	
	# Creates a new timer node
	var created_timer = Timer.new()
	
	# Names the timer so that it can be readable in the remote tab.
	created_timer.name = str(timer_name)
	
	# Sets the one shot parameter
	created_timer.one_shot = one_shot
	
	# Sets the wait time of the timer
	created_timer.wait_time = max(wait, 1.0) # Makes sure it's not zero.
	
	# Sets the autostart of the timer
	created_timer.autostart = autostart
	
	# Adds the timer as a child of the node that called the function.
	# Call defered because some components and states need it to be defered some some stupid reason.
	calling_node.add_child.call_deferred(created_timer)
	
	# Returns the final timer.
	return created_timer
