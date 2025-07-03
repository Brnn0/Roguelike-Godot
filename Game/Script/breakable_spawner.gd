extends Node2D

@export var breakable_scenes: Array[PackedScene] = []
@export var max_breakable: int = 4
@export var spawn_interval: float = 0.5
@onready var breakable_spawn_area: CollisionShape2D = $CollisionShape2D

var current_breakable: Array = []

func _ready():
	spawn_breakables()

func spawn_breakables() -> void:
	while current_breakable.size() < max_breakable:
		var breakable_scene = breakable_scenes.pick_random()
		var breakable = breakable_scene.instantiate()
		breakable.global_position = get_random_position_in_area()

		# Adiciona como filho da sala
		get_parent().add_child.call_deferred(breakable)
		breakable.add_to_group("Breakable")

		# Gerenciar quando for destruído
		current_breakable.append(breakable)
		breakable.connect("tree_exited", Callable(self, "_on_breakable_removed").bind(breakable))

		await get_tree().create_timer(spawn_interval).timeout

func _on_breakable_removed(breakable):
	current_breakable.erase(breakable)

func get_random_position_in_area() -> Vector2:
	var shape = breakable_spawn_area.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var random_offset = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		return global_position + random_offset
	else:
		push_error("Shape não é um RectangleShape2D!")
		return global_position
