extends Node2D
class_name Game

const TILE_SIZE = 32

var level_size := 50
var min_area_size := 5
var split_range := [0.4, 0.6]
var corridor_width := 2
var show_corridor := true
var map_tree: MapTree


func get_level_size_rect():
	return Rect2(Vector2.ZERO, Vector2(level_size, level_size))


func _on_LevelSizeInput_value_changed(value: float):
	level_size = int(value)


func _on_MinAreaSizeInput_value_changed(value: float):
	min_area_size = int(value)


func _on_ShowCorridorButton_toggled(button_pressed: bool):
	show_corridor = not show_corridor
	update()


func _on_Button_pressed():
	build_level()


func _on_MinSplitRangeInput_value_changed(value: float):
	split_range[0] = value


func _on_MaxSplitRangeInput_value_changed(value: float):
	split_range[1] = value


func _on_CorridorWidthInput_value_changed(value: float):
	corridor_width = int(value)


func _ready():
	randomize()
	build_level()

func _draw():
	for r in map_tree.room_areas:
		var scaled = Rect2(
			r.position * TILE_SIZE,
			r.size * TILE_SIZE
		)
		draw_rect(scaled, Color.green, false)
	
	if show_corridor:
		for c in map_tree.corridor_areas:
			var scaled = Rect2(
				c.position * TILE_SIZE,
				c.size * TILE_SIZE
			)
			draw_rect(scaled, Color.red, false)


func build_level():
	map_tree = MapTree.new(4, self)
	
#	for r in map_tree.room_areas:
#		print("room area: %s" % r)
#
#	for c in map_tree.corridor_areas:
#		print("corridor area: %s" % c)

	update()


class MapTree:
# private var
	var root: MapTreeNode
	var level_size: Rect2
	var game: Game
	
# public var
	var room_areas: Array = []
	var corridor_areas: Array = []
	
	func _init(iter_times: int, game: Game):
		self.game = game
		self.level_size = game.get_level_size_rect()
		self.root = make_root(iter_times)
		
		store_leafs_and_corridor(self.root)


	func make_root(iter_times: int):
		root = MapTreeNode.new()
		root.parent = null
		root.area = self.level_size
		
		root.split(iter_times, game.split_range)
		root.merge_too_small_area(game.min_area_size)
		
		root.build_corridor(game.corridor_width)
		
		return root


	func store_leafs_and_corridor(maptree_node: MapTreeNode):
		if maptree_node == null:
			return
		
		if maptree_node.left_child == null and maptree_node.right_child == null:
			room_areas.append(maptree_node.area)
		
		if maptree_node.corridor_area != null:
			corridor_areas.append(maptree_node.corridor_area)
		
		store_leafs_and_corridor(maptree_node.left_child)
		store_leafs_and_corridor(maptree_node.right_child)


class MapTreeNode:
	enum SplitDir {
		H,
		V
	}

	var parent: MapTreeNode
	var left_child: MapTreeNode
	var right_child: MapTreeNode

	var area: Rect2
	var corridor_area: Rect2


	func random_split_dir() -> int:
		var dir = SplitDir.H
		
		if abs(area.size.x - area.size.y) < 3:
			match randi() % 2:
				0:
					dir = SplitDir.H
				1:
					dir = SplitDir.V
		else:
			if area.size.x > area.size.y:
				dir = SplitDir.V
			else:
				dir = SplitDir.H
		
		return dir


	func random_split_point(split_range: Array) -> Vector2:
		var factor = rand_range(split_range[0], split_range[1])
		return (area.position + area.size * factor)


	func split_line(split_range: Array) -> Array:
		var split_point = random_split_point(split_range)
		var split_dir = random_split_dir()
		
		var start_point: Vector2
		var end_point: Vector2
		match split_dir:
			SplitDir.V:
				start_point = Vector2(
					int(split_point.x),
					area.position.y
				)
				end_point = Vector2(
					int(split_point.x),
					area.end.y
				)
			SplitDir.H:
				start_point = Vector2(
					area.position.x,
					int(split_point.y)
				)
				end_point = Vector2(
					area.end.x,
					int(split_point.y)
				)
		
		return [start_point, end_point]


	func is_too_small(min_area_size: int):
		return area.size.x < min_area_size or area.size.y < min_area_size


# public
	func split(times: int, split_range: Array) -> void:
		if times <= 0:
			return
		
		var line := split_line(split_range)
		var right_child_area_start = line[0]
		var left_child_area_end = line[1]
		
		left_child = MapTreeNode.new()
		left_child.parent = self
		left_child.area = Rect2(
			area.position,
			left_child_area_end - area.position
		)
		
		right_child = MapTreeNode.new()
		right_child.parent = self
		right_child.area = Rect2(
			right_child_area_start,
			area.end - right_child_area_start
		)
		
		var remain_times = times - 1
		left_child.split(remain_times, split_range)
		right_child.split(remain_times, split_range)

	func build_corridor(corridor_width: int):
		if left_child == null or right_child == null:
			return
		
		var left_center = left_child.area.get_center()
		var right_center = right_child.area.get_center()
		
#		print("left_center: %s right_center: %s", [left_center, right_center])
		
		var start = Vector2(int(left_center.x), int(left_center.y))
		var end = Vector2(int(right_center.x), int(right_center.y))
		
		var offset = corridor_width / 2
		
		if start.x == end.x:
			start.x -= offset
			end.x += offset
		elif start.y == end.y:
			start.y -= offset
			end.y += offset
		else:
			printerr("两个中心点不在一条直线上？")
		
		corridor_area = Rect2(
			start,
			end - start
		)
		
		left_child.build_corridor(corridor_width)
		right_child.build_corridor(corridor_width)
	
	func merge_too_small_area(min_area_size: int):
		if left_child == null or right_child == null:
			return
		
		if left_child.is_too_small(min_area_size) or right_child.is_too_small(min_area_size):
			left_child = null
			right_child = null
		else:
			left_child.merge_too_small_area(min_area_size)
			right_child.merge_too_small_area(min_area_size)


