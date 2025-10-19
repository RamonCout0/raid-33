extends Control

@export var player_health_bar: TextureProgressBar

# @onready var boss_health_bar = %BossHealthBar

# --- NOVA VARIÁVEL ---
# Precisamos de uma variável para guardar a animação (Tween)
var health_tween: Tween

func _ready():
	print("A variável player_health_bar é: ", player_health_bar)

	EventBus.player_max_health_set.connect(set_player_max_health)
	EventBus.player_health_updated.connect(update_player_health)

func set_player_max_health(max_value):
	player_health_bar.max_value = max_value
	player_health_bar.value = max_value

# --- FUNÇÃO MODIFICADA ---
# Esta função agora vai animar a barra de vida
func update_player_health(new_value):
	
	# 1. Se uma animação de dreno já estiver rodando, mate-a.
	# Isso evita bugs se o jogador tomar dano muito rápido.
	if health_tween and health_tween.is_running():
		health_tween.kill()

	# 2. Crie uma nova animação (Tween)
	health_tween = create_tween()
	
	# 3. Diga ao Tween para animar a propriedade "value" da barra de vida
	#    de: seu valor ATUAL (player_health_bar.value)
	#    para: o novo valor (new_value)
	#    duração: 0.5 segundos (mude este valor como quiser)
	health_tween.tween_property(player_health_bar, "value", new_value, 0.5)

	# A linha antiga (que era instantânea) foi removida:
	# player_health_bar.value = new_value
