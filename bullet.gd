extends Area2D

@export var speed = 600.0
@export var damage: float = 5.0
var direction = Vector2.RIGHT

func _process(delta):
	# Move o projétil na direção definida.
	position += direction * speed * delta

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
