extends CharacterBody2D

# =============================================================================
# ================================ NODES ======================================
# =============================================================================
@onready var player = GameManager.player
@onready var sprite_zombie: Sprite2D = $sprite_zombie
@onready var animation: AnimationPlayer = $animation
@onready var hurtbox: Area2D = $hurtbox  # Área que detecta o player para causar dano
@onready var hit_flash_animation: AnimationPlayer = $hit_flash_animation
@onready var dmg_nmbr_position: Node2D = $DmgNmbrPosition
@onready var healthbar: ProgressBar = $Healthbar

# =============================================================================
# ============================ ATRIBUTOS ======================================
# =============================================================================
@export var blood_explosion : PackedScene
@export var move_speed: float = 30.0
@export var max_health : int = 30
@export var damage: int = 10   # ⚠️ Pode ser configurado por inimigo
var is_hit = false
var can_act = false   # 🔥 Controla se o inimigo pode começar a agir
var health = max_health

# Configurações para evitar agrupamento
@export var separation_distance: float = 24.0
@export var separation_strength: float = 100.0

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 500.0

# =============================================================================
# =============================== READY =======================================
# =============================================================================
func _ready():
	play_spawn_animation()
	healthbar.init_health(health)
	
func play_spawn_animation():
	if animation.has_animation("spawn"):
		animation.play("spawn")
		animation.connect("animation_finished", Callable(self, "_on_spawn_animation_finished"))
	else:
		can_act = true

func _on_spawn_animation_finished(anim_name):
	if anim_name == "spawn":
		can_act = true
		animation.disconnect("animation_finished", Callable(self, "_on_spawn_animation_finished"))

# =============================================================================
# ========================= PROCESSO PRINCIPAL ================================
# =============================================================================
func _physics_process(delta):
	if not player or not can_act:
		return
	
	# Direção para o player
	var move_direction = (player.global_position - global_position).normalized()
	
	# Calcula separação para evitar agrupamento dos inimigos
	var separation = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("Enemy"):
		if other == self:
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_distance and dist > 0:
			separation -= (other.global_position - global_position).normalized() * (separation_distance - dist)
	
	# Combina direção para o player com separação
	var final_direction = (move_direction + separation * (separation_strength / 100.0)).normalized()
	
	# Aplica velocidade com knockback
	var move_vector = final_direction * move_speed
	move_vector += knockback_velocity
	
	velocity = move_vector
	move_and_slide()
	
	# Reduz knockback progressivamente
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	
	# Atualiza animação e sprite
	update_animation()
	update_sprite_direction()

# =============================================================================
# ========================= CONTROLE DE SPRITE ================================
# =============================================================================
func update_sprite_direction():
	if is_hit == false:
		if velocity.x > 0:
			sprite_zombie.scale.x = abs(sprite_zombie.scale.x)
		elif velocity.x < 0:
			sprite_zombie.scale.x = -abs(sprite_zombie.scale.x)

# =============================================================================
# ========================== SISTEMA DE ANIMAÇÃO ==============================
# =============================================================================
func update_animation():
	if velocity.length() > 0.5:
		animation.play("walk")

# =============================================================================
# =========================== RECEBER DANO ====================================
# =============================================================================
func take_damage(amount: int, source: Node):
	
	health -= amount
	healthbar.health = health
	DmgNumberManager.display_number(amount, dmg_nmbr_position.global_position)
	apply_knockback(source)
	HitsStopManager.hit_stop_super_slow_short()
	if health <= 0:
		die()
		
	hit_flash_animation.play("hitflash")

func apply_knockback(source: Node):
	var direction = (global_position - source.global_position).normalized()
	var knockback_strength = 150.0
	knockback_velocity = direction * knockback_strength

func die():
	if blood_explosion:
		var blood = blood_explosion.instantiate()
		blood.global_position = global_position
		get_tree().current_scene.add_child(blood)
	queue_free()

# =============================================================================
# ======================= CAUSAR DANO AO PLAYER ===============================
# =============================================================================
func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.take_damage(damage, self)

# =============================================================================
# =========================== GETTERS OPCIONAIS ===============================
# =============================================================================
func get_damage() -> int:
	return damage
