extends Node2D

var CurrentMap

@onready var SimpleMap = $BattleMapSimple
@onready var RoadMap = $BattleMapRoad
@onready var RiverMap = $BattleMapRiver
@onready var CrossRoadsMap = $BattleMapCrossRoads
@onready var RiverCrossingMap = $BattleMapRiverCrossing

@onready var MainScene = get_tree().current_scene
@onready var Player = $Player

var BugEaterScene = preload("res://Scenes/BugEater.tscn")
var GreenHopliteScene = preload("res://Scenes/GreenHoplite.tscn")
var MagmaGolemScene = preload("res://Scenes/MagmaGolem.tscn")
var PinkyScene = preload("res://Scenes/Pinky.tscn")

var bug_number: int = 0
var hoplite_number: int = 0
var golem_number: int = 0
var pinky_number: int = 0

var bugs_moving: bool = false
var hoplites_moving: bool = false
var golems_moving: bool = false
var pinkies_moving: bool = false

var prev_map_tile: Vector2i
# Called when the node enters the scene tree for the first time.
func _ready():
	CurrentMap = SimpleMap
	CurrentMap.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		MainScene.PauseMenu.visible = true
		get_tree().paused = true

	if not bugs_moving and not hoplites_moving and not golems_moving and not pinkies_moving:
		print("not m")
		# -------------------------
		# HOVER TILE
		# -------------------------
		if event is InputEventMouseMotion:
			var current_map_tile: Vector2i = CurrentMap.local_to_map(get_global_mouse_position())

			if current_map_tile != CurrentMap.local_to_map(Player.position):
				CurrentMap.set_cell(0, current_map_tile, 2, Vector2i(6, 6))

			if prev_map_tile != null and prev_map_tile != current_map_tile and prev_map_tile != CurrentMap.local_to_map(Player.global_position):
				CurrentMap.set_cell(1, prev_map_tile, 1, Vector2i(-1, -1))

			prev_map_tile = current_map_tile
#
		## -------------------------
		## CLICK TO MOVE
		## -------------------------
		#if event is InputEventMouseButton \
		#and event.button_index == MOUSE_BUTTON_LEFT \
		#and event.pressed:
#
			#var click_pos: Vector2 = get_global_mouse_position()
			#var map_tile_clicked: Vector2i = Map.local_to_map(click_pos)
#
			## select/deselect player
			#if Map.local_to_map(Player.global_position) == map_tile_clicked:
				#if not Player.player_clicked:
					#Player.player_clicked = true
					#Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
				#else:
					#Player.player_clicked = false
					#Map.set_cell(1, map_tile_clicked, 1, Vector2i(-1, -1))
#
			## move player
			#elif Player.player_clicked:
				#Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
				#Map.set_cell(1, Map.local_to_map(Player.global_position), 1, Vector2i(-1,-1))
#
				#await get_tree().create_timer(0.5).timeout
				#Map.set_cell(1, map_tile_clicked, 1, Vector2i(-1, -1))
#
				#Player.player_clicked = false
#
				#await move_there(Map.local_to_map(Player.global_position), map_tile_clicked)
				#player_tile = Map.local_to_map(Player.global_position)
#
				#clear_route()
#
				#if prev_player_tile != player_tile:
					#await bug_eater_move()
					#await green_hoplite_move()
					#await magma_golem_move()
					#await pinky_move()
#
				#prev_player_tile = player_tile
#
