extends Node2D

@onready var Anim = $%AnimatedSprite2D
@onready var SearchBox = $SearchBox
@onready var HurtBox = $HurtBox

var enemy_visible = false
var current_mode: String = "map"
var health: int
var enemy_type: String

var max_hit_points: int
var hit_points: int
var hurt_points: int

func _ready():
	if is_in_group("bug_eater"):
		enemy_type = "bug_eater"
		max_hit_points = 1
		hurt_points = 2
	if is_in_group("green_hoplite"):
		enemy_type = "green_hoplite"
		max_hit_points = 5
		hurt_points = 2
	if is_in_group("magma_golem"):
		enemy_type = "magma_golem"
		max_hit_points = 8
		hurt_points = 5
	if is_in_group("pinky"):
		enemy_type = "pinky"
		max_hit_points = 2
		hurt_points = 10

	hit_points = max_hit_points

func _process(delta):
	if current_mode == "map":
		map_update(delta)

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
func map_update(_delta):
	for area in HurtBox.get_overlapping_areas():
		if area.name == "Visible":
			enemy_visible = true
			return
	enemy_visible = false

func check_player() -> Vector2i:
	#player has a PlayerHurtBox as collision shape 2d uniqe name
	#and is the Child of this BugEater node's parent
	#check if it is in collision with BugEater's SearchBox which is also an area 2d
		

	for area in SearchBox.get_overlapping_areas():
		if area.name == "PlayerHurtBox":
			var player = area.get_parent()
			#print("Player detected:", player.global_position)
			return player.global_position

	return Vector2i(-1, -1)

func pythagorean(a: int, b: int) -> float:
	var c: float = sqrt(a*a + b*b)
	return c

func move_to_tile(tile: Vector2i, map: TileMap):
	var current_tile = map.local_to_map(global_position)
	var tile_distance: float = pythagorean(abs(current_tile.x-tile.x), abs(current_tile.y-tile.y))
	
			
	var target_pos = map.map_to_local(tile)
	Anim.play("Walk")
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.2*tile_distance)


	await tween.finished
	Anim.play("Idle")

# -------------------------
# BATTLE LOGIC
# -------------------------

func battle_update() -> bool:
	print("battle update called")
	if hit_points <= 0:
		print(hit_points)
		return true
		#remove_from_group("fighting")
	return false



func _on_anim_finished():
	if Anim.animation != "Walk" and Anim.animation != "Idle":
		Anim.play("Idle")
