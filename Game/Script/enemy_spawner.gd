extends Node2D

signal all_enemies_defeated

@onready var enemy_spawn_area: CollisionShape2D = $CollisionShape2D
@export var enemy_scenes: Array[PackedScene] = []
@export var max_enemies: int = 6
@export var spawn_interval: float = 1.0

var current_enemies: Array = []
var total_spawned: int = 0

func _ready():
	spawn_enemies()

func spawn_enemies() -> void:
	while total_spawned < max_enemies:
		var enemy_scene = enemy_scenes.pick_random()
		var enemy = enemy_scene.instantiate()
		enemy.global_position = get_random_position_in_area()

		get_parent().add_child.call_deferred(enemy)
		enemy.add_to_group("Enemy")

		current_enemies.append(enemy)
		enemy.connect("tree_exited", Callable(self, "_on_enemy_removed").bind(enemy))

		total_spawned += 1  # 🔥 Conta quantos já foram spawnados

		await get_tree().create_timer(spawn_interval).timeout

func _on_enemy_removed(enemy):
	current_enemies.erase(enemy)
	print("Inimigo removido. Restam vivos: ", current_enemies.size())
	if current_enemies.is_empty() and total_spawned >= max_enemies:
		print("Todos os inimigos derrotados! Emitindo sinal.")
		emit_signal("all_enemies_defeated")

func get_random_position_in_area() -> Vector2:
	var shape = enemy_spawn_area.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var offset = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		return global_position + offset
	else:
		push_error("Shape não é um RectangleShape2D!")
		return global_position
