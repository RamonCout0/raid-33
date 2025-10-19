extends Area2D
var speed = 300
var velocity = Vector2.ZERO
func _ready():
	velocity = transform.x * speed
func _physics_process(delta):
	position += velocity * delta
