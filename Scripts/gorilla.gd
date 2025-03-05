extends CharacterBody2D

@export var speed: float = 100.0
@export var attack_range: float = 50.0  
@onready var player = null
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $Area2D

var attacking = false

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("Player found:", player)
	else:
		print("Error: Player not found!")
	anim.play("idle")  

func _process(delta):

	if player:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)

		if distance > 50: 
			velocity = direction * 100  
		else:
			velocity = Vector2.ZERO  
		if player.global_position.x < global_position.x:
			$AnimatedSprite2D.flip_h = true  
		else:
			$AnimatedSprite2D.flip_h = false  
		move_and_collide(velocity * delta)

func attack(target):
	if attacking:
		print("Attack prevented: already attacking")
		return  

	attacking = true
	velocity = Vector2.ZERO  
	print("Gorilla attacking! Playing attack animation:", anim.animation)

	anim.play("attack")  

	await get_tree().create_timer(0.1).timeout  
	print("Current animation:", anim.animation)

	
	await anim.animation_finished
	print("Animation finished!")

	if target and target.is_in_group("player"):
		print("Player took damage!")
		target.take_damage(10)

	attacking = false
	print("Gorilla attack finished. Ready for next attack.")

func _on_Area2D_body_entered(body):
	if body.is_in_group("player") and not attacking:
		print("Player entered attack range!")
		attack(body)
 
func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		print("Player left attack range!")
		attacking = false  
