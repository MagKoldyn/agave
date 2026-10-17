extends Node2D

var elapsed := 0.0
var roads := [
	PackedVector2Array([Vector2(92,262),Vector2(230,260),Vector2(355,276),Vector2(520,268),Vector2(690,256),Vector2(835,263),Vector2(954,292)]),
	PackedVector2Array([Vector2(194,190),Vector2(220,250),Vector2(330,310),Vector2(455,330),Vector2(580,336),Vector2(730,330),Vector2(900,312)]),
	PackedVector2Array([Vector2(560,190),Vector2(558,270),Vector2(570,360),Vector2(570,478),Vector2(565,565)]),
	PackedVector2Array([Vector2(125,478),Vector2(270,482),Vector2(420,500),Vector2(570,510),Vector2(735,495),Vector2(910,462)])
]

func _ready() -> void:
	z_index = 1
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for road_index in roads.size():
		var road: PackedVector2Array = roads[road_index]
		draw_polyline(road, Color(0.33,0.17,0.10,0.18), 18.0, true)
		draw_polyline(road, Color(0.92,0.64,0.34,0.11), 13.0, true)
		for i in range(1, road.size() - 1):
			var p := road[i]
			var flicker := 0.07 + 0.04 * sin(elapsed * 0.7 + i + road_index)
			draw_circle(p + Vector2(7, 5), 1.5, Color(1.0,0.78,0.42,flicker))

