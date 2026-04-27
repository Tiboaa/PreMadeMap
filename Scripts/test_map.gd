extends Node2D

@onready var Map = $TileMap
@onready var UI = $BasicUI
@onready var EndCredit = $EndCredit
@onready var ToolBelt = $BasicUI/MapLayer/MapToolbelt
var PauseMenuScene = preload("res://Scenes/PauseMenu.tscn")
var PauseMenu

var BugEaterScene = preload("res://Scenes/BugEater.tscn")
var GreenHopliteScene = preload("res://Scenes/GreenHoplite.tscn")
var MagmaGolemScene = preload("res://Scenes/MagmaGolem.tscn")
var PinkyScene = preload("res://Scenes/Pinky.tscn")
var PlayerScene = preload("res://Scenes/Player.tscn")

var map_size: Vector2i = Vector2i(141,141)
var map_center: int = 70
var map_data: Array

var LandNoise
var TreeNoise
var IronNoise
var MineralsNoise
var StoneNoise
var OilNoise

@onready var Player = $Player

var preview_route: Array = []
var max_preview_distance: Vector2i = Vector2i(-1, -1)

var prev_map_tile: Vector2i
var prev_player_tile: Vector2i
var player_tile: Vector2i = Vector2i(-1, -1)
var bugs_moving: bool = false
var hoplites_moving: bool = false
var golems_moving: bool = false
var pinkies_moving: bool = false

var axe_pressed: bool = false
var pickaxe_pressed: bool = false
var pumpjack_pressed: bool = false
var rocket_pressed: bool = false

var wood_resource: int
var stone_resource: int
var iron_resource: int
var minerals_resource: int
var oil_resource: int

var iron_cost: int = 10
var minerals_cost: int = 2
var stone_cost: int = 10
var wood_cost: int = 10
var oil_cost: int = 10

var rocket_tile: Vector2i = Vector2i(-1, -1)
var rocket_tile_data
var rocket_level: int = -1

var flying: bool = false
var velocity: float = 0.0
var acceleration: float = 300.0

var max_health: int = 100
var health: int = max_health

var battle_map_open: bool = false

func _ready():
	random_generate_map()
	save_map_to_txt()
	PauseMenu = PauseMenuScene.instantiate()
	add_child(PauseMenu)
	PauseMenu.visible = false
	
	while player_tile == Vector2i(-1, -1) or map_data[player_tile.x][player_tile.y][0].contains("ocean") or map_data[player_tile.x][player_tile.y][1] or map_data[player_tile.x][player_tile.y][3] != "":
		Player.global_position = Map.map_to_local(Vector2i(randi_range(50, 90), randi_range(50, 90)))
		if is_tile_occupied(player_tile, "enemy"): continue
		player_tile = Map.local_to_map(Player.global_position)
	prev_player_tile = player_tile
	
	spawn_bug_eaters(120)
	spawn_green_hoplites(70)
	spawn_magma_golems(30)
	spawn_pinkies(55)
	
	UI.axe_changed.connect(_on_axe_changed)
	UI.pickaxe_changed.connect(_on_pickaxe_changed)
	UI.pumpjack_changed.connect(_on_pumpjack_changed)
	UI.rocket_changed.connect(_on_rocket_changed)
	
	wood_resource = 0
	stone_resource = 0
	iron_resource = 0
	minerals_resource = 0
	oil_resource = 0



func _process(delta):
	if !battle_map_open:
		if flying:
			velocity += acceleration * delta
			Player.global_position.y -= velocity * delta
		else: move_compass()



func _unhandled_input(event):
	if flying:
		return
	if event.is_action_pressed("ui_cancel"):
		PauseMenu.visible = true
		get_tree().paused = true
	if battle_map_open:
		return
	if not bugs_moving and not hoplites_moving and not golems_moving and not pinkies_moving:
		if event is InputEventMouseMotion:
			var current_map_tile: Vector2i = Map.local_to_map(get_global_mouse_position())
			if Map.local_to_map(get_global_mouse_position()) != Map.local_to_map(Player.global_position):
				Map.set_cell(1, current_map_tile, 1, Vector2i(6, 6))
			if prev_map_tile != null and prev_map_tile != current_map_tile and prev_map_tile != Map.local_to_map(Player.global_position):
				Map.set_cell(1, prev_map_tile, 1, Vector2i(-1, -1))
			prev_map_tile = current_map_tile
			
		if axe_pressed or pickaxe_pressed or pumpjack_pressed or rocket_pressed:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var click_pos: Vector2 = get_global_mouse_position()
				var map_tile_clicked: Vector2i = Map.local_to_map(click_pos)
				if map_tile_clicked == player_tile:
					Player.player_clicked = true
					if axe_pressed:
						axe_pressed = false
						UI.get_node("MapLayer/MapToolbelt/Axe/Button").button_pressed = false
					if pickaxe_pressed:
						pickaxe_pressed = false
						UI.get_node("MapLayer/MapToolbelt/Pickaxe/Button").button_pressed = false
					if pumpjack_pressed:
						pumpjack_pressed = false
						UI.get_node("MapLayer/MapToolbelt/Pumpjack/Button").button_pressed = false
					if rocket_pressed:
						rocket_pressed = false
						UI.get_node("MapLayer/MapToolbelt/Rocket/Button").button_pressed = false
					Map.set_cell(1, player_tile, 1, Vector2i(5, 6))
				elif abs(map_tile_clicked.x - player_tile.x) <= 1 and abs(map_tile_clicked.y - player_tile.y) <= 1:
					var cta_coords: Vector2i = Map.get_cell_atlas_coords(2, map_tile_clicked)
					if axe_pressed:
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
						if map_data[map_tile_clicked.x][map_tile_clicked.y][3] == "tree":
							if map_data[map_tile_clicked.x][map_tile_clicked.y][4]:
								map_data[map_tile_clicked.x][map_tile_clicked.y][3] = ""
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = false
								map_data[map_tile_clicked.x][map_tile_clicked.y][5] = 2
								Map.set_cell(2, map_tile_clicked, 1, Vector2i(-1, -1))
								wood_resource += 2
							else:
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = true
								if cta_coords.x == 12:
									Map.set_cell(2, map_tile_clicked, 1, Vector2i(cta_coords.x, cta_coords.y+6))
								else:
									Map.set_cell(2, map_tile_clicked, 1, Vector2i(cta_coords.x+1, cta_coords.y+6))
								wood_resource += 10
						else:
							UI.TooFar.visible = true
							await get_tree().create_timer(2).timeout
							UI.TooFar.visible = false
						UI.update_resources()
					if pickaxe_pressed:
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
						var type_of_rock = map_data[map_tile_clicked.x][map_tile_clicked.y][3]
						if type_of_rock == "stone" or type_of_rock == "iron_ore" or type_of_rock == "minerals":
							if map_data[map_tile_clicked.x][map_tile_clicked.y][4]:
								map_data[map_tile_clicked.x][map_tile_clicked.y][3] = ""
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = false
								map_data[map_tile_clicked.x][map_tile_clicked.y][5] = 2
								Map.set_cell(2, map_tile_clicked, 1, Vector2i(-1, -1))
								match type_of_rock:
									"stone":
										stone_resource += 2
									"iron_ore":
										iron_resource += 2
									"minerals":
										minerals_resource += 2
							else:
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = true
								Map.set_cell(2, map_tile_clicked, 1, Vector2i(cta_coords.x, cta_coords.y+1))
								match type_of_rock:
									"stone":
										stone_resource += 10
									"iron_ore":
										iron_resource += 10
									"minerals":
										minerals_resource += 10
						else:
							UI.TooFar.visible = true
							await get_tree().create_timer(2).timeout
							UI.TooFar.visible = false
						UI.update_resources()
					if pumpjack_pressed:
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
						if map_data[map_tile_clicked.x][map_tile_clicked.y][3] == "crude_oil":
							if map_data[map_tile_clicked.x][map_tile_clicked.y][4]:
								map_data[map_tile_clicked.x][map_tile_clicked.y][3] = ""
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = false
								map_data[map_tile_clicked.x][map_tile_clicked.y][5] = 2
								Map.set_cell(2, map_tile_clicked, 1, Vector2i(-1, -1))
								oil_resource += 2
							else:
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = true
								Map.set_cell(2, map_tile_clicked, 1, Vector2i(cta_coords.x, cta_coords.y+1))
								oil_resource += 10
						
						else:
							UI.TooFar.visible = true
							await get_tree().create_timer(2).timeout
							UI.TooFar.visible = false
						UI.update_resources()
					if rocket_pressed:
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
						if map_data[map_tile_clicked.x][map_tile_clicked.y] == ["grass",false,false,"rocket",true,2] and rocket_tile == map_tile_clicked:
							if rocket_level % 2 == 0 and iron_cost <= iron_resource and minerals_cost <= minerals_resource:
								iron_resource -= iron_cost
								minerals_resource -= minerals_cost
								UI.update_resources()
								rocket_level += 1
								
								if rocket_level <=3:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 2))
								elif rocket_level <= 9:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 1))
								elif rocket_level <= 13:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 0))
									if rocket_level == 13:
										map_data[map_tile_clicked.x][map_tile_clicked.y][4] = false
							elif rocket_level % 2 == 0:
								if iron_cost > iron_resource:
									UI.NotEnough.visible = true
									await get_tree().create_timer(2).timeout
									UI.NotEnough.visible = false
								if minerals_cost > minerals_resource:
									UI.NotEnough.visible = true
									await get_tree().create_timer(2).timeout
									UI.NotEnough.visible = false
									
							elif rocket_level % 2 == 1 and wood_cost <= wood_resource:
								wood_resource -= wood_cost
								UI.update_resources()
								rocket_level += 1
								
								if rocket_level <=3:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 2))
								elif rocket_level <= 9:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 1))
								elif rocket_level <= 13:
									Map.set_cell(2, map_tile_clicked, 3, Vector2i(rocket_level, 0))
									if rocket_level == 13:
										map_data[map_tile_clicked.x][map_tile_clicked.y][4] = false
							elif rocket_level % 2 == 1:
								UI.NotEnough.visible = true
								await get_tree().create_timer(2).timeout
								UI.NotEnough.visible = false
								
						elif map_data[map_tile_clicked.x][map_tile_clicked.y] == ["grass",false,false,"rocket",false,2] and rocket_tile == map_tile_clicked:
							if oil_resource >= 10:
								launch_rocket()
							else:
								UI.NotEnough.visible = true
								await get_tree().create_timer(2).timeout
								UI.NotEnough.visible = false
							
						elif map_data[map_tile_clicked.x][map_tile_clicked.y] == ["grass",false,false,"",false,2] and (rocket_tile == map_tile_clicked or rocket_tile == Vector2i(-1, -1)):
							if stone_cost <= stone_resource:
								stone_resource -= stone_cost
								UI.update_resources()
								rocket_tile = map_tile_clicked
								rocket_level = 0
								Map.set_cell(2, map_tile_clicked, 3, Vector2i(0, 2))
								map_data[map_tile_clicked.x][map_tile_clicked.y][3] = "rocket"
								map_data[map_tile_clicked.x][map_tile_clicked.y][4] = true
							else:
								UI.NotEnough.visible = true
								await get_tree().create_timer(2).timeout
								UI.NotEnough.visible = false
						else:
							UI.TooFar.visible = true
							await get_tree().create_timer(2).timeout
							UI.TooFar.visible = false

		else:
			if event is InputEventMouseMotion and Player.player_clicked:
				var current_map_tile: Vector2i = Map.local_to_map(get_global_mouse_position())

				if current_map_tile != Map.local_to_map(Player.global_position):
					var route = get_preview_path(Map.local_to_map(Player.global_position), current_map_tile)

					if route.size() > 0:
						draw_preview(route)
			
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var click_pos: Vector2 = get_global_mouse_position()
				var map_tile_clicked: Vector2i = Map.local_to_map(click_pos)
				if Map.local_to_map(Player.global_position) == map_tile_clicked:
					if Player.player_clicked == false:
						Player.player_clicked = true
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
					elif Player.player_clicked == true:
						Player.player_clicked = false
						Map.set_cell(1, map_tile_clicked, 1, Vector2i(-1, -1))
				elif Player.player_clicked == true and Map.local_to_map(Player.global_position) != map_tile_clicked:
					Map.set_cell(1, map_tile_clicked, 1, Vector2i(5, 6))
					Map.set_cell(1, Map.local_to_map(Player.global_position), 1, Vector2i(-1,-1))

					await get_tree().create_timer(0.5).timeout
					Map.set_cell(1, map_tile_clicked, 1, Vector2i(-1, -1))
					Player.player_clicked = false
					await move_there(Map.local_to_map(Player.global_position), map_tile_clicked)
					player_tile = Map.local_to_map(Player.global_position)
					clear_route()
					if prev_player_tile != player_tile:
						await bug_eater_move()
						await green_hoplite_move()
						await magma_golem_move()
						await pinky_move()
					prev_player_tile = player_tile
					start_fighting()


# -------------------------
# MAP GENERATION
# -------------------------

func random_generate_map():
	map_data = []
	
	LandNoise = FastNoiseLite.new()
	LandNoise.frequency = 0.005
	LandNoise.seed = randi()
	
	TreeNoise = FastNoiseLite.new()
	TreeNoise.frequency = 0.5
	TreeNoise.seed = randi()
	
	IronNoise = FastNoiseLite.new()
	IronNoise.frequency = 0.5
	IronNoise.seed = randi()
	
	MineralsNoise = FastNoiseLite.new()
	MineralsNoise.frequency = 0.5
	MineralsNoise.seed = randi()
	
	StoneNoise = FastNoiseLite.new()
	StoneNoise.frequency = 0.5
	StoneNoise.seed = randi()
	
	OilNoise = FastNoiseLite.new()
	OilNoise.frequency = 0.5
	OilNoise.seed = randi()
	
	while random_generate_ocean() >= 13000:
		LandNoise.seed = randi()
		
	random_generate_rivers()
	random_generate_roads()
	random_generate_resources()
	
	build_map()

func get_neighbors(tile: Vector2i):

	#n, e, s, w
	
	var neighbor_north = Vector2i(tile.x, tile.y - 1)
	var neighbor_east = Vector2i(tile.x + 1, tile.y)
	var neighbor_south = Vector2i(tile.x, tile.y + 1)
	var neighbor_west = Vector2i(tile.x - 1, tile.y)
	
	var neighbors = [neighbor_north, neighbor_east, neighbor_south, neighbor_west]

	return neighbors

func random_generate_ocean() -> int:
	map_data = []
	var ocean_tiles = 0
	for x in map_size.x:
		map_data.append([])
		for y in map_size.y:
			map_data[x].append([])
			var land = LandNoise.get_noise_2d(x, y)
			if land < 0:
				map_data[x][y] = ["ocean"]
				ocean_tiles += 1
			else:
				if pythagorean(abs(map_center-x), abs(map_center-y)) > map_center - 12:
					ocean_tiles += 1
					if pythagorean(abs(map_center-x), abs(map_center-y)) > map_center - 6:
						map_data[x][y] = ["deep_ocean"]
					else : map_data[x][y] = ["ocean"]
				else: map_data[x][y] = ["grass"]
	return ocean_tiles

func make_it_a_river(pos_x, pos_y) -> bool:
	if pos_x < 1 or pos_y < 1 or pos_x > 140 or pos_y > 140:
		return false
	if map_data[pos_x][pos_y][1] == true:
		return true
	if map_data[pos_x][pos_y][0] != "ocean":
		map_data[pos_x][pos_y][1] = true
	return false

func random_generate_rivers():
	for x in map_size.x:
		for y in map_size.y:
			map_data[x][y].append(false)
			
	var gap = 0
	for i in randi_range(4, 7):
		
		var pos_x: int = randi_range(1 + gap, 20 + gap) 
		var pos_y: int = randi_range(1, 100) 
		gap += 25
		while pos_x < map_size.x-10 and pos_y < map_size.y-10:
			var first_choice: int = randi() % 2
			for first in randi_range(2, 4):
				if first_choice == 0: pos_y += 1
				else: pos_x += 1
				
				if make_it_a_river(pos_x, pos_y):
					break

			var second_choice: int = randi() % 2
			for second in randi_range(4, 8):
				if second_choice == 0: pos_y += 1
				else: pos_x += 1
				
				if make_it_a_river(pos_x, pos_y):
					break

			var third_choice: int = randi() % 3
			if third_choice == 0:
				pos_y += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
			else:
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y += 1
				if make_it_a_river(pos_x, pos_y):
					break
					
				if third_choice == 2:
					pos_x += 1
					if make_it_a_river(pos_x, pos_y):
						break
					pos_y += 1
					if make_it_a_river(pos_x, pos_y):
						break
					pos_y += 1
					if make_it_a_river(pos_x, pos_y):
						break
					pos_x -= 1
					if make_it_a_river(pos_x, pos_y):
						break
					pos_y += 1
					if make_it_a_river(pos_x, pos_y):
						break
					pos_y += 1
					if make_it_a_river(pos_x, pos_y):
						break
					
	
	gap = 0
	for i in randi_range(4, 7):
		
		var pos_y: int = randi_range(map_size.y-100, map_size.y) 
		var pos_x: int = randi_range(1, 100) 
		gap += 20
		while pos_x < map_size.x and pos_y > 0:
			var first_choice: int = randi() % 2
			if first_choice == 0:
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
			else:
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
					
			var second_choice: int = randi() % 5
			if second_choice == 0:
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y -= 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_y += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
			else:
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break
				pos_x += 1
				if make_it_a_river(pos_x, pos_y):
					break

func random_generate_roads():
	var pos_x: int
	var pos_y: int

	for x in map_size.x:
		for y in map_size.y:
			map_data[x][y].append(false)
	var gap: int = 0
	for i in 3:
		gap += map_size.y/4
		pos_y = randi_range(0+gap, map_size.y/4+gap)
		for x in map_size.x:
			for y in map_size.y:
				if y == pos_y:
					if map_data[x][y][0] == "grass":
						map_data[x][y][2] = true
						if map_data[x+1][y][1] and map_data[x+2][y][1]:
							pos_y += 1
							y += 1
							map_data[x][y][2] = true
						else:
							var chance = randi() %20
							if chance == 0:
								pos_y += 1
								x += 1
								map_data[x][y][2] = true
	gap = 0
	for i in 5:
		gap += map_size.y/8
		pos_x = randi_range(0+gap, map_size.y/8+gap)
		for y in map_size.y:
			for x in map_size.x:
				if x == pos_x:
					if map_data[x][y][0] == "grass":
						map_data[x][y][2] = true
						if map_data[x][y+1][1] and map_data[x][y+2][1]:
							pos_x += 1
							x += 1
							map_data[x][y][2] = true
						if map_data[x+1][y][2]:
							pos_x += randi_range(1,8)
							y += 1
						if y%4 ==0:
							if randi()% 20 ==0:
								for j in randi_range(5,20):
									if not map_data[x+j][y][1] and not map_data[x+j+1][y][1]:
										map_data[x+j][y][2] = true
									else: break

func random_generate_resources():
	for x in map_size.x:
		for y in map_size.y:
			map_data[x][y].append("")
			map_data[x][y].append(false)
			map_data[x][y].append(100)
	for x in map_size.x:
		for y in map_size.y:
			if map_data[x][y][0] == "grass" and map_data[x][y][1] == false and map_data[x][y][2] == false:
				var tree = TreeNoise.get_noise_2d(x, y)
				var iron_ore = IronNoise.get_noise_2d(x, y)
				var minerals = MineralsNoise.get_noise_2d(x, y)
				var stone = StoneNoise.get_noise_2d(x, y)
				var crude_oil = OilNoise.get_noise_2d(x, y)
				if tree < -0.45:
					map_data[x][y][3] = "tree"
				if map_data[x][y][3] == "" and iron_ore < -0.45:
					map_data[x][y][3] = "iron_ore"
				if map_data[x][y][3] == "" and minerals < -0.5:
					map_data[x][y][3] = "minerals"
				if map_data[x][y][3] == "" and stone < -0.55:
					map_data[x][y][3] = "stone"
				if map_data[x][y][3] == "" and crude_oil < -0.58:
					map_data[x][y][3] = "crude_oil"
				if map_data[x][y][3] != "":
					var is_depleted = randi() % 10
					if is_depleted == 0:
						map_data[x][y][4] = true

func build_map():
	var neighbors
	var atlas_coords
	var resource_atlas_coords
	var river_neighbors
	var road_neighbors: Array
	var ocean_neighbors
	var ocean_neighbors_num: int
	var river_neighbors_num: int
	for x in map_size.x:
		for y in map_size.y:
			resource_atlas_coords = Vector2i(-1,-1)
			if map_data[x][y][0] == "grass":
				if map_data[x][y][1] == false:
					if map_data[x][y][2] == true:
						neighbors = get_neighbors(Vector2i(x,y))
						road_neighbors = []
						for i in neighbors:
							if map_data[i.x][i.y][2]:
								road_neighbors.append(true)
							else: road_neighbors.append(false)
						atlas_coords = choose_road(road_neighbors)
						map_data[x][y][5] = 1
					else:
						atlas_coords = Vector2i(randi() % 8, randi() % 3)
						map_data[x][y][5] = 2
						if map_data[x][y][3] == "tree":
							map_data[x][y][5] = 3
							if map_data[x][y][4]:
								resource_atlas_coords = Vector2i(1 + (randi() % 4) * 3 ,6)
							else:
								resource_atlas_coords = Vector2i((randi() % 5) * 3, 0)
						elif map_data[x][y][3] == "stone":
							map_data[x][y][5] = 3
							if map_data[x][y][4]:
								resource_atlas_coords = Vector2i(randi_range(0, 4), 8)
							else:
								resource_atlas_coords = Vector2i(randi_range(0, 4), 7)
						elif map_data[x][y][3] == "iron_ore":
							map_data[x][y][5] = 3
							if map_data[x][y][4]:
								resource_atlas_coords = Vector2i(randi_range(0, 4), 10)
							else:
								resource_atlas_coords = Vector2i(randi_range(0, 4), 9)
						elif map_data[x][y][3] == "minerals":
							map_data[x][y][5] = 3
							if map_data[x][y][4]:
								resource_atlas_coords = Vector2i(randi_range(7, 11), 8)
							else:
								resource_atlas_coords = Vector2i(randi_range(7, 11), 7)
						elif map_data[x][y][3] == "crude_oil":
							map_data[x][y][5] = 3
							if map_data[x][y][4]:
								resource_atlas_coords = Vector2i(randi_range(7, 11), 10)
							else:
								resource_atlas_coords = Vector2i(7, 9)
						else: resource_atlas_coords = Vector2i(-1,-1)
						
						
									
						
							
				elif map_data[x][y][1] == true:
					if map_data[x][y][2] == true:
						neighbors = get_neighbors(Vector2i(x,y))
						road_neighbors = []
						river_neighbors = []
						for i in neighbors:
							if map_data[i.x][i.y][2]:
								road_neighbors.append(true)
							else: road_neighbors.append(false)
							if map_data[i.x][i.y][1]:
								river_neighbors.append(true)
							else: river_neighbors.append(false)
							
						if road_neighbors[0] and road_neighbors[2] and river_neighbors[1] and river_neighbors[3]:
							atlas_coords = Vector2i(randi_range(0,1), 12)
							map_data[x][y][5] = 1
						elif road_neighbors[1] and road_neighbors[3] and river_neighbors[0] and river_neighbors[2]:
							atlas_coords = Vector2i(randi_range(4,5), 12)
							map_data[x][y][5] = 1
						else: map_data[x][y][2] = false
						
						
					if map_data[x][y][2] == false:
						neighbors = get_neighbors(Vector2i(x,y))
						river_neighbors = []
						river_neighbors_num = 0
						ocean_neighbors_num = 0
						for i in neighbors:
							if map_data[i.x][i.y][1]:
								river_neighbors.append(true)
								river_neighbors_num += 1
							elif map_data[i.x][i.y][0] == "ocean":
								river_neighbors.append(true)
								ocean_neighbors_num += 1
							else: river_neighbors.append(false)
						atlas_coords = choose_river(river_neighbors)
						map_data[x][y][5] = 100
						if atlas_coords == Vector2i(-1, -1):
							map_data[x][y][0] = "ocean"
							map_data[x][y][1] = false
							atlas_coords = Vector2i(7,17)
							map_data[x][y][5] = 100
							
						
			elif map_data[x][y][0] == "ocean":
				atlas_coords = Vector2i(7,17)
				map_data[x][y][5] = 100
			elif map_data[x][y][0] == "deep_ocean":
				atlas_coords = Vector2i(6,17)
				map_data[x][y][5] = 100
			Map.set_cell(0, Vector2i(x,y), 0, atlas_coords)
			Map.set_cell(2, Vector2i(x,y), 1, resource_atlas_coords)
	
	var do_it = true
	while do_it:
		do_it = false
		var to_ocean = []
		for x in map_size.x:
			for y in map_size.y:
				if map_data[x][y][0] == "grass":
					if map_data[x][y][1]:
						neighbors = get_neighbors(Vector2i(x,y))
						ocean_neighbors_num = 0
						river_neighbors_num = 0
						for i in neighbors:
							if map_data[i.x][i.y][1]:
								river_neighbors_num += 1
							if map_data[i.x][i.y][0] == "ocean":
								ocean_neighbors_num += 1
						if river_neighbors_num >=2 and ocean_neighbors_num >=1:
							to_ocean.append(Vector2i(x, y))
						if river_neighbors_num >=1 and ocean_neighbors_num >=2:
							to_ocean.append(Vector2i(x, y))
		
		for tile in to_ocean:
			do_it = true
			map_data[tile.x][tile.y][0] = "ocean"
			map_data[tile.x][tile.y][1] = false
			atlas_coords = Vector2i(7,17)
			map_data[tile.x][tile.y][5] = 100
			Map.set_cell(0, Vector2i(tile.x,tile.y), 0, atlas_coords)

func choose_road(road_neighbors) -> Vector2i:
	#1
	if road_neighbors == [false, false, false, true]:
		return Vector2i(7, 14)
	if road_neighbors == [false, false, true, false]:
		return Vector2i(6, 13)
	if road_neighbors == [false, true, false, false]:
		return Vector2i(6, 14)
	if road_neighbors == [true, false, false, false]:
		return Vector2i(7, 13)
	#2
	if road_neighbors == [true, false, true, false]:
		return Vector2i(randi_range(0, 5), 13)
	if road_neighbors == [false, true, false, true]:
		return Vector2i(randi_range(0, 5), 14)
	#2 corners
	if road_neighbors == [true, true, false, false]:
		return Vector2i(randi_range(0, 1), 15)
	if road_neighbors == [ false, true, true, false]:
		return Vector2i(randi_range(4, 5), 15)
	if road_neighbors == [false, false, true, true]:
		return Vector2i(randi_range(6, 7), 15)
	if road_neighbors == [true, false, false, true]:
		return Vector2i(randi_range(2, 3), 15)
	#3
	if road_neighbors == [true, true, true, false]:
		return Vector2i(randi_range(0, 1), 16)
	if road_neighbors == [ false, true, true, true]:
		return Vector2i(randi_range(6, 7), 16)
	if road_neighbors == [true, false, true, true]:
		return Vector2i(randi_range(2, 3), 16)
	if road_neighbors == [true, true, false, true]:
		return Vector2i(randi_range(4, 5), 16)
	
	return Vector2i(randi_range(0, 1), 17) # RETURN 4

func choose_river(river_neighbors) -> Vector2i:
	#1
	if river_neighbors == [false, false, false, true]:
		return Vector2i(randi_range(6,7), 3)
	if river_neighbors == [false, false, true, false]:
		return Vector2i(randi_range(2,3), 3)
	if river_neighbors == [false, true, false, false]:
		return Vector2i(randi_range(4,5), 3)
	if river_neighbors == [true, false, false, false]:
		return Vector2i(randi_range(0,1), 3)
	#2
	if river_neighbors == [true, false, true, false]:
		return Vector2i(randi_range(0, 7), 6)
	if river_neighbors == [false, true, false, true]:
		return Vector2i(randi_range(0, 7), 4)
	#2 corners
	if river_neighbors == [true, true, false, false]:
		return Vector2i(randi_range(0, 1), 9)
	if river_neighbors == [ false, true, true, false]:
		return Vector2i(randi_range(4, 5), 9)
	if river_neighbors == [false, false, true, true]:
		return Vector2i(randi_range(6, 7), 9)
	if river_neighbors == [true, false, false, true]:
		return Vector2i(randi_range(2, 3), 9)
	#3
	if river_neighbors == [true, true, true, false]:
		return Vector2i(4, 10)
	if river_neighbors == [ false, true, true, true]:
		return Vector2i(5, 10)
	if river_neighbors == [true, false, true, true]:
		return Vector2i(7, 10)
	if river_neighbors == [true, true, false, true]:
		return Vector2i(6, 10)
	
	return Vector2i(-1 , -1) # RETURN 4


func pythagorean(a: int, b: int) -> float:
	var c: float = sqrt(a*a + b*b)
	return c


# -------------------------
# FILE SAVE
# -------------------------

func save_map_temp(): 
	var path = "C:/Users/tibi2/OneDrive/Documents/godot/Szakdoga/PreMadeMap/SaveFiles/map.json"
	var json_string = JSON.stringify(map_data)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		pass

func save_map_to_txt():
	var file = FileAccess.open("user://map_data.txt", FileAccess.WRITE)
	var content: String = ""
	content +=  "[\n"
	for x in map_size.x:
		content += "\t[\n"
		content += "\t\t" + str(map_data[x]) + "\n"
	file.store_string(content)

# -------------------------
# PLAYER MOVEMENT
# -------------------------
func add_player():
	Player = PlayerScene.instantiate()
	var tile = player_tile
	var pos = Map.map_to_local(tile)

	Player.global_position = pos
	add_child(Player)
	battle_map_open = false
	UI.get_node("MapLayer").visible = true
	UI.get_node("BattleLayer").visible = false

func move_there(start_tile: Vector2i, destination: Vector2i):
	if is_tile_occupied(destination, "enemy"):
		return
	var is_water = map_data[destination.x][destination.y][5] == 100
	
	if is_water:
		return
		
	var tiles = [start_tile]
	var came_from = {}
	var g_distance = {}
	var f_distance = {}
	g_distance[start_tile] = 0
	f_distance[start_tile] = heuristic(start_tile, destination)
	
	while tiles.size() > 0:
		var current = tiles[0]
		for tile in tiles:
			if f_distance.get(tile, INF) < f_distance.get(current, INF):
				current = tile

		if current == destination:
			var route = reconstruct_path(came_from, current)

			for i in range(1, route.size()):
				var tile = route[i]
				if Player.movement_points >= map_data[tile.x][tile.y][5]:
					await Player.tile_clicked(Map.map_to_local(tile))
				else:
					Player.movement_points = Player.max_movement_points
					return
				Player.movement_points -= map_data[tile.x][tile.y][5]
			Player.movement_points = Player.max_movement_points
			return
		
		tiles.erase(current)
		
		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue
			if map_data[neighbor.x][neighbor.y][5] == 100:
				continue

			var g_cost = g_distance.get(current, INF) + map_data[neighbor.x][neighbor.y][5]
			if g_cost < g_distance.get(neighbor, INF):
				came_from[neighbor] = current
				g_distance[neighbor] = g_cost
				f_distance[neighbor] = g_cost + heuristic(neighbor, destination)

				if neighbor not in tiles:
					tiles.append(neighbor)

func heuristic(start_tile: Vector2i, destination: Vector2i) -> int:
	return abs(start_tile.x - destination.x) + abs(start_tile.y - destination.y)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var chosen_path = [current]
	
	while current in came_from:
		current = came_from[current]
		chosen_path.insert(0, current)
	return chosen_path

func get_preview_path(start_tile: Vector2i, destination: Vector2i) -> Array:
	var tiles = [start_tile]
	var came_from = {}

	var g_distance = {}
	var f_distance = {}

	g_distance[start_tile] = 0
	f_distance[start_tile] = heuristic(start_tile, destination)

	while tiles.size() > 0:
		var current = tiles[0]
		for tile in tiles:
			if f_distance.get(tile, INF) < f_distance.get(current, INF):
				current = tile

		if current == destination:
			return reconstruct_path(came_from, current)

		tiles.erase(current)

		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue

			if map_data[neighbor.x][neighbor.y][5] == 100:
				continue

			var g_cost = g_distance.get(current, INF) + map_data[neighbor.x][neighbor.y][5]

			if g_cost < g_distance.get(neighbor, INF):
				came_from[neighbor] = current
				g_distance[neighbor] = g_cost
				f_distance[neighbor] = g_cost + heuristic(neighbor, destination)

				if neighbor not in tiles:
					tiles.append(neighbor)

	return []

func draw_preview(route: Array):
	clear_preview()
	if route.size() < 2:
		return

	var allowed_route: Array = []
	var remaining = Player.movement_points

	allowed_route.append(route[0])

	for i in range(1, route.size()):
		var tile = route[i]
		var cost = map_data[tile.x][tile.y][5]

		if remaining < cost:
			break
		remaining -= cost
		allowed_route.append(tile)

	for i in range(1, allowed_route.size() - 1):
		var prev = allowed_route[i - 1]
		var current = allowed_route[i]
		var next = allowed_route[i + 1]

		var coord: Vector2i = get_direction_tile(prev, current, next)
		Map.set_cell(3, current, 2, coord)
	
	max_preview_distance = allowed_route[allowed_route.size()-1]
	Map.set_cell(1, max_preview_distance, 1, Vector2i(5, 6))
	
	for i in range(allowed_route.size(), route.size() - 1):
		var prev = route[i - 1]
		var current = route[i]
		var next = route[i + 1]

		var coord: Vector2i = get_direction_tile(prev, current, next)
		coord = Vector2i(coord.x + 2, coord.y)
		Map.set_cell(3, current, 2, coord)

	preview_route = route

func clear_preview():
	Map.set_cell(1, max_preview_distance, 1, Vector2i(-1, -1))
	for tile in preview_route:
		Map.set_cell(3, tile, 1, Vector2i(-1, -1))

	preview_route.clear()

func clear_route():
	Map.set_cell(1, max_preview_distance, 1, Vector2i(-1, -1))
	for tile in Map.get_used_cells(3):
		Map.set_cell(3, tile, 1, Vector2i(-1, -1))

func get_direction_tile(prev: Vector2i, current: Vector2i, next: Vector2i) -> Vector2i:
	var from_dir_x = current.x - prev.x
	var from_dir_y = current.y - prev.y

	var to_dir_x = next.x - current.x
	var to_dir_y = next.y - current.y
	
	if from_dir_x == 0 and to_dir_x == 0:
		return Vector2i(1, 2)
	if from_dir_y == 0 and to_dir_y == 0:
		return Vector2i(0, 2)
	# corners
	if (from_dir_x == 1 and to_dir_y == 1) or (from_dir_y == -1 and to_dir_x == -1):
		return Vector2i(1, 0)
	if (from_dir_x == -1 and to_dir_y == 1) or (from_dir_y == -1 and to_dir_x == 1):
		return Vector2i(0, 0) 
	if (from_dir_x == 1 and to_dir_y == -1) or (from_dir_y == 1 and to_dir_x == -1):
		return Vector2i(1, 1)
	if (from_dir_x == -1 and to_dir_y == -1) or (from_dir_y == 1 and to_dir_x == 1):
		return Vector2i(0, 1) 

	return Vector2i(-1, -1)

# -------------------------
# ENEMIES
# -------------------------

func start_fighting():
	var bug_num: int = 0
	var hoplite_num: int = 0
	var golem_num: int = 0
	var pinky_num: int = 0
	for fighter in get_tree().get_nodes_in_group("fighting"):
		if fighter.is_in_group("bug_eater"): bug_num += 1
		if fighter.is_in_group("green_hoplite"): hoplite_num += 1
		if fighter.is_in_group("magma_golem"): golem_num += 1
		if fighter.is_in_group("pinky"): pinky_num += 1
		fighter.queue_free()
	if bug_num != 0 or hoplite_num != 0 or golem_num != 0 or pinky_num != 0:
		battle_map_open = true
		Map.visible = false
		
		UI.get_node("MapLayer").visible = false
		UI.get_node("BattleLayer").visible = true
		
		var battle_scene = preload("res://Scenes/BattleMap.tscn").instantiate()
		Player.queue_free()
		add_child(battle_scene)
		battle_scene.collect_fighters(bug_num, hoplite_num, golem_num, pinky_num)
		battle_scene.spawn_fighters()
		battle_scene.move_the_enemies()

func enemy_moving(enemy, target_tile):
	if enemy.enemy_visible:
		await enemy.move_to_tile(target_tile, Map)
	else: enemy.global_position = Map.map_to_local(target_tile)

func is_tile_occupied(tile: Vector2i, by_who: String) -> bool:
	for unit in get_tree().get_nodes_in_group(by_who):
		var unit_tile = Map.local_to_map(unit.global_position)
		if unit_tile == tile:
			return true
	if map_data[tile.x][tile.y][3] != "":
		return true
	return false

func get_random_tile(center: Vector2i, type: String) -> Vector2i:
	var attempts = 0
	if type == "bug_eater":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 9 - 4
			var offset_y = randi() % 9 - 4
			var tile = center + Vector2i(offset_x, offset_y)

			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]

			if ground_type != "grass":
				continue
			if is_river:
				continue
			if is_road:
				continue
			if is_tile_occupied(tile, "character"):
				continue

			return tile

	if type == "green_hoplite":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 9 - 4
			var offset_y = randi() % 9 - 4
			var tile = center + Vector2i(offset_x, offset_y)

			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]

			if ground_type != "grass":
				continue
			if is_river:
				continue
			if not is_road:
				continue
			if is_tile_occupied(tile, "character"):
				continue

			return tile

	if type == "magma_golem":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 5 - 2
			var offset_y = randi() % 5 - 2
			var tile = center + Vector2i(offset_x, offset_y)

			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]

			if ground_type != "grass":
				continue
			if is_river:
				continue
			if not is_road:
				continue
			if is_tile_occupied(tile, "character"):
				continue

			return tile

	if type == "pinky":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 11 - 6
			var offset_y = randi() % 11 - 6
			var tile = center + Vector2i(offset_x, offset_y)

			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]

			if ground_type != "grass":
				continue
			if is_river and not is_road:
				continue
			if is_tile_occupied(tile, "character"):
				continue

			return tile

	return Vector2i(-1, -1)

func move_closer_to_player(center: Vector2i, type: String) -> Vector2i:

	var valid_tiles = []
	var best_value = 100
	var closest_tile = Vector2i(-1, -1)
	for i in 5:
		valid_tiles.append([])
		for j in 5:
			valid_tiles[i].append(Vector2i(center.x-2+i, center.y-2+j))
	for row in valid_tiles:
		for tile in row:
			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]
			if type == "bug_eater":
				if ground_type != "grass":
					continue
				if is_river:
					continue
				if is_road:
					continue
				if is_tile_occupied(tile, "character"):
					continue

			if type == "green_hoplite" or type == "magma_golem":
				if ground_type != "grass":
					continue
				if is_river and not is_road:
					continue
				if not is_road:
					continue
				if is_tile_occupied(tile, "character"):
					continue
					
			if type == "pinky":
				if ground_type != "grass":
					continue
				if is_river and not is_road:
					continue
				if is_tile_occupied(tile, "character"):
					continue

			var value = heuristic(tile, player_tile)
			if value < best_value:
				closest_tile = tile
				best_value = value
	return closest_tile
	
# -------------------------
# BUGEATER
# -------------------------
func get_random_bug_eater_tile() -> Vector2i:
	var attempts = 0

	while attempts < 1000:
		attempts += 1

		var x = randi() % map_size.x
		var y = randi() % map_size.y
		var tile = Vector2i(x, y)

		var data = map_data[x][y]

		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if ground_type != "grass":
			continue
		if is_river:
			continue
		if is_road:
			continue
		if is_tile_occupied(tile, "character"):
			continue

		return tile
	return Vector2i(-1, -1)

func spawn_bug_eaters(count: int):
	for i in range(count):
		var bug = BugEaterScene.instantiate()

		var tile = get_random_bug_eater_tile()
		if tile != Vector2i(-1, -1):
			var pos = Map.map_to_local(tile)

			bug.global_position = pos
			add_child(bug)
			bug.set_mode("map")

func bug_eater_move():
	bugs_moving = true
	var type = "bug_eater"
	for bug in get_tree().get_nodes_in_group(type):
		var current_tile = Map.local_to_map(bug.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		if bug.check_player() != Vector2i(-1, -1):
			bug.add_to_group("fighting")
			target_tile = move_closer_to_player(current_tile, type)
		else:
			target_tile = get_random_tile(current_tile, type)
		var direction = target_tile.x - current_tile.x
		if direction < 0:
			bug.Anim.flip_h = true
		elif direction > 0:
			bug.Anim.flip_h = false
		await enemy_moving(bug, target_tile)
	bugs_moving = false
# -------------------------
# GREEN HOPLITE
# -------------------------
func get_random_green_hoplite_tile() -> Vector2i:
	var attempts = 0

	while attempts < 1000:
		attempts += 1

		var x = randi() % map_size.x
		var y = randi() % map_size.y
		var tile = Vector2i(x, y)

		var data = map_data[x][y]

		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if ground_type != "grass":
			continue
		if is_river and not is_road:
			continue
		if not is_road:
			continue
		if is_tile_occupied(tile, "character"):
			continue

		return tile
	return Vector2i(-1, -1)

func spawn_green_hoplites(count: int):
	for i in range(count):
		var hoplite = GreenHopliteScene.instantiate()

		var tile = get_random_green_hoplite_tile()
		if tile != Vector2i(-1, -1):
			var pos = Map.map_to_local(tile)

			hoplite.global_position = pos
			add_child(hoplite)
			hoplite.set_mode("map")

func green_hoplite_move():
	hoplites_moving = true
	var type = "green_hoplite"
	for hoplite in get_tree().get_nodes_in_group(type):
		var current_tile = Map.local_to_map(hoplite.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		if hoplite.check_player() != Vector2i(-1, -1):
			hoplite.add_to_group("fighting")
			target_tile = move_closer_to_player(current_tile, type)
		else:
			target_tile = get_random_tile(current_tile, type)
		var direction = target_tile.x - current_tile.x
		if direction < 0:
			hoplite.Anim.flip_h = true
		elif direction > 0:
			hoplite.Anim.flip_h = false
		await enemy_moving(hoplite, target_tile)
	hoplites_moving = false
# -------------------------
# MAGMA GOLEM
# -------------------------
func get_random_magma_golem_tile() -> Vector2i:
	var attempts = 0

	while attempts < 1000:
		attempts += 1

		var x = randi() % map_size.x
		var y = randi() % map_size.y
		var tile = Vector2i(x, y)

		var data = map_data[x][y]

		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if ground_type != "grass":
			continue
		if is_river and not is_road:
			continue
		if not is_road:
			continue
		if is_tile_occupied(tile, "character"):
			continue

		return tile

	return Vector2i(-1, -1)

func spawn_magma_golems(count: int):
	for i in range(count):
		var golem = MagmaGolemScene.instantiate()

		var tile = get_random_magma_golem_tile()
		if tile != Vector2i(-1, -1):
			var pos = Map.map_to_local(tile)

			golem.global_position = pos
			add_child(golem)
			golem.set_mode("map")

func magma_golem_move():
	golems_moving = true
	var type = "magma_golem"
	for golem  in get_tree().get_nodes_in_group(type):
		var current_tile = Map.local_to_map(golem.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		if golem.check_player() != Vector2i(-1, -1):
			golem.add_to_group("fighting")
			target_tile = move_closer_to_player(current_tile, type)
		else:
			target_tile = get_random_tile(current_tile, type)
		var direction = target_tile.x - current_tile.x
		if direction < 0:
			golem.Anim.flip_h = true
		elif direction > 0:
			golem.Anim.flip_h = false
		await enemy_moving(golem, target_tile)
	golems_moving = false
# -------------------------
# PINKY
# -------------------------
func get_random_pinky_tile() -> Vector2i:
	var attempts = 0

	while attempts < 1000:
		attempts += 1

		var x = randi() % map_size.x
		var y = randi() % map_size.y
		var tile = Vector2i(x, y)

		var data = map_data[x][y]

		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if ground_type != "grass":
			continue
		if is_river and not is_road:
			continue
		if is_tile_occupied(tile, "character"):
			continue

		return tile
	return Vector2i(-1, -1)

func spawn_pinkies(count: int):
	for i in range(count):
		var pinky = PinkyScene.instantiate()

		var tile = get_random_pinky_tile()
		if tile != Vector2i(-1, -1):
			var pos = Map.map_to_local(tile)

			pinky.global_position = pos
			add_child(pinky)
			pinky.set_mode("map")

func pinky_move():
	pinkies_moving = true
	var type = "pinky"
	for pinky in get_tree().get_nodes_in_group(type):
		var current_tile = Map.local_to_map(pinky.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		if pinky.check_player() != Vector2i(-1, -1):
			pinky.add_to_group("fighting")
			target_tile = move_closer_to_player(current_tile, type)
		else:
			target_tile = get_random_tile(current_tile, type)
		var direction = target_tile.x - current_tile.x
		if direction < 0:
			pinky.Anim.flip_h = true
		elif direction > 0:
			pinky.Anim.flip_h = false
		await enemy_moving(pinky, target_tile)
	pinkies_moving = false

# -------------------------
# UI
# -------------------------
func _on_axe_changed(pressed: bool):
	if pressed:
		axe_pressed = true
		pickaxe_pressed = false
		pumpjack_pressed = false
		rocket_pressed = false
		Player.player_clicked = false
	else: axe_pressed = false
	clear_preview()
	Map.set_cell(1, player_tile, 1, Vector2i(-1, -1))
	
func _on_pickaxe_changed(pressed: bool):
	if pressed:
		axe_pressed = false
		pickaxe_pressed = true
		pumpjack_pressed = false
		rocket_pressed = false

		Player.player_clicked = false
	else: pickaxe_pressed = false
	clear_preview()
	Map.set_cell(1, player_tile, 1, Vector2i(-1, -1))
	
func _on_pumpjack_changed(pressed: bool):
	if pressed:
		axe_pressed = false
		pickaxe_pressed = false
		pumpjack_pressed = true
		rocket_pressed = false
		Player.player_clicked = false
	else: pumpjack_pressed = false
	clear_preview()
	Map.set_cell(1, player_tile, 1, Vector2i(-1, -1))
	
func _on_rocket_changed(pressed: bool):
	if pressed:
		axe_pressed = false
		pickaxe_pressed = false
		pumpjack_pressed = false
		rocket_pressed = true
		Player.player_clicked = false
	else: rocket_pressed = false
	clear_preview()
	Map.set_cell(1, player_tile, 1, Vector2i(-1, -1))
	
func move_compass():
	if rocket_tile != Vector2i(-1, -1):
		var rocket_pos = Map.map_to_local(rocket_tile)
		var player_pos = Player.global_position
		
		var direction = (rocket_pos - player_pos).normalized()
		
		var angle = direction.angle()
		UI.Shadow.rotation_degrees = rad_to_deg(angle) + 90
		
# -------------------------
# ROCKET
# -------------------------
func launch_rocket():
	UI.get_node("MapLayer").visible = false
	
	prev_player_tile = player_tile
	await move_there(player_tile, rocket_tile)
	player_tile = rocket_tile
	Player.visible = false
	move_there(player_tile, Vector2i(player_tile.x, player_tile.y-1))
	
	Map.set_cell(2, rocket_tile, 3, Vector2i(14, 0))
	await get_tree().create_timer(1).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(15, 0))
	await get_tree().create_timer(0.2).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(16, 0))
	await get_tree().create_timer(0.05).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(17, 0))
	await get_tree().create_timer(0.2).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(18, 0))
	await get_tree().create_timer(0.2).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(19, 0))
	await get_tree().create_timer(0.2).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(20, 0))
	await get_tree().create_timer(0.2).timeout
	Map.set_cell(2, rocket_tile, 3, Vector2i(21, 0))
	Player.z_index = 10
	Player.visible = true
	Player.Anim.play("Rocket")
	flying = true
	
	await get_tree().create_timer(5).timeout
	
	EndCredit.get_node("CanvasLayer").visible = true


