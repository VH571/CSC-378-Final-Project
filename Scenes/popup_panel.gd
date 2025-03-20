extends Panel

func _ready():
	hide()  # Hide at the start

func show_credits():
	show()  # Show the credits popup

func _on_CloseButton_pressed():
	hide()  # Hide when clicking close


func _on_close_pressed() -> void:
	hide() # Replace with function body.
