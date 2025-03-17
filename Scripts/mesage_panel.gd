extends Panel

func _ready():
	# Create a text button
	var text_button = Button.new()
	text_button.text = "CLOSE"
	text_button.position = Vector2(370, 10)
	text_button.size = Vector2(50, 40)
	text_button.pressed.connect(_on_close_button_pressed)
	add_child(text_button)
	var message_label = $MessageLabel
func display_message(message):
	$MessageLabel.text = message
	visible = true

func _on_close_button_pressed():
	visible = false
