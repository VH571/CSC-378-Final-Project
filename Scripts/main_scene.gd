extends Node2D

@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel
@onready var player = $Player
func _ready():
	player.global_position = $Player.global_position
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


# Replace with function body.
