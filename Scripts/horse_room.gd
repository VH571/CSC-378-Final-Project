extends Node2D

@export var horse_scene: PackedScene
@export var max_levels: int = 3
@export var boss_name: String = "HorseBoss"
@export var transition_time: float = 5
@export var base_enemies_per_level: int = 1
@export var enemy_increase_per_level: int = 0
@export var custom_level_config: bool = true
@export var level_configurations: Array[Array] = [
	[1, 1, 3, 1, 1],
	[2, 1, 6, 2, 1],
	[3, 1, 9, 4, 1]
]
@export var base_enemy_health: int = 30
@export var base_enemy_damage: int = 5
@export var base_enemy_speed: int = 50

var current_level: int = 0
var level_in_progress: bool = false

@onready var player = $Player
@onready var spawn_points = $SpawnPoints.get_children()
@onready var ui = $UI
@onready var level_timer = $LevelTimer


signal level_completed(level_number)
signal all_levels_completed

func _ready():
	if player:
		player.punched_enemy.connect(_on_player_punched_enemy)
	
	level_timer.one_shot = true
	level_timer.wait_time = transition_time
	level_timer.timeout.connect(_on_level_timer_timeout)
	
	call_deferred("start_level", 1)

func boss_defeated():
	# Assuming you have a reference to the player
	if player and player.has_method("on_boss_defeated"):
		player.on_boss_defeated(boss_name)  # Pass the specific boss name
func _physics_process(delta):
	if level_in_progress:
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			complete_level()

func start_level(level_number):
	if level_number > max_levels:
		finish_game()
		return
	
	current_level = level_number
	level_in_progress = true
	
	ui.show_level_message("Level " + str(current_level))
	
	var enemies_count = get_enemy_count_for_level(level_number)
	
	# Set the current level for the boss when spawning
	var stats = get_enemy_stats_for_level(level_number)
	
	spawn_enemies(enemies_count, level_number, stats)

func get_enemy_count_for_level(level_number):
	if custom_level_config:
		for config in level_configurations:
			if config[0] == level_number:
				return config[1]
	return base_enemies_per_level + ((level_number - 1) * enemy_increase_per_level)

func get_enemy_stats_for_level(level_number):
	var health_mod = 1.0
	var damage_mod = 1.0
	var speed_mod = 1.0
	
	if custom_level_config:
		for config in level_configurations:
			if config[0] == level_number:
				if config.size() > 2: health_mod = config[2]
				if config.size() > 3: damage_mod = config[3]
				if config.size() > 4: speed_mod = config[4]
				break
	else:
		health_mod = 1.0 + ((level_number - 1) * 0.5)
		damage_mod = 1.0 + ((level_number - 1) * 0.2)
		speed_mod = 1.0 + ((level_number - 1) * 0.1)
	
	return {
		"health": int(base_enemy_health * health_mod),
		"damage": int(base_enemy_damage * damage_mod),
		"speed": int(base_enemy_speed * speed_mod)
	}

func spawn_enemies(count, level_number, stats):
	for existing_enemy in get_tree().get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	
	var available_spawns = spawn_points.duplicate()
	available_spawns.shuffle()
	
	for i in range(min(count, available_spawns.size())):
		var spawn_position = available_spawns[i].global_position
		var enemy = horse_scene.instantiate()
		
		# Set the current level for the boss
		enemy.current_level = level_number
		
		enemy.add_to_group("enemies")
		enemy.health = stats.health
		enemy.damage = stats.damage
		enemy.speed = stats.speed
		
		enemy.hit_player.connect(_on_enemy_hit_player)
		
		add_child(enemy)
		enemy.global_position = spawn_position
		
func _on_player_punched_enemy():
	await get_tree().create_timer(0.2).timeout
	
	if get_tree().get_nodes_in_group("enemies").size() == 0 and level_in_progress:
		complete_level()

func _on_enemy_hit_player():
	if player and player.health <= 0:
		game_over()

func complete_level():
	if not level_in_progress:
		return
		
	level_in_progress = false
	emit_signal("level_completed", current_level)
	
	ui.show_level_message("Level " + str(current_level) + " Completed!")
	
	level_timer.start()

func _on_level_timer_timeout():
	if current_level < max_levels:
		start_level(current_level + 1)
	else:
		finish_game()

func finish_game():
	emit_signal("all_levels_completed")
	ui.show_level_message("Congratulations! All Levels Completed!")

func game_over():
	ui.show_level_message("Game Over!")
	level_in_progress = false
	level_timer.stop()

func restart_game():
	if player:
		player.health = 100
		player.reset()
	
	start_level(1)
