# Random Dungeon Generator (Godot v4)

## How to run

1. Download project
2. Run game
3. Press Enter

## How to use

You can generate 3D dungeon based on it or modify TileSet and build 2d Dungeon

Example of 3D dungeon generation:

```py

const RANDOM_MAP := preload("res://maps/random_map.tscn")

func get_random_map() -> TileMap:
	var map = RANDOM_MAP.instantiate()
	map.generate_map()
	return map


func generate_dungeon():
	var map := get_random_map()
	for cell in map.get_used_cells(0):
		var atlas_coords = map.get_cell_atlas_coords(0, cell)
		match atlas_coords:
			Constants.DUNGEON_EXIT_ATLAS:
				pass # generate exit
			Constants.DUNGEON_ENTRANCE_ATLAS:
				pass # generate entrance
			_:
				pass

```

## How to customize

Main controll variables are:

```py
var max_rooms := 8 # Maximun amount of rooms
var dungeon_size := Vector2i(8, 16) # Dungeon size in tiles of TileMap
var room_max_size := Vector2i(2, 3) # Max size of the room in tiles of TileMap
var room_min_size := Vector2i(1, 2) # Min size of the room in tiles of TileMap
```

# Генератор случайных подземелий (Godot v4)

## Как запустить

1. Скачать проект
2. Запустить игру
3. Нажать Enter

## How to use

Ты можешь сгенерировать 3D подземелье на основе случайной карты или модифицировать TileSet и сгенерировать 2D подземелье

Пример генерации 3D подземелья:

```py

const RANDOM_MAP := preload("res://maps/random_map.tscn")

func get_random_map() -> TileMap:
	var map = RANDOM_MAP.instantiate()
	map.generate_map()
	return map


func generate_dungeon():
	var map := get_random_map()
	for cell in map.get_used_cells(0):
		var atlas_coords = map.get_cell_atlas_coords(0, cell)
		match atlas_coords:
			Constants.DUNGEON_EXIT_ATLAS:
				pass # generate exit
			Constants.DUNGEON_ENTRANCE_ATLAS:
				pass # generate entrance
			_:
				pass

```

## Как модифицировать

Основные переменные:

```py
var max_rooms := 8 # Максимальное количество комнат
var dungeon_size := Vector2i(8, 16) # Размер подземелья в тайлах TileMap
var room_max_size := Vector2i(2, 3) # Максимальный размер комнаты в тайлах
var room_min_size := Vector2i(1, 2) # Минимальный размер комнаты в тайлах
```
