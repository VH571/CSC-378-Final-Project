extends Node

@onready var level_audio = $LevelAudioPlayer

var level1_complete_sound
var level2_complete_sound
var level3_complete_sound
var game_complete_sound
var game_over_sound

func _ready():
	if !has_node("LevelAudioPlayer"):
		var player = AudioStreamPlayer.new()
		player.name = "LevelAudioPlayer"
		add_child(player)
		level_audio = player
	
	level1_complete_sound = load("res://assets/audio/horse/roundOneDefeat.mp3")
	level2_complete_sound = load("res://assets/audio/horse/roundTwoDefeat.mp3")
	level3_complete_sound = load("res://assets/audio/horse/Defeat.mp3")
	game_complete_sound = load("res://assets/audio/horse/Defeat.mp3")
	game_over_sound = load("res://assets/audio/horse/player-death-horse.mp3")
	
	var parent = get_parent()
	if parent.has_signal("level_completed"):
		parent.level_completed.connect(_on_level_completed)
	if parent.has_signal("all_levels_completed"):
		parent.all_levels_completed.connect(_on_all_levels_completed)

func play_level_complete_audio(level_number):
	var sound = null
	
	match level_number:
		1:
			sound = level1_complete_sound
		2:
			sound = level2_complete_sound
		3:
			sound = level3_complete_sound
	
	if sound and level_audio:
		level_audio.stream = sound
		level_audio.play()

func _on_level_completed(level_number):
	play_level_complete_audio(level_number)

func _on_all_levels_completed():
	if game_complete_sound and level_audio:
		level_audio.stream = game_complete_sound
		level_audio.play()

func play_game_over():
	if game_over_sound and level_audio:
		level_audio.stream = game_over_sound
		level_audio.play()
