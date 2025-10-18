# ----- SCRIPT DO BULLET (bullet.gd) -----
extends Area2D

@export var speed = 600.0
@export var damage: float = 5.0

# Remova o ' = Vector2.RIGHT'. A direção será definida pelo Player.
var direction: Vector2 

func _process(delta):
	# Se a direção ainda não foi definida, não faça nada.
	if direction == null:
		return 
		
	# Move o projétil na direção definida.
	position += direction * speed * delta

# --- ADICIONE ESTA NOVA FUNÇÃO ---
# O Player vai chamar esta função assim que criar o bullet.
func set_bullet_direction(dir_vector: Vector2):
	direction = dir_vector.normalized() # Normalizar garante que o vetor tem comprimento 1
	
	# Vira o sprite do bullet baseado na direção
	# (Assumindo que o nó filho se chama 'AnimatedSprite2D')
	if direction.x < 0:
		$power.flip_h = true
	elif direction.x > 0:
		$power.flip_h = false
		
# --- O RESTO DO SEU CÓDIGO ESTÁ PERFEITO ---

# Esta função é chamada quando o projétil colide com um corpo físico.
func _on_body_entered(body):
	# Verifica se o corpo que atingimos está no grupo "boss".
	if body.is_in_group("boss"):
		body.take_damage(damage) # Chama a função de dano do chefe
	
	# O projétil se destrói ao colidir com qualquer coisa (chefe, parede, etc.)
	queue_free()

# Esta função é chamada pelo sinal do VisibleOnScreenNotifier2D
# quando sua forma sai completamente da tela.
func _on_visible_on_screen_notifier_2d_screen_exited():
	# Destrói o projétil quando ele sai da tela.
	queue_free()
