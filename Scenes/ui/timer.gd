extends CanvasLayer # Altere para o tipo do seu nó raiz, se for diferente (ex: Control)

# CORREÇÃO: Usamos $Label e $Timer pois eles são filhos diretos do nó com este script.
@onready var label: Label = $Label
@onready var timer_node: Timer = $Timer

# Variável para armazenar o tempo restante, inicializada no _ready
var tempo_restante: float = 0.0

# Esta função é executada assim que a cena é carregada
func _ready():
	# Inicializa o 'tempo_restante' com o 'wait_time' configurado no Inspetor
	tempo_restante = timer_node.wait_time
	
	# Inicia a contagem regressiva
	timer_node.start()
	
	# Atualiza o Label imediatamente para mostrar o tempo total
	_atualizar_label()


# Esta função é chamada a cada frame
func _process(delta):
	# Se o timer estiver ativo, atualizamos o tempo restante
	if not timer_node.is_stopped():
		# Obtém o tempo que falta para o timer expirar
		tempo_restante = timer_node.time_left
		_atualizar_label()
	# Se o timer já parou (por ter chegado a zero), podemos parar de processar
	elif tempo_restante <= 0.0:
		set_process(false)


# Função para formatar o tempo em "Minutos:Segundos" e atualizar o Label
func _atualizar_label():
	# Garante que o tempo nunca seja negativo no display
	if tempo_restante < 0:
		tempo_restante = 0
	
	# Calcula Minutos e Segundos
	var minutos: int = floor(tempo_restante / 60.0)
	var segundos: int = int(fmod(tempo_restante, 60.0))
	
	# Formata a string como MM:SS (com zeros à esquerda)
	label.text = "%02d:%02d" % [minutos, segundos]


# Esta função é chamada automaticamente quando o sinal 'timeout()' é emitido (tempo=0)
func _on_timer_timeout():
	# Garante que o display mostre exatamente 00:00
	tempo_restante = 0.0
	_atualizar_label()
	
	# A contagem regressiva terminou! Coloque aqui a lógica final do jogo:
	print("TEMPO ESGOTADO! Fim de jogo.")
	
	# Exemplo: Congelar o tempo do jogo
	# get_tree().paused = true
	
	# Exemplo: Mudar para uma tela de Fim de Jogo
	# get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")
