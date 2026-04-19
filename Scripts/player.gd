extends Node2D

@onready var EnemyDetection = $%EnemyDetection

var player_pos
var player_clicked: bool = false
var max_movement_points: int = 10
var movement_points: int = max_movement_points

func _ready():
	pass


func _process(_delta):
	pass


func tile_clicked(map_tile):
	await get_tree().create_timer(0.2).timeout
	global_position = map_tile






