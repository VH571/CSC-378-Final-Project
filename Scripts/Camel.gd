extends CharacterBody2D

signal hit_player

@export var speed: float = 100.0
@export var attack_range: float = 50.0  
@export var health: int = 80
@export var damage: int = 10  # Matches player attack damage
@export var attack_cooldown: float = 1.5
@export var num_roars: int = 3 

@onready var player = null
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $Area2D
@onready var audio_player = $AudioPlayer
@onready var roar_timer = $RoarTimer

var alive: bool = true
var entered: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var has_dealt_damage: bool = false
var direction: Vector2

func _ready():
	find_player()
	connect_signals()
	setup_attack_timer()
	setup_audio_system()
	play_random_roar()
	
func _physics_process(delta):
	if !alive or !player:
		return
		
	if entered:
		update_direction()
		handle_movement_and_attack()
		if !is_attacking:
			velocity = direction * speed  # Set movement speed
			move_and_slide()  # Apply movement
			update_animation()
	
	check_attack_distance()

func find_player():
	player = get_tree().get_first_node_in_group("player")  
	
	if !player:
		print("Error: Player not found!")
	else:
		#print("❌ Error: Player not found!")
		await get_tree().create_timer(1.0).timeout  # Wait 1 second and try again
		find_player()

func connect_signals():
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	var area = $Area2D
	if area and !area.is_connected("body_entered", _on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

func setup_attack_timer():
	if !has_node("AttackTimer"):
		var attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		attack_timer.one_shot = true
		attack_timer.wait_time = attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		add_child(attack_timer)

func setup_audio_system():
	if !has_node("AudioPlayer"):
		var player = AudioStreamPlayer.new()
		player.name = "AudioPlayer"
		add_child(player)
		audio_player = player
	
	if !has_node("RoarTimer"):
		var timer = Timer.new()
		timer.name = "RoarTimer"
		timer.one_shot = true
		timer.timeout.connect(_on_roar_timer_timeout)
		add_child(timer)
		roar_timer = timer
	
	_start_roar_timer()

func _start_roar_timer():
	var delay = randf_range(5.0, 10.0)
	roar_timer.wait_time = delay
	roar_timer.start()

func _on_roar_timer_timeout():
	if alive and randf() <= 0.7:
		play_random_roar()
	
	_start_roar_timer()

func play_random_roar():
	if !alive:
		return
		
	var line_number = randi() % num_roars
	var audio_path = "res://assets/audio/gorilla/roar" + str(line_number) + ".mp3"
	var audio_stream = load(audio_path)
	
	if audio_stream and audio_player:
		audio_player.stream = audio_stream
		audio_player.play()

func update_direction():
	direction = (player.global_position - global_position).normalized()

func handle_movement_and_attack():
	if !is_attacking:
		velocity = direction * speed
		move_and_slide()
		update_animation()
		
		if position.distance_to(player.position) < attack_range and can_attack:
			start_attack()
	elif is_attacking:
		if !has_dealt_damage and position.distance_to(player.position) < attack_range + 10:
			if anim.animation == "attack" and anim.frame >= 2:
				deal_damage_to_player()

func check_attack_distance():
	if !is_attacking and can_attack and alive and player:
		if position.distance_to(player.position) < attack_range:
			start_attack()
	elif !is_attacking and !can_attack and alive and player:
		var distance = position.distance_to(player.position)
		if distance < attack_range and $AttackTimer.time_left < 0.2:
			$AttackTimer.stop()
			_on_attack_timer_timeout()

func update_animation():
	if !anim or is_attacking:
		return
	
	if velocity.length() > 0:
		anim.animation = "run"
	else:
		anim.animation = "idle"
	
	anim.flip_h = velocity.x < 0
	anim.play()

func start_attack():
	is_attacking = true
	can_attack = false
	has_dealt_damage = false
	
	if anim:
		anim.animation = "attack"
		anim.play()
	
	if randf() < 0.5:
		play_random_roar()

func deal_damage_to_player():
	if player and player.has_method("take_damage") and !has_dealt_damage:
		player.take_damage(damage)  # Calls `take_damage()` from `player.gd`
		hit_player.emit()
		has_dealt_damage = true

func take_damage(amount):
	health -= amount
	print("Gorilla health after damage: ", health)
	
	if anim:
		anim.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1)
	
	play_random_roar()
		
	if health <= 0:
		die()

func die():
	remove_from_group("enemies")
	
	alive = false
	velocity = Vector2.ZERO
	
	if anim:
		anim.animation = "dead"
		anim.play()
	
	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_animation_finished():
	if is_attacking and anim.animation == "attack":
		is_attacking = false
		update_animation()
		
		if has_node("AttackTimer"):
			$AttackTimer.start(attack_cooldown)

func _on_attack_timer_timeout():
	can_attack = true
	has_dealt_damage = false
	
	if alive and player and position.distance_to(player.position) < attack_range:
		call_deferred("start_attack")

func _on_area_2d_body_entered(body):
	if player and body == player and alive and !is_attacking:
		start_attack()
