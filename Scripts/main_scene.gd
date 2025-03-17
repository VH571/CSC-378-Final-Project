extends Node2D

@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel

func _ready():
	# Debug: Check if UI and MessagePanel exist
	var ui = get_node_or_null("UI")
	if !ui:
		print("ERROR: UI node not found!")
	else:
		var panel = ui.get_node_or_null("MessagePanel")
		if !panel:
			print("ERROR: MessagePanel not found under UI!")
	
	# Add null check
	if message_panel:
		message_panel.visible = false
	else:
		print("ERROR: message_panel is null!")
	
	# Connect any existing signs
	for sign in get_tree().get_nodes_in_group("signs"):
		sign.sign_interacted.connect(_on_sign_interacted)

func _process(delta):
	# If message panel is visible, check for input to close it
	if message_panel and message_panel.visible:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
			message_panel.visible = false
			
func _on_sign_interacted(message):
	# Add null check
	if message_panel:
		message_panel.display_message(message)
	else:
		print("Cannot display message - panel is null!")

func close_message():
	message_panel.visible = false

func _on_close_button_pressed() -> void:
	pass 
