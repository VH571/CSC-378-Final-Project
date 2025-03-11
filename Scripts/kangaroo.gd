extends CharacterBody2D
var health = 100

@onready var anim = $AnimatedSprite2D

func _process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
		$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		$AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * 200  
		move_and_slide()
		
	if Input.is_action_pressed("attack"):
		anim.play("attack")
	else:
		anim.play("idle")
func take_damage(amount):
	health -= amount
	print("Player health:", health)
	if health <= 0:
		die()

func die():
	print("Game Over!")


func _on_to_horse_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player reached exit! Changing scene...")
		get_tree().change_scene_to_file("res://Scenes/Main1.tscn")
