extends Node2D

var elapsed := 0.0
var stream_paths := [
	PackedVector2Array([Vector2(884,207),Vector2(936,181),Vector2(995,151),Vector2(1058,126),Vector2(1126,99),Vector2(1170,84)]),
	PackedVector2Array([Vector2(1003,285),Vector2(1004,323),Vector2(1006,365),Vector2(1021,401),Vector2(1054,420)]),
	PackedVector2Array([Vector2(1110,264),Vector2(1107,309),Vector2(1103,354),Vector2(1085,394),Vector2(1054,420)]),
	PackedVector2Array([Vector2(1054,420),Vector2(1040,456),Vector2(1012,486),Vector2(977,515),Vector2(952,554),Vector2(958,610),Vector2(975,660)])
]

func _ready() -> void:
	z_index = 2
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	# Small travelling highlights reveal the direction and speed of every channel.
	for path_index in stream_paths.size():
		var path: PackedVector2Array = stream_paths[path_index]
		for particle_index in 8:
			var phase := fmod(elapsed * (0.24 + path_index * 0.035) + particle_index / 8.0, 1.0)
			var point := _sample_path(path, phase)
			var ahead := _sample_path(path, minf(phase + 0.025, 1.0))
			var direction := point.direction_to(ahead)
			var normal := Vector2(-direction.y, direction.x)
			var sway := sin(elapsed * 4.0 + particle_index * 1.7 + path_index) * 3.0
			point += normal * sway
			var length := 7.0 if path_index == 0 else 10.0
			var alpha := sin(phase * PI) * 0.58
			draw_line(point - direction * length * 0.5, point + direction * length * 0.5, Color(0.67, 1.0, 0.96, alpha), 2.0)
			draw_circle(point, 1.4, Color(0.9, 1.0, 0.94, alpha * 0.72))

	# Waterfall streaks accelerate downward and break into foam.
	var fall_points: Array[float] = [1003.0, 1108.0, 966.0]
	for fall_x: float in fall_points:
		for i in 7:
			var phase := fmod(elapsed * 0.78 + i / 7.0 + fall_x * 0.001, 1.0)
			var start_y := 286.0 if fall_x > 990.0 else 594.0
			var distance := 83.0 if fall_x > 990.0 else 66.0
			var y := start_y + phase * phase * distance
			var x: float = fall_x + sin(elapsed * 3.0 + i * 2.1) * 3.5
			draw_line(Vector2(x, y - 8), Vector2(x - 1, y + 7), Color(0.78, 1.0, 0.98, 0.5 * (1.0 - phase * 0.5)), 2.0)
		var foam_phase := fmod(elapsed * 0.8 + fall_x * 0.01, 1.0)
		var foam_y := 373.0 if fall_x > 990.0 else 658.0
		draw_arc(Vector2(fall_x, foam_y), 7.0 + foam_phase * 15.0, PI, TAU, 18, Color(0.82, 1.0, 0.96, (1.0 - foam_phase) * 0.52), 2.0)

func _sample_path(path: PackedVector2Array, phase: float) -> Vector2:
	if path.size() < 2:
		return Vector2.ZERO
	var scaled := clampf(phase, 0.0, 0.9999) * float(path.size() - 1)
	var index := mini(int(floor(scaled)), path.size() - 2)
	return path[index].lerp(path[index + 1], scaled - index)
