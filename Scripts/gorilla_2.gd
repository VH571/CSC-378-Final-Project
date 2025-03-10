extends CharacterBody2D
signal hit_player

# Enemy properties
@export var speed: float = 80.0
@export var health: int = 100
@export var damage: int = 10
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.0

# Node references
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea

# State variables
var player = null
var direction = Vector2.ZERO
var is_attacking = false
var can_attack = true
var has_dealt_damage = false
var alive = true

func _ready():
	# Find the player
	find_player()
	
	# Connect signals
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	# Add to enemies group for level management
	add_to_group("enemies")
	
	# Set up attack timer
	var attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# Add debug print
	print("Gorilla initialized, finding player...")

func _physics_process(delta):
	if !alive or !player:
		return
	
	# Update direction to player
	direction = (player.global_position - global_position).normalized()
	
	# Only move if not attacking
	if !is_attacking:
		# Set velocity toward player
		velocity = direction * speed
		move_and_slide()
		
		# Update animation based on movement
		update_animation()
		
		# Check if close enough to attack
		if global_position.distance_to(player.global_position) < attack_range and can_attack:
			start_attack()
	
	# Add debug prints occasionally
	if Engine.get_frames_drawn() % 60 == 0:  # Every ~1 second
		print("Gorilla state: attacking=", is_attacking, " dist=", global_position.distance_to(player.global_position))

func find_player():
	player = get_tree().get_first_node_in_group("player")
	
	if !player:
		print("Player not found!")
		# Try again after a delay
		await get_tree().create_timer(0.5).timeout
		player = get_tree().get_first_node_in_group("player")
	else:
		print("Player found at position:", player.global_position)

func update_animation():
	if !anim:
		return
	
	if velocity.length() > 0:
		anim.animation = "run"  # Assuming you have a run animation
		anim.flip_h = velocity.x < 0  # Flip based on movement direction
	else:
		anim.animation = "idle"  # Assuming you have an idle animation
	
	anim.play()

func start_attack():
	print("Starting attack!")
	is_attacking = true
	can_attack = false
	has_dealt_damage = false
	
	if anim:
		anim.animation = "attack"  # Assuming you have an attack animation
		anim.play()

func deal_damage_to_player():
	if player and player.has_method("take_damage") and !has_dealt_damage:
		player.take_damage(damage)
		hit_player.emit()
		has_dealt_damage = true
		print("Enemy dealt damage to player")

func take_damage(amount):
	health -= amount
	print("Enemy health: ", health)
	
	# Visual feedback of damage
	if anim:
		anim.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	alive = false
	
	# Remove from enemies group
	remove_from_group("enemies")
	
	# Play death animation
	if anim:
		anim.animation = "dead"
		anim.play()
	
	# Disable collisions
	$CollisionShape2D.set_deferred("disabled", true)
	
	var main = get_tree().current_scene
	if main.has_method("boss_defeated"):
		main.boss_defeated()
	
	# Remove after animation
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _on_animation_finished():
	if is_attacking and anim.animation == "attack":
		print("Attack animation finished")
		# Check if player is in range to deal damage
		if global_position.distance_to(player.global_position) < attack_range + 10:
			deal_damage_to_player()
		
		is_attacking = false
		
		# Start cooldown timer
		$AttackTimer.start()

func _on_attack_timer_timeout():
	can_attack = true
	print("Attack cooldown finished, can attack again")
	
	# If player is still in range, attack again immediately
	if player and global_position.distance_to(player.global_position) < attack_range:
		call_deferred("start_attack")
