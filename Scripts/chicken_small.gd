extends CharacterBody2D
signal hit_player

@export var speed: float = 40.0
@export var health: int = 270
@export var damage: int = 10
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.0

@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var audio_player = $AudioPlayer
@onready var roar_timer = $RoarTimer
@onready var healthbar = $HealthBar

const DAMAGED_SOUND = "res://assets/audio/gorilla/Damaged.mp3"
const VOICELINE_SOUND = "res://assets/audio/gorilla/RandomVoiceline.mp3"
const ROAR1_SOUND = "res://assets/audio/gorilla/roar01.mp3" 
const ROAR2_SOUND = "res://assets/audio/gorilla/roar2.mp3"

var player = null
var direction = Vector2.ZERO
var is_attacking = false
var can_attack = true
var has_dealt_damage = false
var alive = true
@export var boss_name: String = "ChickenBoss"

func _ready():
	if BossProgressManager.is_single_boss_defeated(boss_name):
		set_physics_process(false)
		if $CollisionShape2D:
			$CollisionShape2D.set_deferred("disabled", true)
		if anim:
			anim.visible = false
		return
	
	healthbar.init_health(health)
	find_player()
	
	if anim:
		anim.animation_finished.connect(_on_animation_finished)
	
	add_to_group("enemies")
	
	if !has_node("AttackTimer"):
		var attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		attack_timer.one_shot = true
		attack_timer.wait_time = attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		add_child(attack_timer)
	
	setup_audio_system()
	play_random_roar()

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
		timer.wait_time = randf_range(5.0, 10.0)
		timer.timeout.connect(_on_roar_timer_timeout)
		add_child(timer)
		roar_timer = timer
		roar_timer.start()

func _on_roar_timer_timeout():
	if alive and randf() <= 0.7:
		play_random_roar()
	
	roar_timer.wait_time = randf_range(5.0, 10.0)
	roar_timer.start()

func play_random_roar():
	if !alive:
		return
	
	var sound_path = ROAR1_SOUND if randf() < 0.5 else ROAR2_SOUND
	play_sound(sound_path)

func play_random_voiceline():
	if !alive:
		return
	
	play_sound(VOICELINE_SOUND)

func play_sound(sound_path):
	if !audio_player:
		return
	
	var stream = load(sound_path)
	if stream:
		audio_player.stream = stream
		audio_player.play()

func _physics_process(delta):
	if !alive or !player:
		return
	
	direction = (player.global_position - global_position).normalized()
	
	if !is_attacking:
		velocity = direction * speed
		move_and_slide()
		update_animation()
		
		if global_position.distance_to(player.global_position) < attack_range and can_attack:
			start_attack()

func find_player():
	player = get_tree().get_first_node_in_group("player")
	
	if !player:
		await get_tree().create_timer(0.5).timeout
		player = get_tree().get_first_node_in_group("player")

func update_animation():
	if !anim:
		return
	
	if velocity.length() > 0:
		anim.animation = "run"
		anim.flip_h = velocity.x < 0
	else:
		anim.animation = "idle"
	
	anim.play()

func start_attack():
	is_attacking = true
	can_attack = false
	has_dealt_damage = false
	
	if randf() < 0.5:
		play_random_roar()
	
	if anim:
		anim.animation = "attack" 
		anim.play()

func deal_damage_to_player():
	if player and player.has_method("take_damage") and !has_dealt_damage:
		player.take_damage(damage)
		hit_player.emit()
		has_dealt_damage = true
		
		if randf() < 0.7:
			play_random_voiceline()

func take_damage(amount):
	health -= amount
	healthbar.health = health
	play_sound(DAMAGED_SOUND)
	
	if anim:
		anim.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	BossProgressManager.defeat_single_boss(boss_name)
	
	
	if BossProgressManager.are_all_bosses_defeated():
		print("ALL BOSSES DEFEATED - SHOWING VICTORY SCREEN!")
		await get_tree().create_timer(2.0).timeout
		BossProgressManager.show_victory_screen()
	alive = false
	play_random_roar()
	remove_from_group("enemies")
	
	if anim:
		anim.animation = "dead"
		anim.play()
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	var main = get_tree().current_scene
	if main.has_method("boss_defeated"):
		main.boss_defeated()
	
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _on_animation_finished():
	if is_attacking and anim.animation == "attack":
		if global_position.distance_to(player.global_position) < attack_range + 10:
			deal_damage_to_player()
		
		is_attacking = false
		$AttackTimer.start()

func _on_attack_timer_timeout():
	can_attack = true
	
	if player and global_position.distance_to(player.global_position) < attack_range:
		call_deferred("start_attack")
