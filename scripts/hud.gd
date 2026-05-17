extends CanvasLayer
class_name HUD

func _ready() -> void:
	call_deferred("setup_tab_order")
	
func setup_tab_order() -> void:
	var controls := []

	_collect_focusable(self, controls)

	controls.sort_custom(func(a, b):
		if abs(a.global_position.y - b.global_position.y) < 20:
			return a.global_position.x < b.global_position.x

		return a.global_position.y < b.global_position.y
	)

	for i in range(controls.size()):
		var current = controls[i]
		var next = controls[(i + 1) % controls.size()]
		var prev = controls[(i - 1 + controls.size()) % controls.size()]

		current.focus_next = current.get_path_to(next)
		current.focus_previous = current.get_path_to(prev)


func _collect_focusable(node: Node, arr: Array) -> void:
	for c in node.get_children():

		if c is Control and !c.is_visible_in_tree():
			continue

		if c is Control and c.focus_mode != Control.FOCUS_NONE:
			if c is LineEdit \
			or c is Button \
			or c is HSlider \
			or c is SpinBox:
				arr.append(c)

		_collect_focusable(c, arr)
