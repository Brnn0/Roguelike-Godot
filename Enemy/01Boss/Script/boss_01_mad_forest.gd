extends CharacterBody2D

@onready var player = GameManager.player
@onready var sprite_boss: Sprite2D = $sprite_boss
@onready var animation: AnimationPlayer = $animation
@onready var attack_area: Area2D = $attack_area
@onready var dmg_nmbr_position: Node2D = $DmgNmbrPosition
@onready var healthbar: ProgressBar = $CanvasLayer/Healthbar

@export var blood_explosion : PackedScene
@export var move_speed: float = 20.0
@export var damage: int = 20
@export var max_health : int = 300
@export var attack_distance: float = 40.0 # Distância para começar o ataque

var health = max_health
var is_attacking = false

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 500.0

func _ready() -> void:
	animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	healthbar.init_health(health)
	player = GameManager.player
	if player == null:
		player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):

	# Aplica knockback se houver
	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return

	# Se estiver atacando, não anda
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Calcula direção para o player
	var move_direction = (player.global_position - global_position).normalized()
	velocity = move_direction * move_speed

	# Flip do sprite
	if move_direction.x > 0:
		sprite_boss.scale.x = abs(sprite_boss.scale.x)
		attack_area.scale.x = abs(attack_area.scale.x)
	elif move_direction.x < 0:
		sprite_boss.scale.x = -abs(sprite_boss.scale.x)
		attack_area.scale.x = -abs(attack_area.scale.x)

	# Checar distância para atacar
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_distance:
		start_attack()

	move_and_slide()
	update_animation()

func update_animation():
	if is_attacking:
		animation.play("attack")
	elif velocity.length() > 0.5:
		animation.play("walk")

func start_attack():
	if not is_attacking:
		is_attacking = true
		velocity = Vector2.ZERO
		animation.play("attack")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		is_attacking = false


func take_damage(amount: int, source: Node):
	health -= amount
	healthbar.health = health
	DmgNumberManager.display_number(amount, dmg_nmbr_position.global_position)
	apply_knockback(source)
	if health <= 0:
		die()

func apply_knockback(source: Node):
	var direction = (global_position - source.global_position).normalized()
	var knockback_strength = 100.0
	knockback_velocity = direction * knockback_strength

func die():
	if blood_explosion:
		var blood = blood_explosion.instantiate()
		blood.global_position = global_position
		get_tree().current_scene.add_child(blood)
	queue_free()

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.take_damage(damage, self)
		HitsStopManager.hit_stop_slow_short()
		CameraManager.apply_shake(20.0)

func get_damage() -> int:
	return damage
