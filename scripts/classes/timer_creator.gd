class_name TimerCreator extends Node
## Creates a [Timer] with the given parameters and returns the finished timer so that it can be added as a child.

## Function that helps create a custom [Timer]. Since it returns a [Timer], it should be used to assign a timer to a variable.
static func create_timer(timer_name : String, one_shot : bool, wait : float, autostart : bool) -> Timer:
	
	# Creates a new timer node
	var created_timer = Timer.new()
	
	# Names the timer so that it can be readable in the remote tab.
	created_timer.name = str(timer_name)
	
	# Sets the one shot parameter
	created_timer.one_shot = one_shot
	
	# Sets the wait time of the timer
	created_timer.wait_time = max(wait, 1.0) # Makes sure it's not zero.
	
	created_timer.autostart = autostart
	
	# Returns the final timer.
	return created_timer
