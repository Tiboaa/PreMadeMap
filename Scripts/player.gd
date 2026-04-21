extends Node2D

@onready var EnemyDetection = $%EnemyDetection
@onready var Visible = $%Visible
@onready var Anim = $AnimatedSprite2D

var player_pos
var player_clicked: bool = false
var max_movement_points: int = 10
var movement_points: int = max_movement_points
var speed = 200



func _ready():
	Anim.play("Idle")
	
func _process(_delta):
	pass


func tile_clicked(map_tile):
	while global_position.distance_to(map_tile) > 2:
		var direction = (map_tile - global_position).normalized()
		global_position += direction * speed * get_process_delta_time()
		await get_tree().process_frame
	
	global_position = map_tile





