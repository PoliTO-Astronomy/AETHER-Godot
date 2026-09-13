extends Control
class_name ScientificDirectionOverlay

var ink_color := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_ink_color(color: Color) -> void:
	ink_color = color
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var title_size := 15
	var body_size := 14
	var origin := Vector2.ZERO
	draw_string(font, origin + Vector2(8, 18), "Sky directions", HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, ink_color)
	_draw_direction_row(origin + Vector2(25, 47), 0.0, "N", "North  PA 0.0 deg", body_size)
	_draw_direction_row(origin + Vector2(25, 79), Util.sun_direction, "S", "Sun  PA %.1f deg" % _normalized_pa(Util.sun_direction), body_size)
	_draw_direction_row(origin + Vector2(25, 111), Util.psamv, "T", "Dust tail  PsAMV %.1f deg" % _normalized_pa(Util.psamv), body_size)

func _draw_direction_row(origin: Vector2, pa_degrees: float, symbol: String, caption: String, font_size: int) -> void:
	# Astronomical position angle: North is up and East is left in the sky view.
	var direction := pa_to_screen_direction(pa_degrees)
	var tip := origin + direction * 20.0
	draw_line(origin, tip, ink_color, 2.5, true)
	var side := direction.orthogonal()
	var head := PackedVector2Array([tip, tip - direction * 7.0 + side * 4.0, tip - direction * 7.0 - side * 4.0])
	draw_colored_polygon(head, ink_color)
	draw_circle(origin, 3.0, ink_color)
	draw_string(ThemeDB.fallback_font, origin + Vector2(30, 5), "%s  %s" % [symbol, caption], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink_color)

func _normalized_pa(value: float) -> float:
	return fposmod(value, 360.0)

func pa_to_screen_direction(pa_degrees: float) -> Vector2:
	var angle := deg_to_rad(_normalized_pa(pa_degrees))
	return Vector2(-sin(angle), -cos(angle))
