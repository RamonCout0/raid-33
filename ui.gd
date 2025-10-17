extends Control

# O caminho está correto, apontando para o filho direto.
@export var player_health_bar: TextureProgressBar

# A linha do chefe está comentada para não causar um novo erro.
# @onready var boss_health_bar = %BossHealthBar

func _ready():
	  # ADICIONE ESTA LINHA PARA TESTE
	print("A variável player_health_bar é: ", player_health_bar)

	EventBus.player_max_health_set.connect(set_player_max_health)
	EventBus.player_health_updated.connect(update_player_health)

func set_player_max_health(max_value):
	player_health_bar.max_value = max_value
	player_health_bar.value = max_value

func update_player_health(new_value):
	# A linha 21 é esta. Ela só funciona se a variável acima não for nula.
	player_health_bar.value = new_value
