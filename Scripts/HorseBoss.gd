extends CharacterBody2D

signal hit_player

@export var boss_name: String = "HorseBoss"
@export var current_level: int = 1

const DROP_CHANCE : float = 0.1

@onready var anim = $AnimatedSprite2D
@onready var horse_scene := preload("res://Scenes/Horse.tscn")
@onready var audio_player = $AudioPlayer
@onready var voice_timer = $VoiceTimer
@export var min_voice_delay: float = 5.0
@export var max_voice_delay: float = 10
@export var voice_line_chance: float = 0.7
@export var num_one_liners: int = 6
@onready var healthbar = $HealthBar
var main
var player

var alive : bool = true
var entered : bool = true
var speed : int = 50
var direction : Vector2
var health : int = 100
var damage : int = 5
var is_attacking : bool = false
var attack_cooldown : float = 1.5
var can_attack : bool = true
var has_dealt_damage : bool = false



func _ready():
	var highest_completed_level = BossProgressManager.get_highest_completed_level(boss_name)
	
	# If this level has already been defeated, don't spawn or adjust difficulty
	if BossProgressManager.is_boss_defeated_at_level(boss_name, current_level):
		queue_free()
		return
		
	adjust_difficulty(highest_completed_level)
	
	healthbar.init_health(health)
	find_player()
	connect_signals()
	set_initial_direction()
	setup_attack_timer()
	setup_audio_system()
	play_random_voice_line()

func adjust_difficulty(completed_levels: int):
	health += completed_levels * 20
	damage += completed_levels * 2
	speed += completed_levels * 5
	
func _physics_process(delta):
	if !alive or !player:
		return
		
	if entered:
		update_direction()
		handle_movement_and_attack()
	
	check_attack_distance()

func find_player():
	main = get_tree().get_root().get_node_or_null("Main")
	
	if main:
		player = main.get_node_or_null("Player")
	
	if !player:
		player = get_tree().get_first_node_in_group("player")

func connect_signals():
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	var area = $Area2D
	if area and !area.is_connected("body_entered", _on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)

func set_initial_direction():
	var screen_rect = get_viewport_rect()
	var dist = screen_rect.get_center() - position
	
	if abs(dist.x) > abs(dist.y):
		direction.x = dist.x
		direction.y = 0
	else:
		direction.x = 0
		direction.y = dist.y

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
	
	if !has_node("VoiceTimer"):
		var timer = Timer.new()
		timer.name = "VoiceTimer"
		timer.one_shot = true
		timer.timeout.connect(_on_voice_timer_timeout)
		add_child(timer)
		voice_timer = timer
	
	_start_voice_timer()

func _start_voice_timer():
	var delay = randf_range(min_voice_delay, max_voice_delay)
	voice_timer.wait_time = delay
	voice_timer.start()

func _on_voice_timer_timeout():
	if alive and randf() <= voice_line_chance:
		play_random_voice_line()
	
	_start_voice_timer()

func play_random_voice_line():
	if !alive:
		return
		
	var line_number = randi() % num_one_liners
	var audio_path = "res://assets/audio/horse/one-liners-horse" + str(line_number) + ".mp3"
	var audio_stream = load(audio_path)
	
	if audio_stream and audio_player:
		audio_player.stream = audio_stream
		audio_player.play()

func play_damage_voice_line():
	if !alive:
		return
		
	var line_number = randi() % 3
	var audio_path = "res://assets/audio/horse/horse-damage" + str(line_number) + ".mp3"
	var audio_stream = load(audio_path)
	
	if audio_stream and audio_player:
		audio_player.stream = audio_stream
		audio_player.play()

func update_direction():
	direction = (player.position - position).normalized()

func handle_movement_and_attack():
	if !is_attacking:
		velocity = direction * speed
		move_and_slide()
		update_animation()
		
		if position.distance_to(player.position) < 50 and can_attack:
			start_attack()
	elif is_attacking:
		if !has_dealt_damage and position.distance_to(player.position) < 60:
			if anim.animation == "attack" and anim.frame >= 2:
				deal_damage_to_player()

func check_attack_distance():
	if !is_attacking and can_attack and alive and player:
		if position.distance_to(player.position) < 50:
			start_attack()
	elif !is_attacking and !can_attack and alive and player:
		var distance = position.distance_to(player.position)
		if distance < 50 and $AttackTimer.time_left < 0.2:
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
		play_random_voice_line()

func deal_damage_to_player():
	if player and player.has_method("take_damage") and !has_dealt_damage:
		player.take_damage(damage)
		hit_player.emit()
		has_dealt_damage = true

func take_damage(amount):
	health -= amount
	print("Horse health after damage: ", health)
	
	healthbar.health = health
	
	if anim:
		anim.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1)
	
	play_damage_voice_line()
		
	if health <= 0:
		die()

func die():
	BossProgressManager.defeat_boss("HorseBoss", current_level)
	
	if BossProgressManager.are_all_bosses_defeated():
		print("ALL BOSSES DEFEATED - SHOWING VICTORY SCREEN!")
		await get_tree().create_timer(2.0).timeout
		BossProgressManager.show_victory_screen()
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
	
	if alive and player and position.distance_to(player.position) < 50:
		call_deferred("start_attack")

func _on_entrance_timer_timeout():
	entered = true

func _on_area_2d_body_entered(body):
	if player and body == player and alive and !is_attacking:
		start_attack()
