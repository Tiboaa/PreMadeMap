extends Node2D

@onready var Map = $TileMap

var map_size: Vector2i = Vector2i(141,141)
var map_center: int = 70
var map_data: Array

var LandNoise
var TreeNoise
var IronNoise
var MineralsNoise
var StoneNoise
var OilNoise


func _ready():
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



