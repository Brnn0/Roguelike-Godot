extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation: AnimationPlayer = $animation
@export var check_interval: float = 1 # frequência de checagem dos inimigos

var is_open: bool = false

func _ready():
	close()
	var spawner = get_tree().get_nodes_in_group("Enemy_Spawner")[0]
	spawner.connect("all_enemies_defeated", Callable(self, "open"))

func check_enemies() -> void:
	if get_tree().get_nodes_in_group("Enemy").is_empty():
		open()
	else:
		await get_tree().create_timer(check_interval).timeout
		check_enemies()

func open() -> void:
	if is_open:
		return
	is_open = true
	collision.disabled = true
	animation.play("open")

func close() -> void:
	is_open = false
	collision.disabled = false
	animation.play("closed")
