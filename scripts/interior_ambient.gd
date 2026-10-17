extends Node2D

var location_id := "home"
var elapsed := 0.0
var motes: Array[Vector2] = []

func _ready() -> void:
	z_index = 2
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(location_id)
	for i in 22:
		motes.append(Vector2(rng.randf_range(70, 1080), rng.randf_range(100, 560)))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for i in motes.size():
		var p := motes[i] + Vector2(sin(elapsed * 0.5 + i) * 5.0, -fmod(elapsed * (2.0 + i % 3), 24.0))
		var color := Color(1.0, 0.76, 0.38, 0.10 + 0.07 * sin(elapsed + i))
		if location_id == "aqueduct":
			color = Color(0.52, 1.0, 0.94, 0.16 + 0.08 * sin(elapsed + i))
		draw_circle(p, 1.0 + i % 2, color)
	if location_id in ["home", "workshop"]:
		var fire_position := Vector2(576, 151) if location_id == "home" else Vector2(897, 252)
		for i in 5:
			var phase := fmod(elapsed * 1.8 + i / 5.0, 1.0)
			var flame := fire_position + Vector2(sin(elapsed * 7.0 + i) * 7.0, -phase * 22.0)
			draw_circle(flame, 4.0 * (1.0 - phase), Color(1.0, 0.48, 0.16, (1.0 - phase) * 0.42))
	if location_id == "aqueduct":
		for i in 18:
			var phase := fmod(elapsed * 0.28 + i / 18.0, 1.0)
			var x := 40.0 + phase * 1070.0
			var y := 365.0 + sin(phase * 18.0 + i) * 34.0
			draw_line(Vector2(x - 7, y), Vector2(x + 7, y - 2), Color(0.66, 1.0, 0.96, 0.26), 2.0)

