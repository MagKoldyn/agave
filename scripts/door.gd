extends Node2D

signal opened

var openness := 0.0:
	set(value):
		openness = clampf(value, 0.0, 1.0)
		queue_redraw()
var animating := false

func _ready() -> void:
	z_index = 5
	queue_redraw()

func open_temporarily(hold_seconds := 1.0) -> void:
	if animating:
		return
	animating = true
	var opening := create_tween()
	opening.tween_method(_set_openness, openness, 1.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await opening.finished
	opened.emit()
	await get_tree().create_timer(hold_seconds).timeout
	var closing := create_tween()
	closing.tween_method(_set_openness, 1.0, 0.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await closing.finished
	animating = false

func open_and_hold() -> void:
	if animating or openness >= 0.99:
		return
	animating = true
	var opening := create_tween()
	opening.tween_method(_set_openness, openness, 1.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await opening.finished
	opened.emit()
	animating = false

func close() -> void:
	if animating or openness <= 0.01:
		return
	animating = true
	var closing := create_tween()
	closing.tween_method(_set_openness, openness, 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await closing.finished
	animating = false

func _set_openness(value: float) -> void:
	openness = value

func _draw() -> void:
	# Warm interior becomes visible as the heavy wooden leaf swings inward.
	var glow_alpha := openness * 0.78
	draw_rect(Rect2(-15, -38, 30, 40), Color(1.0, 0.63, 0.24, glow_alpha))
	if openness > 0.03:
		for i in 4:
			var y := -33.0 + i * 9.0
			draw_line(Vector2(-11, y), Vector2(10, y - 3), Color(1.0, 0.86, 0.5, glow_alpha * 0.24), 2.0)

	# Pixel-stone jamb and lintel.
	draw_rect(Rect2(-19, -42, 5, 46), Color("6f432d"))
	draw_rect(Rect2(14, -42, 5, 46), Color("4b3025"))
	draw_rect(Rect2(-19, -45, 38, 6), Color("8e5837"))
	draw_line(Vector2(-14, -39), Vector2(-14, 2), Color("c4834d"), 1.0)
	draw_line(Vector2(14, -39), Vector2(14, 2), Color("2d211c"), 2.0)

	# Perspective width shrinks during the swing; the hinge remains fixed.
	var leaf_width := lerpf(28.0, 4.0, openness)
	var hinge_x := -14.0
	var far_x := hinge_x + leaf_width
	var top_shift := openness * 5.0
	var leaf := PackedVector2Array([
		Vector2(hinge_x, -39),
		Vector2(far_x, -39 + top_shift),
		Vector2(far_x, 1 - top_shift * 0.25),
		Vector2(hinge_x, 2)
	])
	draw_colored_polygon(leaf, Color("6f351f"))
	draw_polyline(PackedVector2Array([leaf[0], leaf[1], leaf[2], leaf[3], leaf[0]]), Color("2b1a16"), 2.0)
	if leaf_width > 9.0:
		var panel_right := far_x - 3.0
		draw_line(Vector2(hinge_x + 4, -29), Vector2(panel_right, -28 + top_shift), Color("a45b2d"), 2.0)
		draw_line(Vector2(hinge_x + 4, -11), Vector2(panel_right, -10), Color("a45b2d"), 2.0)
		draw_line(Vector2(hinge_x + 3, -35), Vector2(hinge_x + 3, -3), Color("4b271b"), 1.0)
		draw_circle(Vector2(far_x - 5, -18 + top_shift * 0.35), 1.8, Color("e2ad52"))
		draw_circle(Vector2(far_x - 5, -18 + top_shift * 0.35), 0.7, Color("fff0ae"))
