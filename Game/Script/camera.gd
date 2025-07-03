extends Camera2D

var randomStrength : float = 30.0
var shakeFade : float = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength : float = 0.0

func _ready():
	CameraManager.register_camera(self)

func apply_shake(strength: float = 30.0):
	shake_strength = strength
	
func _process(delta: float) -> void:
	
	if shake_strength > 0:
		shake_strength = lerp(shake_strength,0.0,shakeFade * delta)
		
		offset = randomOffset()
		
func randomOffset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)
