extends CharacterBody2D

# --- Variáveis de Movimento ---
@export var speed = 250.0
@export var jump_velocity = -450.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Variáveis de Combate ---
@export var max_health = 100
var current_health: int # Declara que esta variável será um inteiro

const BULLET_SCENE = preload("res://bullet.tscn")

# A função _ready é chamada uma vez quando o nó entra na cena.
func _ready():
	# Define a vida inicial do jogador.
	current_health = max_health
	# Avisa a UI (e qualquer outra parte do jogo) qual é a vida máxima do jogador.
	EventBus.player_max_health_set.emit(max_health)

func _physics_process(delta):
	# ... (toda a sua lógica de gravidade, pulo e movimento horizontal fica aqui, sem alterações)
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("shoot"):
		shoot()
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		$Sprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()

	# --- LÓGICA DE TESTE: Pressione T para tomar dano ---
	if Input.is_action_just_pressed("debug_damage"): # A tecla padrão é T
		take_damage(10)

func shoot():
	var bullet_instance = BULLET_SCENE.instantiate()
	var shoot_direction = Vector2.RIGHT
	if $Sprite2D.flip_h:
		shoot_direction = Vector2.LEFT
	bullet_instance.direction = shoot_direction
	bullet_instance.global_position = $Muzzle.global_position
	get_tree().root.add_child(bullet_instance)

# --- NOVA FUNÇÃO: Lógica para tomar dano ---
func take_damage(amount):
	current_health -= amount
	# Garante que a vida não fique negativa.
	if current_health < 0:
		current_health = 0

	# Transmite o sinal com o novo valor da vida.
	EventBus.player_health_updated.emit(current_health)
	print("Player tomou dano! Vida atual: ", current_health)

	if current_health == 0:
		print("Jogador derrotado!")
		# Aqui colocaremos a lógica de derrota mais tarde.
