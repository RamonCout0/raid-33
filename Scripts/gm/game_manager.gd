extends Node

# Uma referência ao nosso chefe na cena.
@onready var boss = $Boss

func _ready():
	# No início do jogo, mandamos o chefe configurar sua vida.
	boss.initialize_health_system()
