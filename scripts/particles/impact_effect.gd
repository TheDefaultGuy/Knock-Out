class_name ImpactEffect extends CPUParticles2D

func _ready() -> void:
	self.finished.connect( func(): self.queue_free())
	self.emitting = true
