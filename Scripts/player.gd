extends CharacterBody2D

signal punched_enemy

const START_SPEED : int = 200
const ATTACK_DURATION : float = 0.3

var speed : int
var screen_size : Vector2
var is_attacking : bool = false
var angle: int = 2
var health : int = 100

@onready var anim := $AnimatedSprite2D
@onready var attack_hitbox := $PunchArea2D
@onready var attack_timer := $AttackTimer

func _ready():
	screen_size = get_viewport_rect().size
	reset()
	anim.animation_finished.connect(_on_animation_finished)
	attack_hitbox.body_entered.connect(_on_PunchArea2D_body_entered)

func _physics_process(_delta):
	get_input()
	move_and_slide()
	position = position.clamp(Vector2.ZERO, screen_size)
	update_player_direction()
	update_animation()

func reset():
	position = screen_size / 2
	speed = START_SPEED

func get_input():
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * speed
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

func update_player_direction():
	if Input.is_action_pressed("move_left"):
		angle = 1
	if Input.is_action_pressed("move_right"):
		angle = 2

func update_animation():
	if is_attacking:
		return
	if velocity.length() != 0:
		anim.animation = "walk" + str(angle)
	else:
		anim.animation = "idle" + str(angle)
	anim.play()

func start_attack():
	is_attacking = true
	anim.animation = "attack" + str(angle)
	anim.play()
	attack_hitbox.position = Vector2(30 if angle == 2 else -30, 0)
	attack_hitbox.monitoring = true

func check_hit_enemies():
	var overlapping_bodies = attack_hitbox.get_overlapping_bodies()
	print("Checking enemies... Found:", overlapping_bodies.size())
	for body in overlapping_bodies:
		if body.is_in_group("enemies"):
			print("Enemy hit:", body.name)
			body.take_damage(5)
			punched_enemy.emit()

func take_damage(amount):
	health -= amount
	print("Player health:", health)
	if health <= 0:
		die()

func die():
	print("Game Over!")

func _on_animation_finished():
	if is_attacking and anim.animation.begins_with("attack"):
		is_attacking = false
		attack_hitbox.monitoring = false
		check_hit_enemies()
		if velocity.length() != 0:
			anim.animation = "walk" + str(angle)
		else:
			anim.animation = "idle" + str(angle)
		anim.play()

func _on_PunchArea2D_body_entered(body):
	if is_attacking and body.is_in_group("enemies"):  
		print("Enemy hit:", body.name)
		body.take_damage(10)
		punched_enemy.emit()
func get_health():
	return health
func get_max_health():
	return 100


func _on_to_horse_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player reached exit! Changing scene...")
		get_tree().change_scene_to_file("res://Scenes/Main1.tscn")


func _on_to_main_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player reached exit! Changing scene...")
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
		
func _on_to_camel_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player reached exit! Changing scene...")
		get_tree().change_scene_to_file("res://Scenes/Desert.tscn")
		
