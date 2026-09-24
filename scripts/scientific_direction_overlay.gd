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
	var font_size := 16
	var origin := Vector2(58, 58)
	_draw_direction_arrow(origin, 0.0, "N", font, font_size)
	_draw_direction_arrow(origin, Util.sun_direction, "S", font, font_size)
	_draw_direction_arrow(origin, Util.sky_motion_pa, "V", font, font_size)

func _draw_direction_arrow(origin: Vector2, pa_degrees: float, symbol: String, font: Font, font_size: int) -> void:
	# Astronomical position angle: North is up and East is left in the sky view.
	var direction := pa_to_screen_direction(pa_degrees)
	var tip := origin + direction * 34.0
	draw_line(origin, tip, ink_color, 2.5, true)
	var side := direction.orthogonal()
	var head := PackedVector2Array([tip, tip - direction * 7.0 + side * 4.0, tip - direction * 7.0 - side * 4.0])
	draw_colored_polygon(head, ink_color)
	draw_string(font, tip + direction * 7.0 + Vector2(-5, 5), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink_color)
	draw_circle(origin, 3.5, ink_color)

func _normalized_pa(value: float) -> float:
	return fposmod(value, 360.0)

func pa_to_screen_direction(pa_degrees: float) -> Vector2:
	var angle := deg_to_rad(_normalized_pa(pa_degrees))
	return Vector2(-sin(angle), -cos(angle))
