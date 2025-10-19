extends CharacterBody2D

# --- Variáveis de Vida ---
@export var max_health: float = 8500.0
var current_health: float
@export var health_per_segment: float = 50.0

# --- Variáveis do Boss (IA) ---
var is_immune = false
var player = null

# --- Variáveis de Física e Movimento ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var MOVE_SPEED: float = 300.0
var JUMP_FORCE: float = -400.0
var STOMP_SPEED: float = 100.0

# --- Referências dos Nós ---
@onready var attack_timer = $AttackTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var move_target_left = $MoveTargetLeft
@onready var move_target_right = $MoveTargetRight
@onready var collision_shape = $CollisionShape2D

var current_move_target = null

# --- Máquina de Estados ---
enum BossState {
	IDLE,
	PATTERN_1_TELEPORT_OUT,
	PATTERN_1_TELEPORT_IN,
	PATTERN_1_SHOOT,
	PATTERN_2_HAND,
	PATTERN_3_STOMP,
	PATTERN_4_COMBO,
	DEAD
}
var current_state = BossState.IDLE

# --- Funções Iniciais ---
func _ready():
	add_to_group("boss")
	initialize_health_system()
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("CHEFE ERRO: Player não encontrado!") # Melhor que print

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	
	start_attack_cooldown(3.0)

func initialize_health_system():
	current_health = max_health
	EventBus.boss_max_health_set.emit(max_health, health_per_segment)

# --- Loop Principal (Simplificado) ---
func _physics_process(delta):
	if player == null or current_state == BossState.DEAD:
		return
		
	# 1. Aplicar Gravidade (padrão)
	# A gravidade só é desligada nos estados de teleporte e tiro
	if not is_on_floor():
		if current_state != BossState.PATTERN_1_TELEPORT_OUT and \
		   current_state != BossState.PATTERN_1_TELEPORT_IN and \
		   current_state != BossState.PATTERN_1_SHOOT:
			
			velocity.y += gravity * delta
	
	# 2. Lógica de Estado (Simplificada)
	match current_state:
		# Estados que ficam parados ou só aplicam fricção
		BossState.IDLE, BossState.PATTERN_2_HAND, BossState.PATTERN_4_COMBO:
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		# Estados de teleporte (sem movimento)
		BossState.PATTERN_1_TELEPORT_OUT, BossState.PATTERN_1_TELEPORT_IN:
			velocity = Vector2.ZERO 
		
		# Estado de tiro (flutua, mas aplica fricção)
		BossState.PATTERN_1_SHOOT:
			is_immune = false
			velocity.y = 0 
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		# Estado de Pulo (controla X e Y)
		BossState.PATTERN_3_STOMP:
			var direction_x = (player.global_position.x - global_position.x)
			if abs(direction_x) > 10:
				velocity.x = STOMP_SPEED * sign(direction_x)
			else:
				velocity.x = 0
			
			if is_on_floor():
				change_state(BossState.IDLE)
				start_attack_cooldown(randf() * (6.0 - 4.0) + 4.0)
		
		BossState.DEAD:
			velocity = Vector2.ZERO
	
	# 3. Mover
	move_and_slide()

# --- Funções de Lógica e Dano ---
func take_damage(amount):
	if is_immune or current_state == BossState.DEAD:
		return
		
	current_health -= amount
	if current_health < 0:
		current_health = 0
		
	EventBus.boss_health_updated.emit(current_health)
	
	if current_health == 0:
		change_state(BossState.DEAD)

# --- Funções de Controle (Sinais) ---
func _on_animated_sprite_animation_finished():
	# Esta é a lógica de SAÍDA dos ataques baseados em animação
	# Usar 'match' é mais limpo que um 'if' longo
	match current_state:
		BossState.PATTERN_1_SHOOT, BossState.PATTERN_2_HAND, BossState.PATTERN_4_COMBO:
			change_state(BossState.IDLE)
			start_attack_cooldown(randf() * (5.0 - 3.0) + 3.0)

func _on_attack_timer_timeout():
	if current_state == BossState.IDLE:
		choose_next_attack()

func choose_next_attack():
	var next_attack = randi_range(1, 4)
	
	match next_attack:
		1:
			change_state(BossState.PATTERN_1_TELEPORT_OUT)
		2:
			change_state(BossState.PATTERN_2_HAND)
		3:
			change_state(BossState.PATTERN_3_STOMP)
		4:
			change_state(BossState.PATTERN_4_COMBO)

func change_state(new_state):
	current_state = new_state
	
	match new_state:
		BossState.IDLE:
			animated_sprite.play("idle")
			is_immune = false
			collision_shape.disabled = false
		
		BossState.PATTERN_1_TELEPORT_OUT:
			is_immune = true
			collision_shape.disabled = true
			animated_sprite.visible = false
			
			if abs(global_position.x - move_target_left.global_position.x) > abs(global_position.x - move_target_right.global_position.x):
				current_move_target = move_target_left
			else:
				current_move_target = move_target_right
			
			await get_tree().create_timer(0.5).timeout
			change_state(BossState.PATTERN_1_TELEPORT_IN)
			
		BossState.PATTERN_1_TELEPORT_IN:
			global_position = current_move_target.global_position
			animated_sprite.visible = true
			animated_sprite.play("move_fast_animation")
			
			await get_tree().create_timer(0.5).timeout
			change_state(BossState.PATTERN_1_SHOOT)
		
		BossState.PATTERN_1_SHOOT:
			animated_sprite.play("shoot_animation")
			# --- COLOQUE SEU CÓDIGO DE ATIRAR AQUI ---
			
		BossState.PATTERN_2_HAND:
			animated_sprite.play("hand_attack_animation")
			
		BossState.PATTERN_3_STOMP:
			velocity.y = JUMP_FORCE
			animated_sprite.play("stomp_jump_animation")
			
		BossState.PATTERN_4_COMBO:
			animated_sprite.play("hand_combo_animation")
			
		BossState.DEAD:
			animated_sprite.play("death")
			is_immune = true
			# CORREÇÃO: Usa call_deferred para evitar bugs de física
			collision_shape.call_deferred("set_disabled", true)
			await animated_sprite.animation_finished
			queue_free()

func start_attack_cooldown(duration):
	attack_timer.wait_time = duration
	attack_timer.one_shot = true
	attack_timer.start()
