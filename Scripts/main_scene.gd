extends Node2D

@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel
@onready var player = $Player
@onready var game_over_ui = $GameOverUI

func _ready():
	player.global_position = $Player.global_position

	if game_over_ui:
		game_over_ui.hide()
	else:
		game_over_ui = get_node_or_null("GameOverUI")
		if game_over_ui:
			game_over_ui.hide()

	if player:
		if not player.is_connected("died", Callable(self, "_on_player_died")):
			player.died.connect(_on_player_died)

	if game_over_ui:
		if not game_over_ui.is_connected("restart_pressed", Callable(self, "_on_restart")):
			game_over_ui.restart_pressed.connect(_on_restart)

	var signs = get_tree().get_nodes_in_group("signs")

	for sign in signs:
		if sign.is_connected("sign_interacted", Callable(self, "_on_sign_interacted")):
			sign.disconnect("sign_interacted", Callable(self, "_on_sign_interacted"))

	for sign in signs:
		sign.sign_interacted.connect(_on_sign_interacted)

	if message_panel:
		message_panel.visible = false

func _process(delta):
	if message_panel and message_panel.visible:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
			message_panel.visible = false

func _on_player_died():
	get_tree().paused = true

	if game_over_ui:
		game_over_ui.show_game_over()
	else:
		game_over_ui = get_node_or_null("GameOverUI")
		if game_over_ui:
			game_over_ui.show_game_over()

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sign_interacted(message):
	if message_panel:
		message_panel.visible = true
		if message_label:
			message_label.text = message
		else:
			message_label = $UI/MessagePanel/MessageLabel
			if message_label:
				message_label.text = message

func close_message():
	message_panel.visible = false

func _on_close_button_pressed() -> void:
	pass
