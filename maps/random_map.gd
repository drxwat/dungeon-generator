extends TileMap

const DEBUG_ENABLED := true

const LAYER := 0
const DUNGEON_CELL_ID = 1

const ROOM_PATH_COST = 3.0
const EMPTY_PATH_COST = 2.0
const CORIDOR_PATH_COST = 1.0

var rng := RandomNumberGenerator.new()

var max_rooms := 8
var max_romm_attemts := 30
var debug_nodes : Array[Node2D] = []

var dungeon_size := Vector2i(8, 16)
var room_max_size := Vector2i(2, 3)
var room_min_size := Vector2i(1, 2)

var rooms : Array[Room] = []
var coridors := {}
var entrance: Vector2i
var exit: Vector2i

func _ready():
	rng.randomize()

func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		clear_debug()
		clear_layer(LAYER)
		generate_map()

func generate_map():
	rooms = []
	for _i in range(max_romm_attemts):
		if rooms.size() >= max_rooms:
			break
		var room = generate_random_room()
		if room is Room:
			rooms.append(room)
			place_room(room)
	
	coridors = build_coridors(rooms)
	generate_entrance(rooms)
	generate_exit(rooms)

func generate_entrance(rooms: Array[Room]):
	var lowest_room := rooms[0]
	for room in rooms:
		if room.center.y > lowest_room.center.y:
			lowest_room = room
	
	var lowest_cell = lowest_room.cells[0]
	for cell in lowest_room.cells:
		if cell.y > lowest_cell.y:
			lowest_cell = cell
	var entrance_cell = lowest_cell + Vector2i(0, 1)
	set_cell(LAYER, entrance_cell, DUNGEON_CELL_ID, Contants.DUNGEON_ENTRANCE_ATLAS)
	entrance = entrance_cell
	
func generate_exit(rooms: Array[Room]):
	var topest_room := rooms[0]
	for room in rooms:
		if room.center.y < topest_room.center.y:
			topest_room = room
	
	var topest_cell = topest_room.cells[0]
	for cell in topest_room.cells:
		if cell.y < topest_cell.y:
			topest_cell = cell
	var exit_cell = topest_cell - Vector2i(0, 1)
	exit = exit_cell
	set_cell(LAYER, exit_cell, DUNGEON_CELL_ID, Contants.DUNGEON_EXIT_ATLAS)
	

func build_coridors(rooms: Array[Room]):
	var room_centers := PackedVector2Array(rooms.map(func (room): return map_to_local(room.center)))
	var vertexes = PackedVector2Array(room_centers)
	
	var delaunay_edges = AdjucencyMatrixGraph.get_delaunay_edges(vertexes)
	var weighted_adjucency_matrix = AdjucencyMatrixGraph.get_weighted_adjucency_matrix(vertexes, delaunay_edges)
	var mst = AdjucencyMatrixGraph.get_minimum_spanning_tree(rng, vertexes, weighted_adjucency_matrix)

	if DEBUG_ENABLED:
		paint_graph(weighted_adjucency_matrix, vertexes)
		paint_graph(mst, vertexes, Color.DARK_RED)
	
	var astar = get_dungeon_area_astar()
	
	return connect_rooms(mst, astar)
				

func get_dungeon_area_astar() -> AStar2D:
	var astar = AStar2D.new()
	var point_id = 0
	for x in range(dungeon_size.x):
		for y in range(dungeon_size.y):
			var cell := Vector2(x, y)
			var is_room := get_cell_source_id(LAYER, cell) != -1
			astar.add_point(point_id, cell, ROOM_PATH_COST if is_room else EMPTY_PATH_COST)
			
			var neighbours = [
				Vector2(x, y - 1),
				Vector2(x - 1, y)
			]
			
			for neghbour in neighbours:
				if neghbour.x < 0 or neghbour.y < 0:
					continue
				astar.connect_points(point_id, astar.get_closest_point(neghbour))

			point_id += 1
	return astar

func connect_rooms(graph: Array, astar: AStar2D) -> Dictionary:
	var coridors := {}
	var connections = [] # unique connections
	for room_index in range(graph.size()):
		var room_connections = graph[room_index]
		for connected_room_index in range(room_connections.size()):
			var connection_key = "{0}{1}".format([min(room_index, connected_room_index), max(room_index, connected_room_index)])
			if connections.has(connection_key) or room_connections[connected_room_index] == 0:
				continue
			
			connections.append(connection_key)
			
			var room = rooms[room_index]
			var connected_room = rooms[connected_room_index]
	
			var coridor_path = astar.get_point_path(
				astar.get_closest_point(room.get_closest_cell_to_room(connected_room)),
				astar.get_closest_point(connected_room.get_closest_cell_to_room(room))
			)

			if coridor_path.size() > 2:
				coridors[connection_key] = coridor_path.slice(1, coridor_path.size() - 1)
				for i in range(1, coridor_path.size() - 1):
					var point = coridor_path[i]
					astar.set_point_weight_scale(astar.get_closest_point(point), CORIDOR_PATH_COST)
					place_coridor(point)
	return coridors

func clear_debug():
	for debug_node in debug_nodes:
		debug_node.queue_free()
	debug_nodes = []

func paint_graph(weighted_adjucency_matrix: Array, vertexes: PackedVector2Array, color = Color("#ffffff")):
	var container := Node2D.new()
	
	for vertex_index in range(weighted_adjucency_matrix.size()):
		var vertex_position = vertexes[vertex_index]
		var vertex_edges = weighted_adjucency_matrix[vertex_index]
		for connected_vertex_index in range(vertex_edges.size()):
			var connected_vertex = vertex_edges[connected_vertex_index]
			if connected_vertex == 0:
				continue
			var edge_line = Line2D.new()
			edge_line.add_point(vertexes[vertex_index], 0)
			edge_line.add_point(vertexes[connected_vertex_index], 1)
			edge_line.default_color = color
			edge_line.width = 4
			container.add_child(edge_line)
	
	debug_nodes.append(container)
	add_child(container)

func generate_random_room():
	var room_size = Vector2i(
		rng.randi_range(room_min_size.x, room_max_size.x), 
		rng.randi_range(room_min_size.y, room_max_size.y))
	var room_position = Vector2i(
		rng.randi_range(1, dungeon_size.x - room_size.x),
		rng.randi_range(1, dungeon_size.y - room_size.y),
	)
	
	for x in range(room_size.x):
		for y in range(room_size.y):
			var cell = room_position + Vector2i(x, y)
			if get_cell_source_id(LAYER, cell) != -1:
				return
			var surrounding_cells = [
				cell + Vector2i(-1, 0),
				cell + Vector2i(-1, -1),
				cell + Vector2i(0, -1),
				cell + Vector2i(1, -1),
				cell + Vector2i(1, 0),
				cell + Vector2i(1, 1),
				cell + Vector2i(0, 1),
				cell + Vector2i(-1, 1),
			]
			if surrounding_cells.any(func(surrounding_cell): return get_cell_source_id(LAYER, surrounding_cell) != -1):
				return
	
	return Room.new(room_size, room_position)

func place_room(room: Room):
	for cell in room.cells:
		set_cell(LAYER, cell, DUNGEON_CELL_ID, Contants.DUNGEON_ROOM_ATLAS)

func place_coridor(cell: Vector2i):
	if get_cell_source_id(LAYER, cell) == -1:
		set_cell(LAYER, cell, DUNGEON_CELL_ID, Contants.DUNGEON_CORIDOR_ATLAS)

class AdjucencyMatrixGraph:
	
	static func get_delaunay_edges(vertexes: PackedVector2Array) -> PackedInt32Array:
		return Geometry2D.triangulate_delaunay(vertexes)
	
	static func get_empty_adjucency_matrix(vertexes: PackedVector2Array) -> Array:
		var adjucency_matrix = range(vertexes.size())
		for i in adjucency_matrix:
			adjucency_matrix[i] = range(vertexes.size()).map(func (i): return 0)
		
		return adjucency_matrix
	
	static func get_weighted_adjucency_matrix(vertexes: PackedVector2Array, delaunay_edges: PackedInt32Array):
		var adjucency_matrix = get_empty_adjucency_matrix(vertexes)
		
		for i in range(delaunay_edges.size() / 3):
			var index = i * 3

			var first = delaunay_edges[index]
			var second = delaunay_edges[index + 1]
			var third = delaunay_edges[index + 2]
			
			adjucency_matrix[first][second] = vertexes[first].distance_squared_to(vertexes[second])
			adjucency_matrix[first][third] = vertexes[first].distance_squared_to(vertexes[third])
			
			adjucency_matrix[second][first] = vertexes[second].distance_squared_to(vertexes[first])
			adjucency_matrix[second][third] = vertexes[second].distance_squared_to(vertexes[third])
			
			adjucency_matrix[third][first] = vertexes[third].distance_squared_to(vertexes[first])
			adjucency_matrix[third][second] = vertexes[third].distance_squared_to(vertexes[second])
		
		return adjucency_matrix
	
#	static func 
	
	# Prims Algorithm 
	static func get_minimum_spanning_tree(rng: RandomNumberGenerator, vertexes: PackedVector2Array, weighted_adjucency_matrix: Array) -> Array:
		var minimum_spanning_tree = get_empty_adjucency_matrix(vertexes)
		var fringe_vertexes = range(vertexes.size())
		var opened_vertexes = []
		
		var first_vertex = rng.randi_range(0, minimum_spanning_tree.size() - 1)
		fringe_vertexes.erase(first_vertex)
		opened_vertexes.append(first_vertex)
		
		while fringe_vertexes.size() > 0:
			var best_edge
			
			for opened_vertex in opened_vertexes:
				var opened_vertex_edges : Array = weighted_adjucency_matrix[opened_vertex]
				for vertex_index in range(opened_vertex_edges.size()):
					var vertex_weight = opened_vertex_edges[vertex_index]
					if vertex_weight == 0 or not fringe_vertexes.has(vertex_index):
						continue
						
					if best_edge == null or vertex_weight < best_edge.weight:
						best_edge = {
							"opened": opened_vertex,
							"fringe": vertex_index,
							"weight": vertex_weight
						}
						
			if best_edge == null:
				break
			
			fringe_vertexes.erase(best_edge.fringe)
			opened_vertexes.append(best_edge.fringe)
			
			minimum_spanning_tree[best_edge.opened][best_edge.fringe] = 1
			minimum_spanning_tree[best_edge.fringe][best_edge.opened] = 1
		
		return minimum_spanning_tree



class Room:
	var room_size: Vector2i
	var room_position: Vector2i
	var cells: Array[Vector2i]
	var center: Vector2i
	
	func _init(_room_size: Vector2i, _room_position: Vector2i):
		room_size = _room_size
		room_position = _room_position
		center = _room_position
		for x in range(room_size.x):
			for y in range(room_size.y):
				cells.append(room_position + Vector2i(x, y))
				
	func get_closest_cell_to_room(target_room: Room) -> Vector2i:
		var closest_cell = cells[0]
		for room_cell in cells:
			for target_room_cell in target_room.cells:
				var room_cell_distance = Vector2(room_cell).distance_squared_to(Vector2(target_room_cell))
				var closest_distance = Vector2(closest_cell).distance_squared_to(Vector2(target_room_cell))
				if room_cell_distance < closest_distance:
					closest_cell = Vector2(room_cell)
		return closest_cell
