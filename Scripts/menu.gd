extends Control


func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")

func _on_CreditsButton_pressed():
	$CreditsPopup.show_credits()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	$PopupPanel.show_credits()
