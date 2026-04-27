extends Node2D

var CurrentMap

@onready var SimpleMap = $BattleMapSimple
@onready var RoadMap = $BattleMapRoad
@onready var CrossRoadsMap = $BattleMapCrossRoads
@onready var RiverCrossingMap = $BattleMapRiverCrossing
@onready var UI = get_parent().get_node("BasicUI")

var map_size
var map_size_for_spawning
var map_data = []


@onready var MainScene = get_tree().current_scene
@onready var Player = $Player
var prev_player_tile: Vector2i
var player_tile: Vector2i

var BugEaterScene = preload("res://Scenes/BugEater.tscn")
var GreenHopliteScene = preload("res://Scenes/GreenHoplite.tscn")
var MagmaGolemScene = preload("res://Scenes/MagmaGolem.tscn")
var PinkyScene = preload("res://Scenes/Pinky.tscn")

var bug_number: int = 0
var hoplite_number: int = 0
var golem_number: int = 0
var pinky_number: int = 0
var enemy_number: int = 0

var enemies_moving: bool = false
var player_moving: bool = false

var prev_map_tile: Vector2i

var basic_atk_selected: bool = false
var area_atk_selected: bool = false
var heavy_atk_selected: bool = false
var attacked_tile: Vector2i = Vector2i(-1, -1)

var preview_route: Array = []
var max_preview_distance: Vector2i = Vector2i(-1, -1)

var move_there_tile: Vector2i = Vector2i(-1, -1)

var player_attacking: bool = false

func _process(delta):
	if enemy_number <= 0:
		all_enemies_killed(false)

func _ready():
	CurrentMap = CrossRoadsMap
	CurrentMap.visible = true
	map_size = CurrentMap.get_used_rect().size
	map_size_for_spawning = Vector2i(map_size.x-3, map_size.y-3)
	map_gen()
	UI.basic_atk_changed.connect(_on_basic_changed)
	UI.area_atk_changed.connect(_on_area_changed)
	UI.heavy_atk_changed.connect(_on_heavy_changed)
	health_update()
	player_tile = Vector2i(4, 2)
	UI.Survived.visible = false
	UI.Death.visible = false

	
func _input(event):
	if event.is_action_pressed("end_turn"):
		enemies_moving = false
		player_attacking = false
		player_moving = false
		basic_atk_selected = false
		area_atk_selected = false
		heavy_atk_selected = false
	if event.is_action_pressed("ui_cancel"):
		MainScene.PauseMenu.visible = true
		get_tree().paused = true
	var mouse_pos = CurrentMap.to_local(get_global_mouse_position())
	var current_map_tile: Vector2i = CurrentMap.local_to_map(mouse_pos)
	
	if  not enemies_moving and not player_attacking and not is_tile_off_map(current_map_tile):
		if event is InputEventMouseMotion and not player_moving:
			if Player.player_clicked:
				var route = get_preview_path(CurrentMap.local_to_map(CurrentMap.to_local(Player.global_position)), current_map_tile)
				if route.size() > 0:
					draw_preview(route)
				if prev_map_tile != current_map_tile and prev_map_tile != CurrentMap.local_to_map(Player.position):
					CurrentMap.set_cell(1, prev_map_tile, -1)
					
			elif basic_atk_selected:
				if not Player.player_clicked:
					CurrentMap.set_cell(1, prev_map_tile, -1)
					CurrentMap.set_cell(1, current_map_tile, 2, Vector2i(6, 6))
				
			elif area_atk_selected:
				if not Player.player_clicked:
					var area = get_neighbors(current_map_tile)
					var prev_area = get_neighbors(prev_map_tile)
					area.append(current_map_tile)
					prev_area.append(prev_map_tile)
					for i in prev_area:
						CurrentMap.set_cell(1, i, -1)
					for i in area:
						CurrentMap.set_cell(1, i, 2, Vector2i(6, 6))
						
			elif heavy_atk_selected:
				if not Player.player_clicked:
					CurrentMap.set_cell(1, prev_map_tile, -1)
					CurrentMap.set_cell(1, Vector2i(prev_map_tile.x, player_tile.y), -1)
					CurrentMap.set_cell(1, Vector2i(current_map_tile.x, player_tile.y), 2, Vector2i(6, 6))
			else:
				CurrentMap.set_cell(1, prev_map_tile, -1)
				CurrentMap.set_cell(1, current_map_tile, 2, Vector2i(6, 6))

			prev_map_tile = current_map_tile
		if (area_atk_selected or basic_atk_selected or heavy_atk_selected) and not player_moving:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var click_pos: Vector2 = CurrentMap.to_local(get_global_mouse_position())
				var map_tile_clicked: Vector2i = CurrentMap.local_to_map(click_pos)
				if basic_atk_selected:
					player_attacking = true
					
					if CurrentMap.local_to_map(Player.position) == map_tile_clicked:
						Player.player_clicked = true
						CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
					else:
						CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
						await get_tree().create_timer(0.5).timeout
						CurrentMap.set_cell(1, map_tile_clicked, -1)
						
						if map_tile_clicked.x > player_tile.x:
							Player.Anim.flip_h = false
						else: Player.Anim.flip_h = true
							
						var clicked_enemy = get_enemy_on_tile(map_tile_clicked)
						if clicked_enemy != null:
							Player.Anim.play("Attack")
							await Player.Anim.animation_finished
							clicked_enemy.Anim.play("Hurt")
							await clicked_enemy.Anim.animation_finished
							await hurt_the_enemy(clicked_enemy, 2)
						else:
							player_attacking = false
							return
						
						enemies_moving = true
						await move_the_enemies()
						enemies_moving = false
						basic_atk_selected = false
						area_atk_selected = false
						heavy_atk_selected = false

						UI.get_node("BattleLayer/BattleToolbelt/BasicAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/AreaAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/HeavyAtk/Button").button_pressed = false

					player_attacking = false
				if area_atk_selected:
					player_attacking = true
					if CurrentMap.local_to_map(Player.position) == map_tile_clicked:
						Player.player_clicked = true
						CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
					else:
						var area = get_neighbors(map_tile_clicked)
						area.append(map_tile_clicked)
						for i in area:
							CurrentMap.set_cell(1, i, 2, Vector2i(5, 6))
						await get_tree().create_timer(0.2).timeout
						for i in area:
							CurrentMap.set_cell(1, i, -1)
							
						if map_tile_clicked.x > player_tile.x:
							Player.Anim.flip_h = false
						else: Player.Anim.flip_h = true
							
						var enemies_hurt: int = 0
						for i in area:
							var clicked_enemy = get_enemy_on_tile(i)
							if clicked_enemy != null:
								clicked_enemy.Anim.play("Hurt")
								await hurt_the_enemy(clicked_enemy, 1)
								enemies_hurt += 1
						if enemies_hurt > 0:
							Player.Anim.play("Attack")
							await Player.Anim.animation_finished
						if enemies_hurt == 0:
							player_attacking = false
							return
						
						enemies_moving = true
						await move_the_enemies()
						enemies_moving = false
						basic_atk_selected = false
						area_atk_selected = false
						heavy_atk_selected = false 

						UI.get_node("BattleLayer/BattleToolbelt/BasicAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/AreaAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/HeavyAtk/Button").button_pressed = false

					player_attacking = false
				if heavy_atk_selected:
					player_attacking = true
					if CurrentMap.local_to_map(Player.position) == map_tile_clicked:
						Player.player_clicked = true
						CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
					else :
						attacked_tile = Vector2i(map_tile_clicked.x, player_tile.y)
						CurrentMap.set_cell(1, attacked_tile, 2, Vector2i(5, 6))
						await get_tree().create_timer(0.5).timeout
						CurrentMap.set_cell(1, attacked_tile, -1)
						
						if attacked_tile.x > player_tile.x:
							Player.Anim.flip_h = false
						else: Player.Anim.flip_h = true
						
						var clicked_enemy = get_enemy_on_tile(attacked_tile)
						if clicked_enemy != null:
							Player.Anim.play("Attack")
							await Player.Anim.animation_finished
							clicked_enemy.Anim.play("Hurt")
							await clicked_enemy.Anim.animation_finished
							await hurt_the_enemy(clicked_enemy, 4)
						else: 
							player_attacking = false
							return
						
						enemies_moving = true
						await move_the_enemies()
						enemies_moving = false
						basic_atk_selected = false
						area_atk_selected = false
						heavy_atk_selected = false

						UI.get_node("BattleLayer/BattleToolbelt/BasicAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/AreaAtk/Button").button_pressed = false
						UI.get_node("BattleLayer/BattleToolbelt/HeavyAtk/Button").button_pressed = false

					player_attacking = false
				return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not player_moving:

			var click_pos: Vector2 = CurrentMap.to_local(get_global_mouse_position())
			var map_tile_clicked: Vector2i = CurrentMap.local_to_map(click_pos)
			if is_tile_off_map(map_tile_clicked) and Player.player_clicked:
			
				CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
				await get_tree().create_timer(0.5).timeout
				CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(-1, -1))
				return
				
			if CurrentMap.local_to_map(Player.position) == map_tile_clicked:
				if not Player.player_clicked:
					Player.player_clicked = true
					CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(5, 6))
				else:
					Player.player_clicked = false
					CurrentMap.set_cell(1, map_tile_clicked, 2, Vector2i(-1, -1))

			elif Player.player_clicked:
				player_moving = true
				Player.player_clicked = false
				
				await move_there(CurrentMap.local_to_map(Player.position), move_there_tile)
				player_tile = CurrentMap.local_to_map(Player.position)
				clear_preview()

				
				if prev_player_tile != player_tile:
					enemies_moving = true
					await move_the_enemies()
					enemies_moving = false
					basic_atk_selected = false
					area_atk_selected = false
					heavy_atk_selected = false

					UI.get_node("BattleLayer/BattleToolbelt/BasicAtk/Button").button_pressed = false
					UI.get_node("BattleLayer/BattleToolbelt/AreaAtk/Button").button_pressed = false
					UI.get_node("BattleLayer/BattleToolbelt/HeavyAtk/Button").button_pressed = false

				player_moving = false
				prev_player_tile = player_tile


func get_preview_path(start_tile: Vector2i, destination: Vector2i) -> Array:
	var open_set = [start_tile]
	var came_from = {}

	var g_distance = {}
	var f_distance = {}

	g_distance[start_tile] = 0
	f_distance[start_tile] = heuristic(start_tile, destination)

	while open_set.size() > 0:
		var current = open_set[0]
		for tile in open_set:
			if f_distance.get(tile, INF) < f_distance.get(current, INF):
				current = tile

		if current == destination:
			return reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue

			if map_data[neighbor.x][neighbor.y][5] == 1000:
				continue

			var g_cost = g_distance.get(current, INF) + map_data[neighbor.x][neighbor.y][5]

			if g_cost < g_distance.get(neighbor, INF):
				came_from[neighbor] = current
				g_distance[neighbor] = g_cost
				f_distance[neighbor] = g_cost + heuristic(neighbor, destination)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []

# -------------------------
# MAP
# -------------------------
func map_gen():
	for x in map_size.x:
		map_data.append([])
		for y in map_size.y:
			map_data[x].append([])
			var ground = CurrentMap.get_cell_atlas_coords(0, Vector2i(x,y), false)
			var border = CurrentMap.get_cell_source_id(0, Vector2i(x,y), false)
			var ground_type: String
			var river: bool
			var road: bool
			var resource_type: String = ""
			var resource_depleted: bool
			var cost: int = 1
			
			if border == 1:
				ground_type = "border"
			elif ground == Vector2i(6,17): 
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


			if ground_type == "border":
				cost += 999
			elif ground_type.contains("ocean") or (river == true and road == false): 
				cost += 99
			elif road == false and resource_type != "":
				cost += 2
			elif road == false and resource_type == "":
				cost += 1 
					
			map_data[x][y] = [ground_type, river, road, resource_type, resource_depleted, cost]

func is_tile_off_map(tile: Vector2i) -> bool:
	if tile.x <= -1 or tile.y <= -1 or tile.x >= map_size.x-1 or tile.y >= map_size.y-1:
		return true

	if map_data[tile.x][tile.y][0] == "border":
		return true
	
	return false

# -------------------------
# PLAYER MOVEMENT
# -------------------------
func move_there(start_tile: Vector2i, destination: Vector2i):
	if is_tile_occupied(destination, "enemy"):
		return
		
	var is_water = map_data[destination.x][destination.y][5] == 100
	if is_water:
		return
		
	var open_set = [start_tile]
	var came_from = {}
	var g_distance = {}
	var f_distance = {}
	g_distance[start_tile] = 0
	f_distance[start_tile] = heuristic(start_tile, destination)
	
	while open_set.size() > 0:
		var current = open_set[0]
		for tile in open_set:
			if f_distance.get(tile, INF) < f_distance.get(current, INF):
				current = tile

		if current == destination:
			var route = reconstruct_path(came_from, current)
			for i in range(1, route.size()):
				var tile = route[i]
				if true:
					await Player.tile_clicked(CurrentMap.to_global(CurrentMap.map_to_local(tile)))
				else:
					Player.battle_movement_points = Player.max_battle_movement_points
					return
				Player.battle_movement_points -= map_data[tile.x][tile.y][5]
			Player.battle_movement_points = Player.max_battle_movement_points
			return

		open_set.erase(current)
		for neighbor in get_neighbors(current):
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_size.x or neighbor.y >= map_size.y:
				continue
			
			if map_data[neighbor.x][neighbor.y][5] == 1000 :
				continue
			
			var g_cost = g_distance.get(current, INF) + map_data[neighbor.x][neighbor.y][5]
			if g_cost < g_distance.get(neighbor, INF):
				came_from[neighbor] = current
				g_distance[neighbor] = g_cost
				f_distance[neighbor] = g_cost + heuristic(neighbor, destination)

				if neighbor not in open_set:
					open_set.append(neighbor)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var chosen_path = [current]
	
	while current in came_from:
		current = came_from[current]
		chosen_path.insert(0, current)
	
	return chosen_path
	
	

func heuristic(start_tile: Vector2i, destination: Vector2i) -> int:
	return abs(start_tile.x - destination.x) + abs(start_tile.y - destination.y)

func get_neighbors(tile: Vector2i):
	var neighbor_north = Vector2i(tile.x, tile.y - 1)
	var neighbor_east = Vector2i(tile.x + 1, tile.y)
	var neighbor_south = Vector2i(tile.x, tile.y + 1)
	var neighbor_west = Vector2i(tile.x - 1, tile.y)
	var neighbors = [neighbor_north, neighbor_east, neighbor_south, neighbor_west]

	return neighbors

func draw_preview(route: Array):
	clear_preview()
	CurrentMap.set_cell(1, player_tile, 2, Vector2i(5, 6))
	if route.size() < 2:
		return

	var allowed_route: Array = []
	var remaining = Player.battle_movement_points

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
		CurrentMap.set_cell(1, current, 3, coord)
	
	max_preview_distance = allowed_route[allowed_route.size()-1]
	move_there_tile = max_preview_distance
	CurrentMap.set_cell(1, max_preview_distance, 2, Vector2i(5, 6))

	preview_route = route

func clear_preview():
	CurrentMap.set_cell(1, max_preview_distance, -1)
	for tile in preview_route:
		CurrentMap.set_cell(1, tile, -1)

	preview_route.clear()

func get_direction_tile(prev: Vector2i, current: Vector2i, next: Vector2i) -> Vector2i:
	var from_dir_x = current.x - prev.x
	var from_dir_y = current.y - prev.y

	var to_dir_x = next.x - current.x
	var to_dir_y = next.y - current.y
	
	if from_dir_x == 0 and to_dir_x == 0:
		return Vector2i(1, 2)
	if from_dir_y == 0 and to_dir_y == 0:
		return Vector2i(0, 2)

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
func collect_fighters(bug_num: int, hopltite_num: int, golem_num: int, pinky_num: int):
	bug_number = bug_num
	hoplite_number = hopltite_num
	golem_number = golem_num
	pinky_number = pinky_num

func get_random_enemy_tile() -> Vector2i:
	var attempts = 0

	while attempts < 1000:
		attempts += 1

		var x = randi() % map_size_for_spawning.x
		var y = randi() % map_size_for_spawning.y
		var tile = Vector2i(x, y)

		var data = map_data[x][y]

		var ground_type = data[0]
		var is_river = data[1]
		var is_road = data[2]

		if ground_type != "grass":
			continue
		if is_river:
			continue
		if is_tile_occupied(tile, "character"):
			continue

		return tile
	return Vector2i(-1, -1)

func is_tile_occupied(tile: Vector2i, by_who: String) -> bool:
	for unit in get_tree().get_nodes_in_group(by_who):
		var unit_tile = CurrentMap.local_to_map(CurrentMap.to_local(unit.global_position))
		if unit_tile == tile and not is_tile_off_map(tile):
			return true
	return false

func get_random_tile(center: Vector2i, type: String) -> Vector2i:
	var attempts = 0
	if type == "bug_eater":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 7 - 3
			var offset_y = randi() % 7 - 3
			var tile = center + Vector2i(offset_x, offset_y)

			if tile.x < 0 or tile.y < 0 or tile.x >= 12 or tile.y >= 6:
				continue
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
			if is_tile_off_map(tile):
				continue

			return tile

	if type == "green_hoplite":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 5 - 2
			var offset_y = randi() % 5 - 2
			var tile = center + Vector2i(offset_x, offset_y)

			if tile.x < 0 or tile.y < 0 or tile.x >= 12 or tile.y >= 6:
				continue
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
			if is_tile_off_map(tile):
				continue

			return tile

	if type == "magma_golem":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 5 - 2
			var offset_y = randi() % 5 - 2
			var tile = center + Vector2i(offset_x, offset_y)


			if tile.x < 0 or tile.y < 0 or tile.x >= 12 or tile.y >= 6:
				continue
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
			if is_tile_off_map(tile):
				continue
				
			return tile

	if type == "pinky":
		while attempts < 100:
			attempts += 1
			var offset_x = randi() % 9 - 4
			var offset_y = randi() % 9 - 4
			var tile = center + Vector2i(offset_x, offset_y)

			if tile.x < 0 or tile.y < 0 or tile.x >= 12 or tile.y >= 6:
				continue
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
			if is_tile_off_map(tile):
				continue
				
			return tile

	return Vector2i(-1, -1)

func spawn_fighters():
	for b in bug_number:
		enemy_number += 1
		var bug = BugEaterScene.instantiate()
		var tile = get_random_enemy_tile()
		if tile != Vector2i(-1, -1):
			var pos = CurrentMap.map_to_local(tile)

			bug.global_position = pos
			add_child(bug)
			bug.set_mode("battle")
			bug.add_to_group("fighting")
	for h in hoplite_number:
		enemy_number += 1
		var hoplite = GreenHopliteScene.instantiate()
		var tile = get_random_enemy_tile()
		if tile != Vector2i(-1, -1):
			var pos = CurrentMap.map_to_local(tile)

			hoplite.global_position = pos
			add_child(hoplite)
			hoplite.set_mode("battle")
			hoplite.add_to_group("fighting")
			hoplite.add_to_group("green_hoplite")
	for g in golem_number:
		enemy_number += 1
		var golem = MagmaGolemScene.instantiate()
		var tile = get_random_enemy_tile()
		if tile != Vector2i(-1, -1):
			var pos = CurrentMap.map_to_local(tile)

			golem.global_position = pos
			add_child(golem)
			golem.set_mode("battle")
			golem.add_to_group("fighting")
	for p in pinky_number:
		enemy_number += 1
		var pinky = PinkyScene.instantiate()
		var tile = get_random_enemy_tile()
		if tile != Vector2i(-1, -1):
			var pos = CurrentMap.map_to_local(tile)

			pinky.global_position = pos
			add_child(pinky)
			pinky.set_mode("battle")
			pinky.add_to_group("fighting")

func move_the_enemies():
	for enemy in get_tree().get_nodes_in_group("fighting"):
		if not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("bug_eater"):
			var where_is_player = enemy.check_player()
			var enemy_tile = CurrentMap.local_to_map(CurrentMap.to_local(enemy.global_position))
			if where_is_player == Vector2i(-1, -1):
				var target_tile = get_random_tile(enemy_tile, "bug_eater")
				await enemy.move_to_tile((target_tile), CurrentMap)
			else:
				var next_to_player = get_neighbors(player_tile)
				if enemy_tile in next_to_player:
					if enemy_tile.x > where_is_player.x:
						enemy.Anim.flip_h = true
					else: enemy.Anim.flip_h = false
					var option = randi() % 2
					if option == 0:
						enemy.Anim.play("Bite")
						Player.Anim.play("Hurt")
						Player.health -= enemy.hurt_points + (randi() % 2 - 1)
						await enemy.Anim.animation_finished
					if option == 1:
						enemy.Anim.play("Slam")
						Player.Anim.play("Hurt")
						Player.health -= enemy.hurt_points * 2 + (randi() % 2 - 1)
						await enemy.Anim.animation_finished

				else:
					for i in next_to_player:
						if not is_tile_occupied(i, "character") and not is_tile_off_map(i):
							var target_tile = i
							await enemy.move_to_tile((target_tile), CurrentMap)
							break
		
		if enemy.is_in_group("green_hoplite"):
			var enemy_tile = CurrentMap.local_to_map(CurrentMap.to_local(enemy.global_position))
			if player_tile.y != enemy_tile.y:
				var tile_option: Vector2i
				var found_the_tile: bool = false
				for i in range(enemy_tile.x):
					tile_option = Vector2i(enemy_tile.x, player_tile.y + i)
					if not is_tile_occupied(tile_option, "character") and not is_tile_off_map(tile_option):
						var target_tile = tile_option
						await enemy.move_to_tile((target_tile), CurrentMap)
						found_the_tile = true
						break
					tile_option = Vector2i(enemy_tile.x, player_tile.y - i)
					if not is_tile_occupied(tile_option, "character") and not is_tile_off_map(tile_option):
						var target_tile = tile_option
						if enemy_tile.x > target_tile.x:
							enemy.Anim.flip_h = true
						else: enemy.Anim.flip_h = false
						await enemy.move_to_tile((target_tile), CurrentMap)
						found_the_tile = true
						break
				if not found_the_tile:
					var target_tile = get_random_tile(enemy_tile, "green_hoplite")
					await enemy.move_to_tile((target_tile), CurrentMap)
			else:
				if enemy_tile.x > player_tile.x:
					enemy.Anim.flip_h = true
				else: enemy.Anim.flip_h = false
				var option = randi() % 3
				if option == 0:
					enemy.Anim.play("Attack")
					Player.Anim.play("Hurt")
					Player.health -= enemy.hurt_points + (randi() % 2 - 1)
					await enemy.Anim.animation_finished
				else:
					enemy.Anim.play("ApAttack")
					Player.Anim.play("Hurt")
					Player.health -= enemy.hurt_points * 3 + (randi() % 21 - 10)
					await enemy.Anim.animation_finished
		
		if enemy.is_in_group("magma_golem"):
			var where_is_player = enemy.check_player()
			var enemy_tile = CurrentMap.local_to_map(CurrentMap.to_local(enemy.global_position))
			if where_is_player == Vector2i(-1, -1):
				var target_tile = get_random_tile(enemy_tile, "magma_golem")
				await enemy.move_to_tile((target_tile), CurrentMap)
			else:
				var option = randi() % 2
				if option == 0:
					if enemy_tile.x > player_tile.x:
							enemy.Anim.flip_h = true
					else: enemy.Anim.flip_h = false
					if player_tile.y != enemy_tile.y:
						var tile_option: Vector2i
						var found_the_tile: bool = false
						for i in range(enemy_tile.x):
							tile_option = Vector2i(enemy_tile.x, player_tile.y + i)
							if not is_tile_occupied(tile_option, "character") and not is_tile_off_map(tile_option):
								var target_tile = tile_option
								await enemy.move_to_tile((target_tile), CurrentMap)
								found_the_tile = true
								break
							tile_option = Vector2i(enemy_tile.x, player_tile.y - i)
							if not is_tile_occupied(tile_option, "character") and not is_tile_off_map(tile_option):
								var target_tile = tile_option
								await enemy.move_to_tile((target_tile), CurrentMap)
								found_the_tile = true
								break
						if not found_the_tile:
							var target_tile = get_random_tile(enemy_tile, "magma_golem")
							await enemy.move_to_tile((target_tile), CurrentMap)
					else:
						enemy.Anim.play("Attack")
						Player.Anim.play("Hurt")
						Player.health -= enemy.hurt_points + (randi() % 2 - 1)
						await enemy.Anim.animation_finished
				if option == 1:
					if enemy_tile.x > player_tile.x:
						enemy.Anim.flip_h = true
					else: enemy.Anim.flip_h = false
					enemy.Anim.play("HeavyAttack")
					Player.Anim.play("Hurt")
					Player.health -= enemy.hurt_points * 2 + (randi() % 5 - 2)
					await enemy.Anim.animation_finished
			
		if enemy.is_in_group("pinky"):
			var where_is_player = enemy.check_player()
			var enemy_tile = CurrentMap.local_to_map(CurrentMap.to_local(enemy.global_position))
			if where_is_player == Vector2i(-1, -1):
				var target_tile = get_random_tile(enemy_tile, "pinky")
				await enemy.move_to_tile((target_tile), CurrentMap)
				
			else:
				var next_to_player = get_neighbors(player_tile)
				
				if enemy_tile in next_to_player:
					if enemy_tile.x > player_tile.x:
						enemy.Anim.flip_h = true
					else: enemy.Anim.flip_h = false
					var option = randi() % 4
					if option == 0:
						enemy.Anim.play("Bite")
						Player.Anim.play("Hurt")
						Player.health -= enemy.hurt_points * 5 + (randi() % 11 - 5)
						await enemy.Anim.animation_finished
					if option > 0:
						enemy.Anim.play("Slap")
						Player.Anim.play("Hurt")
						Player.health -= enemy.hurt_points + (randi() % 2 - 1)
						await enemy.Anim.animation_finished

				else:
					for i in next_to_player:
						if not is_tile_occupied(i, "character") and not is_tile_off_map(i):
							var target_tile = i
							await enemy.move_to_tile((target_tile), CurrentMap)
							break
		
		health_update()

func get_enemy_on_tile(tile: Vector2i):
	for enemy in get_tree().get_nodes_in_group("fighting"):
		if not is_instance_valid(enemy):
			return null
		if enemy.is_in_group("enemy"):
			var enemy_tile = CurrentMap.local_to_map(CurrentMap.to_local(enemy.global_position))
			if enemy_tile == tile and not is_tile_off_map(tile):
				return enemy
	return null

func hurt_the_enemy(enemy, damage):
	enemy.hit_points -= damage
	var is_dead: bool = enemy.battle_update()
	if is_dead:
		enemy_number -= 1
		player_moving = false
		player_attacking = false
		enemy.remove_from_group("fighting")
		enemy.queue_free()
		
func all_enemies_killed(dead):
	basic_atk_selected = false
	area_atk_selected = false
	heavy_atk_selected = false

	UI.get_node("BattleLayer/BattleToolbelt/BasicAtk/Button").button_pressed = false
	UI.get_node("BattleLayer/BattleToolbelt/AreaAtk/Button").button_pressed = false
	UI.get_node("BattleLayer/BattleToolbelt/HeavyAtk/Button").button_pressed = false

	if not dead:
		UI.Survived.visible = true
		
	else:
		UI.Death.visible = true
		MainScene.wood_resource = 0
		MainScene.stone_resource = 0
		MainScene.iron_resource = 0
		MainScene.minerals_resource = 0
		MainScene.oil_resource = 0
		UI.update_resources()
	await get_tree().create_timer(2).timeout
	UI.Survived.visible = false
	UI.Death.visible = false
	MainScene.Map.visible = true
	await MainScene.add_player()
	queue_free()
	
# -------------------------
# UI
# -------------------------

func _on_basic_changed(pressed: bool):
	if pressed:
		basic_atk_selected = true
		area_atk_selected = false
		heavy_atk_selected = false
		Player.player_clicked = false
		clear_preview()
		
		var prev_area = get_neighbors(prev_map_tile)
		prev_area.append(prev_map_tile)
		for i in prev_area:
			CurrentMap.set_cell(1, i, -1)
		CurrentMap.set_cell(1, attacked_tile, -1)
		
	else: basic_atk_selected = false
	if not Player.player_clicked:
		CurrentMap.set_cell(1, player_tile, -1)

func _on_area_changed(pressed: bool):
	if pressed:
		basic_atk_selected = false
		area_atk_selected = true
		heavy_atk_selected = false
		Player.player_clicked = false
		clear_preview()
		
		CurrentMap.set_cell(1, prev_map_tile, -1)
		CurrentMap.set_cell(1, attacked_tile, -1)
		
	else: area_atk_selected = false
	if not Player.player_clicked:
		CurrentMap.set_cell(1, player_tile, -1)
	else:
		var area = get_neighbors(player_tile)
		for i in area:
			CurrentMap.set_cell(1, i, -1)

func _on_heavy_changed(pressed: bool):
	if pressed:
		
		basic_atk_selected = false
		area_atk_selected = false
		heavy_atk_selected = true
		Player.player_clicked = false
		clear_preview()

		var prev_area = get_neighbors(prev_map_tile)
		prev_area.append(prev_map_tile)
		for i in prev_area:
			CurrentMap.set_cell(1, i, -1)
	else: heavy_atk_selected = false
	if not Player.player_clicked:
		CurrentMap.set_cell(1, player_tile, -1)

func health_update():
	UI.HealthBar.value = Player.health






