extends CanvasLayer
class_name HUD

@onready var help_ita = $Body/HelpPanel/HelpContentPanel/CometPanel/HelpIta
@onready var help_eng = $Body/HelpPanel/HelpContentPanel/CometPanel/HelpEng
@onready var button_ita = $Body/HelpPanel/HelpContentPanel/CometPanel/ButtonIta
@onready var button_eng = $Body/HelpPanel/HelpContentPanel/CometPanel/ButtonEng
func _ready() -> void:
	call_deferred("setup_tab_order")
	call_deferred("_on_ita_pressed")
	
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
		
		
func _on_ita_pressed():
	help_ita.show()
	button_ita.hide()
	help_eng.hide()
	button_eng.show()

func _on_eng_pressed():
	help_ita.hide()
	button_ita.show()
	help_eng.show()
	button_eng.hide()
