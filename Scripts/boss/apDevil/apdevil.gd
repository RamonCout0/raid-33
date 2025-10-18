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
@onready var var_animated_sprite = $AnimatedSprite2D # RENOMEADO AQUI PARA EVITAR CONFLITO
@onready var move_target_left = $MoveTargetLeft
@onready var move_target_right = $MoveTargetRight
@onready var collision_shape = $CollisionShape2D # Adicionado para controlar a colisão

var current_move_target = null

# --- Máquina de Estados ---
enum BossState {
	IDLE,
	PATTERN_1_TELEPORT_OUT, # NOVO: Desaparecer
	PATTERN_1_TELEPORT_IN,  # NOVO: Reaparecer
	PATTERN_1_SHOOT,
	PATTERN_2_HAND,
	PATTERN_3_STOMP,
	PATTERN_4_COMBO,
	DEAD
}
var current_state = BossState.IDLE

# --- Funções Iniciais ---
func _ready():
	print("Chefe: _ready() INICIADA.")
	add_to_group("boss")
	initialize_health_system()
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("CHEFE ERRO: Player não encontrado!")

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if var_animated_sprite: # Usando o novo nome
		var_animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
		print("Chefe: Sinal 'animation_finished' conectado com sucesso.")
	else:
		print("CHEFE ERRO CRÍTICO: Nó 'AnimatedSprite2D' não encontrado!")

	start_attack_cooldown(3.0)
	print("Chefe: Pronto e esperando.")

func initialize_health_system():
	current_health = max_health
	EventBus.boss_max_health_set.emit(max_health, health_per_segment)
	print("Chefe: Sistema de vida inicializado. HUD deve aparecer.")

# --- Loop Principal (O "Cérebro" do boss) ---
func _physics_process(delta):
	if player == null or current_state == BossState.DEAD:
		return
		
	# Gravidade
	if not is_on_floor():
		# CORREÇÃO: Desliga a gravidade para TODOS os estados do Padrão 1
		if current_state != BossState.PATTERN_1_TELEPORT_OUT and \
		   current_state != BossState.PATTERN_1_TELEPORT_IN and \
		   current_state != BossState.PATTERN_1_SHOOT:
			
			velocity.y += gravity * delta
	match current_state:
		BossState.IDLE:
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		# --- NOVO PADRÃO 1 ---
		BossState.PATTERN_1_TELEPORT_OUT:
			# Não se move, só espera o await (o _on_animation_finished não vai rodar aqui)
			pass 
		BossState.PATTERN_1_TELEPORT_IN:
			# Não se move, só espera o await
			pass
		# --- FIM NOVO PADRÃO 1 ---
		
		BossState.PATTERN_1_SHOOT:
			is_immune = false
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		BossState.PATTERN_2_HAND:
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		BossState.PATTERN_3_STOMP:
			var direction_x = (player.global_position.x - global_position.x)
			if abs(direction_x) > 10: 
				velocity.x = STOMP_SPEED * sign(direction_x)
			else:
				velocity.x = 0
			
			if is_on_floor():
				print("DEBUG: Chefe tocou o chão! Saindo do Padrão 3...")
				change_state(BossState.IDLE)
				start_attack_cooldown(randf() * (6.0 - 4.0) + 4.0)
		
		BossState.PATTERN_4_COMBO:
			velocity.x = move_toward(velocity.x, 0, 100 * delta)
		
		BossState.DEAD:
			velocity = Vector2.ZERO
	
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
	print("DEBUG: Sinal 'animation_finished' DISPARADO! Estado atual: ", current_state)
	
	# Esta é a lógica de SAÍDA dos ataques baseados em animação
	if current_state == BossState.PATTERN_1_SHOOT or \
	   current_state == BossState.PATTERN_2_HAND or \
	   current_state == BossState.PATTERN_4_COMBO:
		
		print("DEBUG: Animação de ataque terminou. Voltando para IDLE.")
		change_state(BossState.IDLE)
		start_attack_cooldown(randf() * (5.0 - 3.0) + 3.0)

func _on_attack_timer_timeout():
	print("DEBUG: Timer de ataque disparou!")
	if current_state == BossState.IDLE:
		choose_next_attack()

func choose_next_attack():
	var next_attack = randi_range(1, 4)
	print("DEBUG: Sorteando próximo ataque... Resultado: ", next_attack)
	
	match next_attack:
		1:
			change_state(BossState.PATTERN_1_TELEPORT_OUT) # Mudei aqui
		2:
			change_state(BossState.PATTERN_2_HAND)
		3:
			change_state(BossState.PATTERN_3_STOMP)
		4:
			change_state(BossState.PATTERN_4_COMBO)

func change_state(new_state):
	current_state = new_state
	print("Chefe: MUDANDO ESTADO para: ", current_state)
	
	match new_state:
		BossState.IDLE:
			var_animated_sprite.play("idle")
			is_immune = false
			collision_shape.disabled = false # Garante que a colisão está ativa
		
		# --- NOVO PADRÃO 1 LÓGICA ---
		BossState.PATTERN_1_TELEPORT_OUT:
			is_immune = true
			collision_shape.disabled = true # Desabilita a colisão para não empurrar
			var_animated_sprite.visible = false # Faz o chefe sumir
			
			# Escolhe o alvo mais longe do player
			if abs(global_position.x - move_target_left.global_position.x) > abs(global_position.x - move_target_right.global_position.x):
				current_move_target = move_target_left
			else:
				current_move_target = move_target_right
			
			# Espera um pequeno tempo "invisível" antes de reaparecer
			await get_tree().create_timer(0.5).timeout 
			change_state(BossState.PATTERN_1_TELEPORT_IN)
			
		BossState.PATTERN_1_TELEPORT_IN:
			global_position = current_move_target.global_position # Teleporta!
			var_animated_sprite.visible = true # Faz o chefe aparecer
			# Toca uma animação de "reaparecer" se tiver uma
			var_animated_sprite.play("move_fast_animation") # Usando move_fast por enquanto
			
			# Espera um pequeno tempo para o reaparecimento (ou até animação terminar)
			await get_tree().create_timer(0.5).timeout
			change_state(BossState.PATTERN_1_SHOOT) # Agora vai para o ataque de tiro
		# --- FIM NOVO PADRÃO 1 LÓGICA ---
		
		BossState.PATTERN_1_SHOOT:
			var_animated_sprite.play("shoot_animation")
			# --- COLOQUE SEU CÓDIGO DE ATIRAR AQUI ---
			
		BossState.PATTERN_2_HAND:
			var_animated_sprite.play("hand_attack_animation")
			
		BossState.PATTERN_3_STOMP:
			print("DEBUG: EXECUTANDO PULO! (JUMP_FORCE)")
			velocity.y = JUMP_FORCE
			var_animated_sprite.play("stomp_jump_animation")
			
		BossState.PATTERN_4_COMBO:
			var_animated_sprite.play("hand_combo_animation")
			
		BossState.DEAD:
			var_animated_sprite.play("death")
			is_immune = true
			collision_shape.disabled = true
			await var_animated_sprite.animation_finished
			queue_free()

func start_attack_cooldown(duration):
	print("Chefe: Iniciando cooldown de ataque por ", duration, " segundos.")
	attack_timer.wait_time = duration
	attack_timer.one_shot = true
	attack_timer.start()
