extends CharacterBody2D
signal punched_enemy
signal died

const START_SPEED : int = 200
const ATTACK_DURATION : float = 0.3
var speed : int
var screen_size : Vector2
var is_attacking : bool = false
var angle: int = 2
var health : int = 150
var alive = true
@onready var anim := $AnimatedSprite2D
@onready var attack_hitbox := $PunchArea2D
@onready var attack_timer := $AttackTimer
@onready var healthbar = $HealthBar

func _ready():
	healthbar.init_health(health)
	screen_size = get_viewport_rect().size
	reset()
	anim.animation_finished.connect(_on_animation_finished)
	attack_hitbox.body_entered.connect(_on_PunchArea2D_body_entered)

func _physics_process(_delta):
	if not alive:
		return
		
	get_input()
	move_and_slide()
	position = position.clamp(Vector2.ZERO, screen_size)
	update_player_direction()
	update_animation()

func reset():
	screen_size = get_viewport_rect().size
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
	for body in overlapping_bodies:
		if body.is_in_group("enemies"):
			body.take_damage(5)
			punched_enemy.emit()

func take_damage(amount):
	if not alive:
		return
		
	health -= amount
	
	if healthbar:
		healthbar.health = health
	
	if anim:
		anim.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		if alive:
			anim.modulate = Color(1, 1, 1)
	
	if health <= 0 and alive:
		die()

func die():
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	get_tree().paused = true
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10 
	canvas_layer.name = "GameOverLayer"
	
	var emergency_ui = Control.new()
	emergency_ui.name = "EmergencyGameOverUI"
	emergency_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	emergency_ui.anchor_right = 1.0
	emergency_ui.anchor_bottom = 1.0
	canvas_layer.add_child(emergency_ui)
	
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0, 0, 0.7)
	emergency_ui.add_child(bg)
	
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	emergency_ui.add_child(center_container)
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(400, 0)
	container.add_theme_constant_override("separation", 20)
	center_container.add_child(container)
	
	var label = Label.new()
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0, 0))
	container.add_child(label)
	
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	container.add_child(button_container)
	
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.pressed.connect(func(): 
		canvas_layer.queue_free()
		complete_game_restart()
	)
	button_container.add_child(restart_button)
	
	var menu_button = Button.new()
	menu_button.text = "Return to Main Menu"
	menu_button.pressed.connect(func(): 
		get_tree().paused = false
		canvas_layer.queue_free()
		get_tree().change_scene_to_file("res://Scenes/menu.tscn"))
	button_container.add_child(menu_button)
	
	var quit_button = Button.new()
	quit_button.text = "Quit Game"
	quit_button.pressed.connect(func(): 
		canvas_layer.queue_free()
		get_tree().quit())
	button_container.add_child(quit_button)
	
	get_tree().root.add_child(canvas_layer)
	
	died.emit()

func complete_game_restart():
	if BossProgressManager:
		BossProgressManager.reset_boss_progress()
	
	get_tree().paused = false
	
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

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
		body.take_damage(10)
		punched_enemy.emit()

func get_health():
	return health

func get_max_health():
	return 100

func _on_to_horse_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/Main1.tscn")

func _on_to_main_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
		
func _on_to_desert_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/Desert.tscn")

func _on_to_gorilla_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/Gorilla_fight.tscn")
		
func _on_to_chicken_scene_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/ChickenFight.tscn")
