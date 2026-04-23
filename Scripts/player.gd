extends Node2D

@onready var EnemyDetection = $%EnemyDetection
@onready var Visible = $%Visible
@onready var Anim = $AnimatedSprite2D
@onready var MainScene = get_tree().current_scene

var player_pos
var player_clicked: bool = false
var max_movement_points: int = 10
var movement_points: int = max_movement_points
var max_battle_movement_points: int = 4
var battle_movement_points: int = max_battle_movement_points
var speed = 200

var max_health: int
var health: int


func _ready():
	Anim.play("Idle")
	max_health = MainScene.max_health
	health = MainScene.health
	
#func _process(_delta):
	#max_health = MainScene.max_health
	#health = MainScene.health


func tile_clicked(map_tile):
	while global_position.distance_to(map_tile) > 2:
		var direction = (map_tile - global_position).normalized()
		global_position += direction * speed * get_process_delta_time()
		await get_tree().process_frame
	
	global_position = map_tile





