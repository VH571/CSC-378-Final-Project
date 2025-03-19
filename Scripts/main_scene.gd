extends Node2D

@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel
@onready var player = $Player
@onready var game_over_ui = $GameOverUI

func _ready():
	player.global_position = $Player.global_position
	
	# Make sure the GameOverUI is hidden at start
	if game_over_ui:
		game_over_ui.hide()
		print("GameOverUI hidden at start")
	else:
		print("ERROR: game_over_ui is not found!")
		# Try to find it manually
		game_over_ui = get_node_or_null("GameOverUI")
		if game_over_ui:
			game_over_ui.hide()
			print("Found GameOverUI manually")
	
	# Connect player died signal
	if player:
		if not player.is_connected("died", Callable(self, "_on_player_died")):
			player.died.connect(_on_player_died)
			print("Connected player died signal")
	else:
		print("ERROR: player is null!")
	
	# Connect restart button signal
	if game_over_ui:
		if not game_over_ui.is_connected("restart_pressed", Callable(self, "_on_restart")):
			game_over_ui.restart_pressed.connect(_on_restart)
			print("Connected restart_pressed signal")
	
	# Debug: Check if UI and MessagePanel exist
	var ui = get_node_or_null("UI")
	var signs = get_tree().get_nodes_in_group("signs")
	print("Found", signs.size(), "signs in the 'signs' group:")
	
	# Disconnect any existing connections first
	for sign in signs:
		if sign.is_connected("sign_interacted", Callable(self, "_on_sign_interacted")):
			sign.disconnect("sign_interacted", Callable(self, "_on_sign_interacted"))
	
	# Connect all signs
	for sign in signs:
		print("Sign:", sign.name, "Message:", sign.long_message)
		sign.sign_interacted.connect(_on_sign_interacted)
	
	if message_panel:
		message_panel.visible = false
	else:
		print("ERROR: message_panel is null!")

func _process(delta):
	# If message panel is visible, check for input to close it
	if message_panel and message_panel.visible:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
			message_panel.visible = false

func _on_player_died():
	print("Player died signal received")
	
	# Pause the game
	get_tree().paused = true
	
	# Show the Game Over UI when player dies
	if game_over_ui:
		print("Calling show_game_over()")
		game_over_ui.show_game_over()
	else:
		print("ERROR: Cannot show game_over_ui because it is null!")
		# Try to find it again
		game_over_ui = get_node_or_null("GameOverUI")
		if game_over_ui:
			print("Found GameOverUI manually, showing")
			game_over_ui.show_game_over()
		else:
			print("Still can't find GameOverUI!")

func _on_restart():
	print("Restart signal received")
	
	# Unpause the game before restarting
	get_tree().paused = false
	
	# Restart the current scene
	get_tree().reload_current_scene()
			
func _on_sign_interacted(message):
	# Debug print to see what message is being received
	print("Sign message received:", message)
	
	# Make sure message_panel and message_label exist
	if message_panel:
		message_panel.visible = true
		
		# Set the text directly 
		if message_label:
			message_label.text = message
			print("Set message_label.text to:", message)
		else:
			print("ERROR: message_label is null!")
			
			# Try to find it again
			message_label = $UI/MessagePanel/MessageLabel
			if message_label:
				message_label.text = message
			else:
				print("Still can't find MessageLabel!")
	else:
		print("ERROR: message_panel is null!")

func close_message():
	message_panel.visible = false

func _on_close_button_pressed() -> void:
	pass 

