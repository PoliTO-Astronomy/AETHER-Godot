extends WorldEnvironment
#@onready var HUD = $HUD

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var _window := get_window()
# 	_window.min_size = Vector2i(1330, 980)
func _ready() -> void:
	# Wait a short moment, then force a resize
	await get_tree().process_frame
	_force_resize_once()
	var _window := get_window()
	var screen_size = DisplayServer.screen_get_usable_rect().size
	_window.min_size = Vector2i(min(1280, screen_size.x), min(720, screen_size.y))

func _force_resize_once() -> void:
	var size := DisplayServer.window_get_size()
	# toggle micro per far scattare davvero i resize dove necessario
	DisplayServer.window_set_size(size)
