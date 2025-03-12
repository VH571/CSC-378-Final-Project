extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
@onready var level_label = $LevelLabel
@onready var message_timer = $MessageTimer

var player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if !player:
		player = get_parent().get_node_or_null("Player")
	
	update_health_display()
	level_label.text = ""
	level_label.visible = false
	
	message_timer.timeout.connect(_on_message_timer_timeout)

func _process(delta):
	if player:
		update_health_display()

func update_health_display():
	if player and player.has_method("get_health"):
		var current_health = player.get_health()
		var max_health = player.get_max_health() if player.has_method("get_max_health") else 100
		
		
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = current_health
			
			var health_percent = float(current_health) / max_health
			if health_percent > 0.7:
				health_bar.modulate = Color(0, 1, 0)
			elif health_percent > 0.3:
				health_bar.modulate = Color(1, 1, 0)
			else:
				health_bar.modulate = Color(1, 0, 0)
		
		if health_label:
			health_label.text = "Health: " + str(current_health) + "/" + str(max_health)

func show_level_message(text):
	level_label.text = text
	level_label.visible = true
	message_timer.start(2.0)

func _on_message_timer_timeout():
	level_label.visible = false
