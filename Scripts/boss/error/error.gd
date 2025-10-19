extends CharacterBody2D

# --- Variáveis de Vida (Igual ao outro boss) ---
@export var max_health: float = 5000.0 # Vida diferente
var current_health: float
@export var health_per_segment: float = 50.0

# --- Variáveis do Boss (IA) ---
var is_immune = false
var player = null

# --- Variáveis de Física ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Referências dos Nós ---
@onready var attack_timer = $AttackTimer
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# --- NOVO: Conecte sua cena de projétil aqui ---
@export var projectile_scene: PackedScene

# --- Máquina de Estados (SIMPLIFICADA) ---
enum BossState {
	IDLE,
	ATTACK_1, # Ataque de projétil 1
	ATTACK_2, # Ataque de projétil 2
	ATTACK_3, # Ataque de projétil 3
	DEAD
}
var current_state = BossState.IDLE

# --- Funções Iniciais ---
func _ready():
	add_to_group("boss") # IMPORTANTE!
	initialize_health_system()
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("CHEFE ERRO: Player não encontrado!")

	attack_timer.timeout.connect(_on_attack_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	
	start_attack_cooldown(3.0)

# Esta função FAZ A HUD FUNCIONAR!
func initialize_health_system():
	current_health = max_health
	EventBus.boss_max_health_set.emit(max_health, health_per_segment)

# --- Loop Principal (MUITO SIMPLES) ---
func _physics_process(delta):
	if player == null or current_state == BossState.DEAD:
		return
		
	# Este chefe só fica parado e sofre gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Fricção simples
	velocity.x = move_toward(velocity.x, 0, 100 * delta)
	
	move_and_slide()

# --- Função de Dano (Igual) ---
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
	# Quando qualquer animação de ataque terminar, volte ao IDLE
	match current_state:
		BossState.ATTACK_1, BossState.ATTACK_2, BossState.ATTACK_3:
			change_state(BossState.IDLE)
			start_attack_cooldown(randf() * (4.0 - 2.0) + 2.0)

func _on_attack_timer_timeout():
	if current_state == BossState.IDLE:
		choose_next_attack()

# --- Lógica de IA (SIMPLIFICADA) ---
func choose_next_attack():
	# Sorteia um número de 1 a 3
	var next_attack = randi_range(1, 3)
	
	match next_attack:
		1:
			change_state(BossState.ATTACK_1)
		2:
			change_state(BossState.ATTACK_2)
		3:
			change_state(BossState.ATTACK_3)

func change_state(new_state):
	current_state = new_state
	
	match new_state:
		BossState.IDLE:
			animated_sprite.play("idle")
			is_immune = false
			
		BossState.ATTACK_1:
			animated_sprite.play("attack_1") # Sua nova animação
			_shoot_projectile(1) # Ex: Atira 1 projétil
			
		BossState.ATTACK_2:
			animated_sprite.play("attack_2") # Sua nova animação
			_shoot_projectile(3) # Ex: Atira 3 projéteis
			
		BossState.ATTACK_3:
			animated_sprite.play("attack_3") # Sua nova animação
			_shoot_projectile(1, true) # Ex: Atira 1 projétil rápido
			
		BossState.DEAD:
			animated_sprite.play("death")
			is_immune = true
			collision_shape.call_deferred("set_disabled", true)
			await animated_sprite.animation_finished
			queue_free()

func start_attack_cooldown(duration):
	attack_timer.wait_time = duration
	attack_timer.one_shot = true
	attack_timer.start()

# --- NOVA FUNÇÃO DE TIRO ---
func _shoot_projectile(amount: int = 1, fast: bool = false):
	if not player or not projectile_scene:
		return

	for i in range(amount):
		var proj = projectile_scene.instantiate() as Area2D
		# Adiciona o projétil à cena principal (não ao chefe)
		get_tree().root.add_child(proj) 
		
		# Posição inicial (ex: na frente do chefe)
		proj.global_position = global_position + Vector2(50, 0)
		proj.look_at(player.global_position) # Mira no player
		
		if fast:
			proj.speed = 600 # Assume que o script do projétil tem 'speed'
		
		# Se atirar múltiplos, espera um pouco entre eles
		if amount > 1:
			await get_tree().create_timer(0.2).timeout
