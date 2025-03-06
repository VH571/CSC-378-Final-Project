extends CharacterBody2D

@export var speed: float = 120.0  # Normal movement speed
@export var charge_speed: float = 250.0  # Charge attack speed
@export var attack_range: float = 50.0  
@export var retreat_threshold: float = 30.0  # HP at which the horse runs away
@export var max_health: int = 100

@onready var player = null
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $Area2D
@onready var timer = $Timer  # For attack cooldown

var attacking = false
var charging = false
var health = max_health
var retreating = false

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		print("Player found:", player)
	else:
		print("Error: Player not found!")
	
	anim.play("idle")  
	timer.start()  # Starts attack cooldown timer

func _process(delta):
	if not player or attacking or charging:
		return

	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)

	# Retreating when health is low
	if health <= retreat_threshold:
		retreating = true
		velocity = -direction * speed  # Move away from player
		anim.play("run")
	else:
		retreating = false

		# If close, attack
		if distance < attack_range and timer.is_stopped():
			attack(player)
			return  # Stop further movement while attacking

		# Move towards player normally
		elif distance > attack_range:
			velocity = direction * speed  
			anim.play("run")
		else:
			velocity = Vector2.ZERO  
			anim.play("idle")

	# Flip sprite based on direction
	if player.global_position.x < global_position.x:
		anim.flip_h = true  
	else:
		anim.flip_h = false  

	move_and_slide()

func attack(target):
	if attacking or charging:
		return

	attacking = true
	velocity = Vector2.ZERO  
	
	# Randomly decide between a charge or a strong melee attack
	if randf() < 0.5:
		charge_attack(target)
	else:
		melee_attack(target)

func charge_attack(target):
	charging = true
	anim.play("charge")

	var direction = (target.global_position - global_position).normalized()
	velocity = direction * charge_speed  

	await get_tree().create_timer(0.4).timeout  # Charge duration
	velocity = Vector2.ZERO  

	# Check if the player is still in range after the charge
	if global_position.distance_to(target.global_position) < attack_range:
		target.take_damage(15)  # Stronger charge attack

	charging = false
	attacking = false
	timer.start()  # Start cooldown to prevent spam attacks

func melee_attack(target):
	anim.play("attack")  

	await get_tree().create_timer(0.2).timeout  

	if target and target.is_in_group("player"):
		target.take_damage(10)  # Strong kick attack

	await anim.animation_finished
	attacking = false
	timer.start()  # Start attack cooldown

func _on_Area2D_body_entered(body):
	if body.is_in_group("player") and not attacking and timer.is_stopped():
		attack(body)

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		attacking = false  

func take_damage(amount):
	health -= amount
	print("Horse Boss HP:", health)

	# If HP reaches 0, boss dies
	if health <= 0:
		die()

func die():
	anim.play("death")
	set_physics_process(false)  # Stops movement
	await anim.animation_finished
	queue_free()  # Remove the boss from the scene
