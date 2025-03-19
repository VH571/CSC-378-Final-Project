extends Node

var boss_progress: Dictionary = {}

func defeat_single_boss(boss_name: String):
	boss_progress[boss_name] = true
	print("Boss defeated: ", boss_name)
	
func is_single_boss_defeated(boss_name: String) -> bool:
	return boss_progress.get(boss_name, false)

func defeat_boss(boss_name: String, level: int):
	if !boss_progress.has(boss_name):
		boss_progress[boss_name] = {}
	
	boss_progress[boss_name][level] = true
	print("Boss defeated: ", boss_name, " at level ", level)
func is_boss_defeated(boss_name: String, level: int = 0) -> bool:
	if boss_progress.has(boss_name):
		return boss_progress[boss_name].get(level, false)
	return false

func is_boss_defeated_at_level(boss_name: String, level: int) -> bool:
	if boss_progress.has(boss_name):
		return boss_progress[boss_name].get(level, false)
	return false

func get_highest_completed_level(boss_name: String) -> int:
	if boss_progress.has(boss_name):
		var levels = boss_progress[boss_name].keys()
		return levels.max() if levels else 0
	return 0

func reset_boss_progress():
	boss_progress.clear() 
