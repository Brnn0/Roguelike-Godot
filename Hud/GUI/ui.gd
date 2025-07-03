extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_bar: ProgressBar = $HealthBar/DamageBar
@onready var health_text: Label = $HealthBar/HealthText
@onready var timer: Timer = $HealthBar/Timer

@onready var dash_cooldown: TextureProgressBar = $DashCooldown

var max_health := 0
var health := 0
var prev_health := 0

var dash_cooldown_time := 0.0    # tempo total do cooldown do dash
var dash_cooldown_elapsed := 0.0 # tempo passado desde o dash usado

func _ready():
	GameManager.ui = self
	health_bar.max_value = max_health
	health_bar.value = health
	damage_bar.max_value = max_health
	damage_bar.value = health
	prev_health = health
	dash_cooldown_time = 1.0  # pode ser qualquer valor padrão, depois será atualizado
	dash_cooldown.value = dash_cooldown_time
	dash_cooldown.max_value = dash_cooldown_time

func update_health_bar(new_health: int, new_max_health: int) -> void:
	max_health = new_max_health
	health_bar.max_value = max_health
	damage_bar.max_value = max_health
	health = clamp(new_health, 0, max_health)
	health_bar.value = health
	health_text.text = "HP: %d / %d" % [health, max_health]
	if health < prev_health:
		damage_bar.value = prev_health
		timer.start()
	else:
		damage_bar.value = health
	prev_health = health

func _on_timer_timeout() -> void:
	damage_bar.value = health

# ------------------- DASH -------------------

func start_dash_cooldown(cooldown_time: float):
	dash_cooldown_time = cooldown_time
	dash_cooldown_elapsed = 0.0
	dash_cooldown.max_value = cooldown_time
	dash_cooldown.value = 0.0   # barra começa vazia ao usar o dash

func _process(delta):
	if not GameManager.player.can_dash:
		# Incrementa o tempo decorrido para preencher a barra progressivamente
		dash_cooldown_elapsed += delta
		if dash_cooldown_elapsed > dash_cooldown_time:
			dash_cooldown_elapsed = dash_cooldown_time
		dash_cooldown.value = dash_cooldown_elapsed
	else:
		# Dash disponível, barra cheia
		dash_cooldown.value = dash_cooldown_time
