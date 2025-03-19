extends Node

var boss_progress: Dictionary = {}
var single_bosses = ["GorillaBoss", "ChickenBoss", "CamelBoss"]
var horse_boss_max_level = 3

func defeat_single_boss(boss_name: String):
	boss_progress[boss_name] = true
	
func is_single_boss_defeated(boss_name: String) -> bool:
	return boss_progress.get(boss_name, false)

func defeat_boss(boss_name: String, level: int):
	if !boss_progress.has(boss_name):
		boss_progress[boss_name] = {}
	
	boss_progress[boss_name][level] = true

func is_boss_defeated(boss_name: String, level: int = 0) -> bool:
	if boss_progress.has(boss_name):
		return boss_progress[boss_name].get(level, false)
	return false

func is_boss_defeated_at_level(boss_name: String, level: int) -> bool:
	if boss_progress.has(boss_name):
		return boss_progress[boss_name].get(level, false)
	return false

func get_highest_completed_level(boss_name: String) -> int:
	if boss_progress.has(boss_name):
		var levels = boss_progress[boss_name].keys()
		return levels.max() if levels else 0
	return 0

func are_all_bosses_defeated() -> bool:
	for boss in single_bosses:
		if not is_single_boss_defeated(boss):
			return false
	
	for level in range(1, horse_boss_max_level + 1):
		if not is_boss_defeated_at_level("HorseBoss", level):
			return false
	
	return true

func show_victory_screen():
	get_tree().paused = true
	

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	canvas_layer.name = "VictoryLayer"
	
	var victory_ui = Control.new()
	victory_ui.name = "VictoryUI"
	victory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_ui.anchor_right = 1.0
	victory_ui.anchor_bottom = 1.0
	canvas_layer.add_child(victory_ui)
	
	
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0, 0, 0.7) 
	victory_ui.add_child(bg)
	
	
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	victory_ui.add_child(center_container)
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(400, 0)  
	container.add_theme_constant_override("separation", 20)
	center_container.add_child(container)
	

	var title_label = Label.new()
	title_label.text = "VICTORY!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))  
	container.add_child(title_label)
	
	var congrats_label = Label.new()
	congrats_label.text = "You have defeated all the bosses!"
	congrats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congrats_label.add_theme_font_size_override("font_size", 24)
	congrats_label.add_theme_color_override("font_color", Color(1, 1, 1))
	container.add_child(congrats_label)
	
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	container.add_child(button_container)
	
	
	var menu_button = Button.new()
	menu_button.text = "Return to Main Menu"
	menu_button.pressed.connect(func():
		get_tree().paused = false
		canvas_layer.queue_free() 
		get_tree().change_scene_to_file("res://Scenes/menu.tscn"))
	button_container.add_child(menu_button)
	
	var replay_button = Button.new()
	replay_button.text = "Play Again"
	replay_button.pressed.connect(func(): 
		reset_boss_progress()
		get_tree().paused = false
		canvas_layer.queue_free()  
		get_tree().change_scene_to_file("res://Scenes/MainScene.tscn"))
	button_container.add_child(replay_button)
	
	var quit_button = Button.new()
	quit_button.text = "Quit Game"
	quit_button.pressed.connect(func(): 
		canvas_layer.queue_free()  
		get_tree().quit())
	button_container.add_child(quit_button)
	
	get_tree().root.add_child(canvas_layer)
	
func reset_boss_progress():
	boss_progress.clear()
