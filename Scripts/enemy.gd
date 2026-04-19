extends Node2D

signal movement_finished

@onready var Anim = $%AnimatedSprite2D
@onready var SearchBox = $SearchBox

var current_mode: String = "map"
var moving: bool = false:
	set(value):
		if moving == value:
			return
		moving = value

		if moving:
			Anim.play("Walk")
		else:
			Anim.play("Idle")

func _ready():
	pass
	#print("I spawned")
	
func _process(delta):
	if current_mode == "map":
		map_update(delta)
	elif current_mode == "battle":
		battle_update(delta)

# -------------------------
# MODE SWITCH
# -------------------------
func set_mode(mode: String):
	current_mode = mode

	if mode == "map":
		#add a detector here that triggers if moving is changed and is now false is that possible?
		Anim.play("Idle")

	elif mode == "battle":
		Anim.play("Idle")

# -------------------------
# MAP LOGIC
# -------------------------
func map_update(delta):
	# idle / wandering later
	pass
	
func check_player() -> Vector2i:
	#player has a PlayerHurtBox as collision shape 2d uniqe name
	#and is the Child of this BugEater node's parent
	#check if it is in collision with BugEater's SearchBox which is also an area 2d
		

	for area in SearchBox.get_overlapping_areas():
		if area.name == "PlayerHurtBox":
			var player = area.get_parent()
			print("Player detected:", player.global_position)
			return player.global_position

	return Vector2i(-1, -1)

# -------------------------
# BATTLE LOGIC
# -------------------------
func battle_update(delta):
	# combat logic later
	pass
