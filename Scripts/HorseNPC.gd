extends CharacterBody2D

# Horse boss stats
@export var max_health := 100
@export var current_health := 100
@export var normal_speed := 150
@export var charge_speed := 300
@export var punch_damage := 15
@export var detection_radius := 300
@export var retreat_health_threshold := 30  # % of health to trigger retreat

# State machine
enum State {IDLE, CHASE, CHARGE, ATTACK, RETREAT, WITHDRAW, STUNNED}
var current_state = State.IDLE

# References
@onready var player = get_tree().get_first_node_in_group("player")
@onready var animation_player = $AnimationHorse
@onready var cooldown_timer = $CooldownTimer
@onready var state_timer = $StateTimer
@onready var hit_area = $HitArea

# State variables
var can_attack := true
var attack_cooldown := 2.0
var charge_cooldown := 5.0
var retreat_duration := 3.0
var stun_duration := 1.0
var withdraw_duration := 1.5  # Time spent withdrawing before chasing again
var direction := Vector2.ZERO
var last_known_player_pos := Vector2.ZERO
var attack_count := 0
var difficulty_scale := 0.8  # 0.0-1.0 where 1.0 is hardest

func _ready():
	cooldown_timer.one_shot = true
	state_timer.one_shot = true
	hit_area.monitoring = false  # Turn off attack hit detection until attacking

func _physics_process(delta):
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.CHASE:
			process_chase_state(delta)
		State.CHARGE:
			process_charge_state(delta)
		State.ATTACK:
			process_attack_state(delta)
		State.RETREAT:
			process_retreat_state(delta)
		State.WITHDRAW:
			process_withdraw_state(delta)
		State.STUNNED:
			process_stunned_state(delta)
			
	# Apply movement
	move_and_slide()
	
	# Update animations based on movement
	update_animations()

func process_idle_state(delta):
	velocity = Vector2.ZERO
	
	if player_in_detection_range():
		transition_to_state(State.CHASE)

func process_chase_state(delta):
	if not player_in_detection_range():
		transition_to_state(State.IDLE)
		return
		
	# Check if health is low for retreating
	if should_retreat():
		transition_to_state(State.RETREAT)
		return
		
	# Move towards player
	direction = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if can_attack and distance_to_player < 80:
		if randf() < 0.7 * difficulty_scale:
			transition_to_state(State.ATTACK)
			return
	
	# Random chance to charge if far enough and cooldown allows
	if cooldown_timer.is_stopped() and distance_to_player > 150 and distance_to_player < detection_radius:
		if randf() < 0.3 * difficulty_scale:
			last_known_player_pos = player.global_position
			transition_to_state(State.CHARGE)
			return
	
	# Move to WITHDRAW if too close
	if distance_to_player < 50:
		transition_to_state(State.WITHDRAW)
		return
	
	velocity = direction * normal_speed

func process_withdraw_state(delta):
	if not state_timer.is_stopped():
		# Move away from player
		direction = (global_position - player.global_position).normalized()
		velocity = direction * normal_speed
	else:
		transition_to_state(State.CHASE)

func process_charge_state(delta):
	# Charge in the direction of where the player was when charge began
	if not state_timer.is_stopped():
		velocity = global_position.direction_to(last_known_player_pos) * charge_speed
	else:
		# Charge finished
		cooldown_timer.start(charge_cooldown)
		transition_to_state(State.CHASE)

func process_attack_state(delta):
	velocity = Vector2.ZERO
	
	# Attack logic is handled by animation events

func process_retreat_state(delta):
	if not state_timer.is_stopped():
		# Run away from player
		if player_in_detection_range():
			direction = global_position.direction_to(player.global_position).normalized() * -1
			velocity = direction * normal_speed * 1.2  # Slightly faster when retreating
		else:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 100)
	else:
		transition_to_state(State.CHASE)

func process_stunned_state(delta):
	velocity = Vector2.ZERO
	
	if state_timer.is_stopped():
		transition_to_state(State.CHASE)

func transition_to_state(new_state):
	current_state = new_state
	
	match new_state:
		State.IDLE:
			animation_player.play("idle")
		State.CHASE:
			animation_player.play("run")
		State.CHARGE:
			animation_player.play("charge")
			state_timer.start(2.0)  # Charge duration
		State.ATTACK:
			animation_player.play("attack")
			can_attack = false
			hit_area.monitoring = true
		State.RETREAT:
			animation_player.play("run")
			state_timer.start(retreat_duration)
		State.WITHDRAW:
			animation_player.play("run")
			state_timer.start(withdraw_duration)  # Moves away briefly before chasing again
		State.STUNNED:
			animation_player.play("stunned")
			state_timer.start(stun_duration)

func player_in_detection_range() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) < detection_radius

func should_retreat() -> bool:
	# Retreat based on health threshold and also make it a bit random
	var health_percent = (float(current_health) / max_health) * 100
	return health_percent <= retreat_health_threshold and randf() < 0.3

func update_animations():
	# Update facing direction based on movement or player position
	if velocity.length() > 0:
		# Flip sprite based on horizontal movement
		if velocity.x < 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
	elif player and current_state != State.RETREAT:
		# When not moving, face the player
		if player.global_position.x < global_position.x:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		hit_area.monitoring = false
		cooldown_timer.start(attack_cooldown)
		transition_to_state(State.CHASE)
	
func _on_hit_area_body_entered(body):
	if body.is_in_group("player") and current_state == State.ATTACK:
		# Deal damage to player
		if body.has_method("take_damage"):
			body.take_damage(punch_damage)
		
	# For charge attack, deal damage and stun self
	if body.is_in_group("player") and current_state == State.CHARGE:
		if body.has_method("take_damage"):
			body.take_damage(punch_damage * 1.5)
		transition_to_state(State.STUNNED)  # Horse gets stunned after charge hit

func take_damage(amount):
	current_health -= amount
	
	# Flash effect or other visual indicator
	$Sprite2D.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()
	elif randf() < 0.2:  # Small chance to be stunned when hit
		transition_to_state(State.STUNNED)

func die():
	# Play death animation
	animation_player.play("death")
	set_physics_process(false)
	
	# Wait for animation to finish
	await animation_player.animation_finished
	
	# Remove the boss
	queue_free()

func _on_cooldown_timer_timeout():
	can_attack = true
