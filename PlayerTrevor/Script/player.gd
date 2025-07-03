extends CharacterBody2D

# ------------------------- NODES E EXPORTS -------------------------
@onready var sprite_trevor: Sprite2D = $SpriteTrevor
@onready var animation: AnimationPlayer = $animation
@onready var dash_ghost_timer: Timer = $DashGhostTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var whip: Area2D = $whip
@onready var hurtbox: Area2D = $hurtbox
@onready var dash_timer: Timer = $DashTimer
@onready var collision_player: CollisionShape2D = $CollisionPlayer
@onready var collision_hurtbox: CollisionShape2D = $hurtbox/CollisionHurtbox
@export var dash_ghost_node: PackedScene
@export var SPEED: float = 100.0

# ---------------------------- VARIÁVEIS ----------------------------
var move_speed = SPEED
var can_dash = true
var last_move_direction := Vector2.RIGHT
var char_direction: Vector2
var can_move = true:
	set(value):
		can_move = value
		move_speed = SPEED if value else 0.0

var is_dashing = false
var is_attacking = false:
	set(value):
		is_attacking = value
		whip.visible = value

# ----------------------- SISTEMA DE COMBO --------------------------
var attack_index := 0
var can_continue_attack := false
var queue_next_attack := false

# ------------------------- VIDA E DANO -----------------------------
var is_dead = false
var is_hit = false
var max_health : int = 100
var health = max_health
var is_invulnerable = false

# -------------------------- KNOCKBACK ------------------------------
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 800.0

# ============================== READY ==============================
func _ready() -> void:
	GameManager.player = self
	GameManager.ui = get_tree().get_current_scene().get_node("Ui")
	GameManager.ui.update_health_bar(health, max_health)

# ======================= PROCESSO PRINCIPAL =======================
func _physics_process(delta: float) -> void:
	# Movimento
	char_direction.x = Input.get_axis("move_left", "move_right")
	char_direction.y = Input.get_axis("move_up", "move_down")
	char_direction = char_direction.normalized()

	# Salvar última direção
	if char_direction != Vector2.ZERO:
		last_move_direction = char_direction

	# Virar sprite (se não estiver atacando)
	if not is_attacking:
		if char_direction.x > 0:
			sprite_trevor.scale.x = abs(sprite_trevor.scale.x)
			whip.scale.x = abs(whip.scale.x)
		elif char_direction.x < 0:
			sprite_trevor.scale.x = -abs(sprite_trevor.scale.x)
			whip.scale.x = -abs(whip.scale.x)

	# Movimento + knockback
	var move_vector = Vector2.ZERO
	if char_direction and can_move and not is_dashing:
		move_vector = char_direction * move_speed

	move_vector += knockback_velocity
	velocity = move_vector
	move_and_slide()

	# Reduz knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	# Atualiza animação
	update_animation()

# ============================ INPUT ================================
func _input(event):
	if event.is_action_pressed("dash"):
		dash()
	elif event.is_action_pressed("attack"):
		start_attack()

# ========================= SISTEMA DE ATAQUE =======================
func start_attack():
	if not is_attacking:
		is_attacking = true
		can_move = false
		attack_index = 1
		queue_next_attack = false
		can_continue_attack = false
		play_attack_animation(attack_index)
	elif can_continue_attack:
		queue_next_attack = true

func play_attack_animation(index: int):
	var anim_name = "Atk" + str(index)
	animation.play(anim_name)
	can_continue_attack = false
	apply_attack_slide()

func _on_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("Atk"):
		if queue_next_attack and attack_index < 3:
			attack_index += 1
			queue_next_attack = false
			play_attack_animation(attack_index)
		else:
			reset_attack()

func enable_next_attack():
	can_continue_attack = true
	attack_timer.start(0.5)

func _on_attack_timer_timeout():
	if is_attacking and not queue_next_attack:
		reset_attack()

func reset_attack():
	is_attacking = false
	can_move = true
	can_continue_attack = false
	queue_next_attack = false
	attack_index = 0

func apply_attack_slide():
	var slide_distance = 10
	var direction = sign(sprite_trevor.scale.x)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position:x", position.x + slide_distance * direction, 0.15)

# ============================ DASH ================================
func dash():
	if not can_dash or is_dashing:
		return
	if is_attacking:
		reset_attack()

	is_dashing = true
	can_dash = false
	dash_ghost_timer.start()
	dash_timer.start()
	GameManager.ui.start_dash_cooldown(dash_timer.wait_time)
	
	# Direção do dash
	var dash_dir = velocity.normalized()
	if dash_dir == Vector2.ZERO:
		dash_dir = last_move_direction.normalized()

	# Configurações
	var dash_speed = 200.0
	var dash_duration = 0.35
	var dash_time = 0.0

	# 🔥 Durante o dash, ignora inimigos
	var original_mask = collision_mask
	# Supondo que mask padrão é World (3) + Enemy (2) = 0b110 = 6
	# Remove Enemy (Layer 2 -> bit 2 -> valor 0b10 = 2)
	collision_mask &= ~2  # Desativa colisão com inimigos (Layer 2)

	while dash_time < dash_duration:
		var delta = get_process_delta_time()
		var collision = move_and_collide(dash_dir * dash_speed * delta)
		if collision:
			# Se colidir com parede (Layer 3), para o dash
			break
		dash_time += delta
		await get_tree().process_frame
	
	# 🔥 Restaura a mask original
	collision_mask = original_mask

	dash_ghost_timer.stop()
	is_dashing = false

func _on_dash_timer_timeout() -> void:
	can_dash = true
	GameManager.ui.start_dash_cooldown(dash_timer.wait_time)

func add_ghost():
	var ghost = dash_ghost_node.instantiate()
	ghost.set_property(position, sprite_trevor.scale)
	get_tree().current_scene.add_child(ghost)

func _on_dash_ghost_timer_timeout() -> void:
	add_ghost()

# ========================= ANIMAÇÕES ==============================
func update_animation():
	if is_attacking or is_hit or is_dead:
		return
	if is_dashing:
		animation.play("Dash")
	elif velocity == Vector2.ZERO:
		animation.play("Idle")
	else:
		animation.play("Walk")

# ==================== COLISÃO COM WHIP ===========================
func _on_whip_body_entered(body: Node) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Breakable"):
		var damage = 0
		match attack_index:
			1, 2:
				damage = 10
			3:
				damage = 20
		body.take_damage(damage, self)

# ========================= RECEBER DANO ===========================
func take_damage(amount: int, source: Node):
	if is_invulnerable or is_dashing:
		return
	is_attacking = false
	animation.play("Hit")
	health -= amount
	GameManager.ui.update_health_bar(health, max_health)
	apply_knockback(source)
	start_invulnerability()
	if health <= 0:
		die()
	else:
		play_hit()

func play_hit():
	is_hit = true
	can_move = false
	animation.play("Hit")
	await animation.animation_finished
	is_hit = false
	can_move = true

func apply_knockback(source: Node):
	var direction = (global_position - source.global_position).normalized()
	var knockback_strength = 200.0
	knockback_velocity = direction * knockback_strength

func start_invulnerability(duration: float = 1.5):
	if is_invulnerable:
		return
	is_invulnerable = true
	var blink_timer = Timer.new()
	blink_timer.wait_time = 0.1
	blink_timer.one_shot = false
	add_child(blink_timer)
	blink_timer.start()
	blink_timer.timeout.connect(func ():
		sprite_trevor.visible = not sprite_trevor.visible
	)
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
	sprite_trevor.visible = true
	blink_timer.stop()
	blink_timer.queue_free()

func die():
	queue_free()

# ================== COLISÃO COM INIMIGOS =========================
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var damage = 10
		if body.has_method("get_damage"):
			damage = body.get_damage()
		take_damage(damage, body)
