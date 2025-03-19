extends Node

var current_health: int = 150
var max_health: int = 150
var last_boss_defeated: String = ""

func set_current_health(health: int):
	current_health = min(health, max_health)

func fully_restore_health():
	current_health = max_health

func record_boss_defeat(boss_name: String):
	last_boss_defeated = boss_name
	fully_restore_health()

func should_reset_health(current_scene: String) -> bool:
	return false
