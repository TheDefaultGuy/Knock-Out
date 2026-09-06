class_name OneShotEffect extends CPUParticles2D

func _ready() -> void:
	self.finished.connect( func(): self.queue_free())
	self.emitting = true
