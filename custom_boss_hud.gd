extends CanvasLayer

# --- CONECTE NO INSPETOR ---
@export var bar_count_label: Label
@export var segment_progress_bar: TextureProgressBar
@export var health_color_gradient: Gradient

# --- Variáveis Internas ---
var health_per_segment: float = 1.0
var total_bar_count: int = 1

# Guarda o valor de vida que a UI está *mostrando* atualmente.
var display_health: float = 0.0

# Guarda a referência do nosso Tween de animação
var health_tween: Tween

# Chamado quando a cena é iniciada
func _ready():
	hide() # Esconde a HUD no início
	
	# Conecta aos sinais globais do chefe
	EventBus.boss_max_health_set.connect(set_boss_max_health)
	EventBus.boss_health_updated.connect(update_boss_health)

# Chamada UMA VEZ para configurar a HUD
func set_boss_max_health(max_health, p_health_per_segment):
	health_per_segment = p_health_per_segment
	if health_per_segment <= 0: return # Proteção

	# Configura o valor máximo da barra
	segment_progress_bar.max_value = health_per_segment
	
	# Calcula o número total de barras para nossa lógica de cor
	total_bar_count = ceil(float(max_health) / health_per_segment)
	
	# Define a vida inicial que a UI está mostrando
	display_health = float(max_health)
	
	# Atualiza a HUD pela primeira vez
	update_hud_visuals(display_health)
	show()

# Chamada TODA VEZ que o chefe toma dano
func update_boss_health(current_health):
	# Se uma animação de vida já estiver rodando, mate-a.
	if health_tween and health_tween.is_running():
		health_tween.kill()

	# --- A NOVA MANEIRA (GODOT 4) ---
	# 1. Cria um novo objeto Tween.
	health_tween = create_tween()
	
	# 2. Diz ao Tween para animar (chamar) um método.
	# Ele vai chamar a função "update_hud_visuals" repetidamente,
	# com um valor que vai de "display_health" (a vida antiga)
	# até "current_health" (a vida nova),
	# durante 0.5 segundos.
	health_tween.tween_method(update_hud_visuals, display_health, float(current_health), 0.5)
	



# Esta é a nossa função 100% focada em VISUALIZAÇÃO
# Ela agora é chamada pelo Tween, criando a animação suave.
func update_hud_visuals(health_value):
	if health_per_segment <= 0: return

	# --- 1. Lógica do Texto "x" ---
	var current_bar_count = ceil(health_value / health_per_segment)
	bar_count_label.text = str(current_bar_count) + "x"

	# --- 2. Lógica de Cor ---
	var percent_remaining = float(current_bar_count) / total_bar_count
	if health_color_gradient:
		segment_progress_bar.tint_progress = health_color_gradient.sample(percent_remaining)

	# --- 3. Lógica da Barra (A matemática robusta) ---
	if health_value <= 0:
		segment_progress_bar.value = 0
		return

	var health_in_previous_bars = (current_bar_count - 1) * health_per_segment
	var current_bar_health = health_value - health_in_previous_bars
	
	segment_progress_bar.value = current_bar_health
	display_health = health_value
