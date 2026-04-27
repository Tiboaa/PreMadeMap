extends Node2D

@onready var Anim = $%AnimatedSprite2D
@onready var SearchBox = $SearchBox
@onready var HurtBox = $HurtBox

var enemy_visible = false
var current_mode: String = "map"
var health: int
var enemy_type: String

@onready var Parent = get_parent()
@onready var MainScene = get_tree().current_scene

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
	for area in SearchBox.get_overlapping_areas():
		if area.name == "PlayerHurtBox":
			var player = area.get_parent()
			return player.global_position

	return Vector2i(-1, -1)

func pythagorean(a: int, b: int) -> float:
	var c: float = sqrt(a*a + b*b)
	return c

func move_to_tile(tile: Vector2i, map: TileMap):
	if hit_points <= 0:
		return
	if tile == Vector2i(-1, -1):
		return
	var current_tile
	if Parent != MainScene:
		current_tile = map.local_to_map(map.to_local(global_position))
	else:
		current_tile = map.local_to_map(global_position)

	var tile_distance: float = pythagorean(abs(current_tile.x-tile.x), abs(current_tile.y-tile.y))
		
	if current_tile.x > tile.x:
		Anim.flip_h = true
	else: Anim.flip_h = false
	
	var target_pos = map.map_to_local(tile)
	if Parent != MainScene:
		target_pos = map.to_global(map.map_to_local(tile))
	else: target_pos = map.map_to_local(tile)
	Anim.play("Walk")
	var tween = create_tween()
	var duration = max(0.05, 0.2 * tile_distance)
	tween.tween_property(self, "global_position", target_pos, duration)


	await tween.finished
	Anim.play("Idle")

# -------------------------
# BATTLE LOGIC
# -------------------------

func battle_update() -> bool:
	if hit_points <= 0:
		return true
	return false



func _on_anim_finished():
	if Anim.animation != "Walk" and Anim.animation != "Idle":
		Anim.play("Idle")
