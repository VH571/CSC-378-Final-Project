extends Panel

func _ready():
	visible = false

func display_message(message):
	$MessageLabel.text = message
	visible = true

func _on_close_button_pressed():
	visible = false
