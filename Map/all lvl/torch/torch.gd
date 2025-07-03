extends StaticBody2D

@export var explosion : PackedScene
@onready var anim_spr: AnimatedSprite2D = $anim_spr

var health = 10

func _process(delta: float) -> void:
	update_animation()

func take_damage(amount: int, source: Node):
	health -= amount
	if health <= 0:
		die()
		
func die():
	if explosion:
		var explosion_fx = explosion.instantiate()
		explosion_fx.global_position = global_position
		get_tree().current_scene.add_child(explosion_fx)
	queue_free()

func update_animation():
	anim_spr.play("default")
