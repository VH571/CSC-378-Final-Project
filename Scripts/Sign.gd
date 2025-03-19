extends StaticBody2D

signal sign_interacted(message)

@export var message: String = "This is a sign message."
@export_multiline var long_message: String = "This is a longer message that can span multiple lines."

var player_in_range = false

@onready var prompt_label = $PressEPrompt

func _ready():
	if prompt_label:
		prompt_label.visible = false

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		var full_message = message + "\n\n" + long_message
		
		print("Attempting to send message: [" + full_message + "]")
		
		emit_signal("sign_interacted", full_message)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
