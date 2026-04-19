extends Node2D
#132x88 test map
@onready var Map = $TileMap
var PauseMenuScene = preload("res://Scenes/PauseMenu.tscn")
var PauseMenu

var BugEaterScene = preload("res://Scenes/BugEater.tscn")
var GreenHopliteScene = preload("res://Scenes/GreenHoplite.tscn")
var MagmaGolemScene = preload("res://Scenes/MagmaGolem.tscn")
var PinkyScene = preload("res://Scenes/Pinky.tscn")
#ground expandable x way for bioms
#resources expandable y way for different resources
@onready var map_size = Map.get_used_rect().size
@onready var Player = $Player
var map_data = []

var preview_route: Array = []
var max_preview_distance: Vector2i = Vector2i(-1, -1)

var prev_map_tile: Vector2i
var prev_player_tile: Vector2i
var player_tile: Vector2i

func _ready():
	generate_map()
	save_map_to_txt()
	PauseMenu = PauseMenuScene.instantiate()
	add_child(PauseMenu)
	PauseMenu.visible = false
	
	spawn_bug_eaters(100)
	spawn_green_hoplites(30)
	spawn_magma_golems(10)
	spawn_pinkies(20)
	player_tile = Map.local_to_map(Player.global_position)
	



func _input(event):
	if event is InputEventMouseMotion: #and player_clicked:
		var current_map_tile: Vector2i = Map.local_to_map(get_global_mouse_position())
		if Map.local_to_map(get_global_mouse_position()) != Map.local_to_map(Player.global_position):
			Map.set_cell(1, current_map_tile, 1, Vector2i(6, 6))
		if prev_map_tile != null and prev_map_tile != current_map_tile and prev_map_tile != Map.local_to_map(Player.global_position):
			Map.set_cell(1, prev_map_tile, 1, Vector2i(-1, -1))
		prev_map_tile = current_map_tile
	
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
			Map.set_cell(1, #Find or create a func to get_layer_id() reverse of get_layer_name()
				map_tile_clicked, 1, Vector2i(5, 6))
			Map.set_cell(1,Map.local_to_map(Player.global_position),1,Vector2i(-1,-1))

			await get_tree().create_timer(0.5).timeout
			Map.set_cell(1, map_tile_clicked, 1, Vector2i(-1, -1))
			Player.player_clicked = false
			await move_there(Map.local_to_map(Player.global_position), map_tile_clicked)
			player_tile = Map.local_to_map(Player.global_position)
			clear_route()
			bug_eater_move()
			green_hoplite_move()
			magma_golem_move()
			pinky_move()



	if event.is_action_pressed("ui_cancel"):
		PauseMenu.visible = true
		get_tree().paused = true

# -------------------------
# MAP GENERATION
# -------------------------

func generate_map():
	map_data.clear()
	for x in map_size.x:
		map_data.append([])
		for y in map_size.y:
			map_data[x].append([])
			var ground = Map.get_cell_atlas_coords(0, Vector2i(x,y), false)
			var resources = Map.get_cell_atlas_coords(2, Vector2i(x,y), false)
			var ground_type: String
			var river: bool
			var road: bool
			var resource_type: String = ""
			var resource_depleted: bool
			var cost: int = 1
			
			if ground == Vector2i(6,17): 
				ground_type = "deep_ocean"
			elif ground == Vector2i(7,17):
				ground_type = "ocean"
			else:
				if ground.x >= 0 and ground.x <= 7:
					ground_type = "grass"
				else: pass
				if ground.y >= 3 and ground.y <= 12:
					river = true
				else: river = false
				if ground.y >= 12 and ground.y <= 17:
					road = true
				else: road = false
				resource_depleted = false
				if resources.y >= 0 and resources.y <= 6:
					resource_type = "tree"
					if resources.y == 6: resource_depleted = true
				if resources.x >= 0 and resources.x <= 4:
					if resources.y == 7:
						resource_type = "stone"
					elif resources.y == 8:
						resource_type = "stone"
						resource_depleted = true
					elif resources.y == 9:
						resource_type = "iron_ore"
					elif resources.y == 10:
						resource_type = "iron_ore"
						resource_depleted = true
				elif resources.x >= 7 and resources.x <= 11:
					if resources.y == 7:
						resource_type = "minerals"
					elif resources.y == 8:
						resource_type = "minerals"
						resource_depleted = true
					elif resources.y == 9:
						resource_type = "crude_oil"
					elif resources.y == 10:
						resource_type = "crude_oil"
						resource_depleted = true
				

			if ground_type.contains("ocean") or (river == true and road == false): 
				cost += 99
			elif road == false and resource_type != "":
				cost += 2
			elif road == false and resource_type == "":
				cost += 1 
					

			map_data[x][y] = [ground_type, river, road, resource_type, resource_depleted, cost]
	save_map_temp()

# -------------------------
# FILE SAVE --> looks ok, the rows and columns might be switched up?
# -------------------------

func save_map_temp(): 
	var path = "C:/Users/tibi2/OneDrive/Documents/godot/Szakdoga/PreMadeMap/SaveFiles/map.json"
	var json_string = JSON.stringify(map_data)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		#print("Map saved to: ", path)
	else:
		pass
		#print("Failed to save file.")

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

func move_there(start_tile: Vector2i, destination: Vector2i):
	var is_water = map_data[destination.x][destination.y][5] == 100

	if is_water:
		#print("Invalid destination")
		return
		
	var open_set = [start_tile]
	var came_from = {}

	var g_score = {}
	var f_score = {}

	g_score[start_tile] = 0
	f_score[start_tile] = heuristic(start_tile, destination)

	while open_set.size() > 0:
		var current = open_set[0]
		for tile in open_set:
			if f_score.get(tile, INF) < f_score.get(current, INF):
				current = tile

		if current == destination:
			var route = reconstruct_path(came_from, current)

			var total_cost = 0

			#print("Route:", route)
			for i in range(1, route.size()):
				var tile = route[i]
				if Player.movement_points >= map_data[tile.x][tile.y][5]:
					await Player.tile_clicked(Map.map_to_local(tile))
					total_cost += map_data[tile.x][tile.y][5]
					#print("I moved there: ", tile, " the cost is: ", map_data[tile.x][tile.y][5], " becouse the feature is: ", map_data[tile.x][tile.y][3])
				else:
					#print("out of movement points, remaining movement points: ", Player.movement_points)
					#print("the movement cost would have been: ", map_data[tile.x][tile.y][5])
					#print("Total movement cost:", total_cost)
					Player.movement_points = Player.max_movement_points
					return
				Player.movement_points -= map_data[tile.x][tile.y][5]
				#print("remaining movement_points: ", Player.movement_points)
				
			#print("Total movement cost:", total_cost)
			Player.movement_points = Player.max_movement_points
			return

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue

			if map_data[neighbor.x][neighbor.y][5] == 100:
				continue

			var tentative_g = g_score.get(current, INF) + map_data[neighbor.x][neighbor.y][5]

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, destination)

				if neighbor not in open_set:
					open_set.append(neighbor)

	#print("No path found")

func heuristic(a: Vector2i, b: Vector2i) -> int:
	# Manhattan distance
	return abs(a.x - b.x) + abs(a.y - b.y)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var total_path = [current]

	while current in came_from:
		current = came_from[current]
		total_path.insert(0, current)

	return total_path

func get_neighbors(tile: Vector2i):

	#n, e, s, w
	
	var neighbor_north = Vector2i(tile.x, tile.y - 1)
	var neighbor_east = Vector2i(tile.x + 1, tile.y)
	var neighbor_south = Vector2i(tile.x, tile.y + 1)
	var neighbor_west = Vector2i(tile.x - 1, tile.y)
	var neighbors = [neighbor_north,
					 neighbor_east,
					 neighbor_south,
					 neighbor_west]

	return neighbors

func get_preview_path(start_tile: Vector2i, destination: Vector2i) -> Array:
	var open_set = [start_tile]
	var came_from = {}

	var g_score = {}
	var f_score = {}

	g_score[start_tile] = 0
	f_score[start_tile] = heuristic(start_tile, destination)

	while open_set.size() > 0:
		var current = open_set[0]
		for tile in open_set:
			if f_score.get(tile, INF) < f_score.get(current, INF):
				current = tile

		if current == destination:
			return reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue

			if map_data[neighbor.x][neighbor.y][5] == 100:
				continue

			var tentative_g = g_score.get(current, INF) + map_data[neighbor.x][neighbor.y][5]

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, destination)

				if neighbor not in open_set:
					open_set.append(neighbor)

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
		#print("allowed route:", allowed_route)
		var prev = allowed_route[i - 1]
		var current = allowed_route[i]
		var next = allowed_route[i + 1]

		var atlas: Vector2i = get_direction_tile(prev, current, next)
		Map.set_cell(3, current, 2, atlas)
	
	max_preview_distance = allowed_route[allowed_route.size()-1]
	#print("max dISTANCE: ", max_preview_distance)
	Map.set_cell(1, max_preview_distance, 1, Vector2i(5, 6))
	
	for i in range(allowed_route.size(), route.size() - 1):
		var prev = route[i - 1]
		var current = route[i]
		var next = route[i + 1]

		var atlas: Vector2i = get_direction_tile(prev, current, next)
		atlas = Vector2i(atlas.x + 2, atlas.y)
		Map.set_cell(3, current, 2, atlas)

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
#func stopped_moving(_enemy):
	#enemies_finished_moving += 1
	#
#func enemies_moving():
	#enemies_finished_moving = 0
	#while current_enemies > enemies_finished_moving:
		#continue

func is_tile_occupied(tile: Vector2i) -> bool:
	for unit in get_tree().get_nodes_in_group("character"):
		var unit_tile = Map.local_to_map(unit.global_position)
		if unit_tile == tile:
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
			if is_tile_occupied(tile):
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
			if is_tile_occupied(tile):
				continue

			return tile

	if type == "magma_golem":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 5 - 4
			var offset_y = randi() % 5 - 4
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
			if is_tile_occupied(tile):
				continue

			return tile

	if type == "pinky":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 11 - 4
			var offset_y = randi() % 11 - 4
			var tile = center + Vector2i(offset_x, offset_y)

			var data = map_data[tile.x][tile.y]
			var ground_type = data[0]
			var is_river = data[1]
			var is_road = data[2]

			if ground_type != "grass":
				continue
			if is_river and not is_road:
				continue
			if is_tile_occupied(tile):
				continue

			return tile

	return Vector2i(-1, -1)
	
func check_roadblock(start_tile: Vector2i, end_tile: Vector2i, type: String) -> bool:
	var current = start_tile

	while current != end_tile:
		if current.x < end_tile.x:
			current.x += 1
		elif current.x > end_tile.x:
			current.x -= 1
		elif current.y < end_tile.y:
			current.y += 1
		elif current.y > end_tile.y:
			current.y -= 1

		var data = map_data[current.x][current.y]
		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if type == "bug_eater":
			if ground_type.contains("ocean"):
				return true
			if is_river:
				return true
			if is_road:
				return true

		if type == "green_hoplite" or type == "magma_golem":
			if ground_type.contains("ocean"):
				return true
			if is_river and not is_road:
				return true
			if not is_road:
				return true

		if type == "pinky":
			if ground_type.contains("ocean"):
				return true
			if is_river and not is_road:
				return true

	return false

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
				if is_tile_occupied(tile):
					continue

			if type == "green_hoplite" or type == "magma_golem":
				if ground_type != "grass":
					continue
				if is_river and not is_road:
					continue
				if not is_road:
					continue
				if is_tile_occupied(tile):
					continue
					
			if type == "pinky":
				if ground_type != "grass":
					continue
				if is_river and not is_road:
					continue
				if is_tile_occupied(tile):
					continue

			var value = heuristic(tile, player_tile)
			if value < best_value:
				print(best_value)
				closest_tile = tile
				best_value = value
	return closest_tile
	# if type is "bug_eater" chose a tile closest to the player that is not river
	
func enemy_movement():
	#this one moves one tile at a time
	pass

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
		if is_tile_occupied(tile):
			continue

		return tile
	return Vector2i(-1, -1)

func spawn_bug_eaters(count: int):
	print("bug eaters spawning")
	for i in range(count):
		var bug = BugEaterScene.instantiate()

		var tile = get_random_bug_eater_tile()
		if tile != Vector2i(-1, -1):
			var pos = Map.map_to_local(tile)

			bug.global_position = pos
			add_child(bug)
			bug.set_mode("map")

func bug_eater_move():
	for bug in get_tree().get_nodes_in_group("bug_eater"):
		var current_tile = Map.local_to_map(bug.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		if bug.check_player() != Vector2i(-1, -1):
			target_tile = move_closer_to_player(current_tile, "bug_eater")
			bug.global_position = Map.map_to_local(target_tile)

		else:
			target_tile = get_random_tile(current_tile, "bug_eater")
			bug.global_position = Map.map_to_local(target_tile)
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
		if is_tile_occupied(tile):
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
	for hoplite in get_tree().get_nodes_in_group("green_hoplite"):
		var current_tile = Map.local_to_map(hoplite.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		
		if hoplite.check_player() != Vector2i(-1, -1):
			target_tile = move_closer_to_player(current_tile, "green_hoplite")
			hoplite.global_position = Map.map_to_local(target_tile)

		else:
			target_tile = get_random_tile(current_tile, "green_hoplite")
			hoplite.global_position = Map.map_to_local(target_tile)

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
		if is_tile_occupied(tile):
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
	for golem in get_tree().get_nodes_in_group("magma_golem"):
		var current_tile = Map.local_to_map(golem.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		
		if golem.check_player() != Vector2i(-1, -1):
			target_tile = move_closer_to_player(current_tile, "magma_golem")
			golem.global_position = Map.map_to_local(target_tile)

		else:
			target_tile = get_random_tile(current_tile, "magma_golem")
			golem.global_position = Map.map_to_local(target_tile)

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
		if is_tile_occupied(tile):
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
	for pinky in get_tree().get_nodes_in_group("pinky"):
		var current_tile = Map.local_to_map(pinky.global_position)
		var target_tile: Vector2i = Vector2i(-1, -1)
		
		if pinky.check_player() != Vector2i(-1, -1):
			target_tile = move_closer_to_player(current_tile, "pinky")
			pinky.global_position = Map.map_to_local(target_tile)

		else:
			target_tile = get_random_tile(current_tile, "pinky")
			pinky.global_position = Map.map_to_local(target_tile)




