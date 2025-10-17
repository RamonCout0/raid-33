extends CharacterBody2D

# Vamos agrupar o chefe para que o projétil saiba com quem colidiu.
func _ready():
	add_to_group("boss")

# Variáveis para a vida do chefe.
@export var max_health = 8500.0 # Ex: ~304k de um MMORPG (usando valores menores)
var current_health: float

# Variáveis para o sistema de barras.
@export var health_per_segment = 50.0 # Quantos pontos de vida cada barra representa

func initialize_health():
	current_health = max_health
	# Avisa a UI para criar as barras de vida.
	# Enviamos a vida máxima e o valor de cada segmento.
	EventBus.boss_max_health_set.emit(max_health, health_per_segment)

func take_damage(amount):
	current_health -= amount
	if current_health < 0:
		current_health = 0
		print("Chefe está emitindo o sinal. Vida atual: ", current_health)
	EventBus.boss_health_updated.emit(current_health)
	
	# Avisa a UI que a vida mudou.
	EventBus.boss_health_updated.emit(current_health)
	print("Chefe tomou dano! Vida atual: ", current_health)
	
	if current_health == 0:
		# Lógica de derrota do chefe aqui.
		queue_free() # Por enquanto, ele apenas desaparece.
