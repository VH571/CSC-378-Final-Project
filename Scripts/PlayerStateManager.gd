extends Node

# Persistent player state
var current_health: int = 150
var max_health: int = 150
var last_boss_defeated: String = ""

# Method to update current health
func set_current_health(health: int):
	current_health = min(health, max_health)

# Method to fully restore health (typically after boss defeat)
func fully_restore_health():
	current_health = max_health

# Method to track boss defeat for health reset
func record_boss_defeat(boss_name: String):
	last_boss_defeated = boss_name
	fully_restore_health()

# Method to check if health should be reset
func should_reset_health(current_scene: String) -> bool:
	# You can add logic here to determine when to reset health
	# For example, only reset after a specific boss or scene
	return false
