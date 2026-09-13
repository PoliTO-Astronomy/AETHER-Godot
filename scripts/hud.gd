extends CanvasLayer
class_name HUD

const AETHER_THEME = preload("res://scripts/aether_theme.gd")
const HELP_CONTENT = preload("res://scripts/help_content.gd")

@onready var help_ita = $Body/HelpPanel/HelpContentPanel/CometPanel/HelpIta
@onready var help_eng = $Body/HelpPanel/HelpContentPanel/CometPanel/HelpEng
@onready var button_ita = $Body/HelpPanel/HelpContentPanel/CometPanel/ButtonIta
@onready var button_eng = $Body/HelpPanel/HelpContentPanel/CometPanel/ButtonEng

var section_controls_layer: CanvasLayer
var top_navigation_layer: CanvasLayer
var top_save_button: Button
var top_load_button: Button
var help_title: Label
var help_subtitle: Label
var help_navigation: VBoxContainer
var help_section_buttons: Array[Button] = []
var help_language := "it"
var help_section := 0
var section_definitions: Dictionary = {}
var section_buttons: Dictionary = {}
var section_collapsed: Dictionary = {}
var section_original_offsets: Dictionary = {}
var left_section_order := ["sun", "nucleus", "dust", "jets"]
var right_section_order := ["nucleus_model", "date", "ccd", "run"]

func _ready() -> void:
	_apply_application_theme()
	_setup_top_navigation_layer()
	call_deferred("_layout_top_navigation")
	call_deferred("setup_tab_order")
	call_deferred("_setup_help_page")
	call_deferred("_layout_nucleus_parameters")
	call_deferred("_setup_collapsible_sections")
	$Body/CometTab/Control/CometPanel.resized.connect(_layout_nucleus_parameters)
	$Body/ModelPanel/Navbar.tab_changed.connect(_on_primary_tab_changed_for_sections)
	get_viewport().size_changed.connect(func():
		call_deferred("_layout_collapsible_sections")
		call_deferred("_layout_top_navigation")
		call_deferred("_layout_help_page"))

func _apply_application_theme() -> void:
	var application_theme: Theme = AETHER_THEME.create()
	for node in find_children("*", "", true, false):
		if node is Control or node is Window:
			node.theme = application_theme

func _setup_top_navigation_layer() -> void:
	top_save_button = $Body/TabButtons/SaveBtn
	top_load_button = $Body/TabButtons/LoadBtn
	top_navigation_layer = CanvasLayer.new()
	top_navigation_layer.name = "TopNavigationControls"
	top_navigation_layer.layer = 30
	add_child(top_navigation_layer)
	top_save_button.reparent(top_navigation_layer, true)
	top_load_button.reparent(top_navigation_layer, true)

func _layout_top_navigation() -> void:
	var tabs: TabContainer = $Body/ModelPanel/Navbar
	var tab_bar: TabBar = tabs.get_tab_bar()
	var tab_rect := tab_bar.get_global_rect()
	if tab_rect.size.x <= 0.0 or tab_rect.size.y <= 0.0:
		return
	var final_tab_rect := tab_bar.get_tab_rect(tab_bar.tab_count - 1)
	var button_size := Vector2(36, 36)
	var first_x := tab_rect.position.x + final_tab_rect.end.x + 14.0
	for index in range(2):
		var button: Button = top_save_button if index == 0 else top_load_button
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.global_position = Vector2(first_x + index * 44.0, tab_rect.position.y - 10.0)
		button.size = button_size

func _setup_collapsible_sections() -> void:
	await get_tree().process_frame
	section_controls_layer = CanvasLayer.new()
	section_controls_layer.name = "SectionCollapseControls"
	section_controls_layer.layer = 20
	add_child(section_controls_layer)
	section_definitions = {
		"sun": _section($Body/CometTab/Control/SunPanelLabel, _sun_section_body(), _sun_section_layout()),
		"nucleus": _section($Body/CometTab/Control/CometPanelLabel, _nucleus_section_body(), _nucleus_section_layout()),
		"dust": _section($Body/CometTab/Control/ParticlePanelLabel, _dust_section_body(), _dust_section_layout()),
		"jets": _section($Body/JetsTab/Control/ParticlePanelLabel, _jets_section_body(), _jets_section_layout()),
		"nucleus_model": _section($Viewport/NucleusModelLabel, _nucleus_model_section_body(), _nucleus_model_section_layout()),
		"date": _section($Body/CometTab/Control/SwitchDate/ChangeDateLabel, _date_section_body(), _date_section_layout()),
		"ccd": _section($Body/SimTab/Control/CCDImgLabel, _ccd_section_body(), _ccd_section_layout()),
		"run": _section($Body/TabButtons/RunModelLabel, _run_section_body(), _run_section_layout()),
	}
	for section_id in section_definitions:
		section_collapsed[section_id] = false
		var header: Label = section_definitions[section_id]["header"]
		header.add_theme_font_size_override("font_size", 17)
		header.add_theme_color_override("font_color", AETHER_THEME.ACCENT_BRIGHT)
		var button := _make_section_button(section_id)
		section_buttons[section_id] = button
		for node: Control in section_definitions[section_id]["layout"]:
			section_original_offsets[node] = Vector2(node.offset_top, node.offset_bottom)
	_apply_section_state()

func _section(header: Control, body: Array[Control], layout: Array[Control]) -> Dictionary:
	return {"header": header, "body": body, "layout": layout}

func _with_header(header: Control, body: Array[Control]) -> Array[Control]:
	var nodes: Array[Control] = [header]
	nodes.append_array(body)
	return nodes

func _make_section_button(section_id: String) -> Button:
	var button := Button.new()
	button.name = section_id.to_pascal_case() + "CollapseButton"
	button.text = "−"
	button.tooltip_text = "Minimize %s section" % section_id.replace("_", " ")
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", AETHER_THEME.TEXT_SECONDARY)
	button.add_theme_color_override("font_hover_color", AETHER_THEME.ACCENT_BRIGHT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(AETHER_THEME.INPUT, 0.72)
	normal.set_corner_radius_all(4)
	var hover := normal.duplicate()
	hover.bg_color = AETHER_THEME.SECTION
	hover.border_color = AETHER_THEME.BORDER
	hover.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(func(): _toggle_section(section_id))
	section_controls_layer.add_child(button)
	return button

func _toggle_section(section_id: String) -> void:
	section_collapsed[section_id] = not section_collapsed[section_id]
	for node: Control in section_definitions[section_id]["body"]:
		node.visible = not section_collapsed[section_id]
	_apply_section_state()

func _on_primary_tab_changed_for_sections(_tab: int) -> void:
	call_deferred("_apply_section_state")

func _apply_section_state() -> void:
	if section_controls_layer == null:
		return
	var is_model: bool = $Body/ModelPanel/Navbar.current_tab == 1
	for section_id in section_definitions:
		var collapsed: bool = section_collapsed[section_id]
		section_buttons[section_id].visible = is_model
		section_buttons[section_id].text = "+" if collapsed else "−"
		section_buttons[section_id].tooltip_text = ("Restore " if collapsed else "Minimize ") + section_id.replace("_", " ") + " section"
		if is_model and collapsed:
			for node: Control in section_definitions[section_id]["body"]:
				node.visible = false
	_update_compact_model_layout(is_model)
	_layout_collapsible_sections()
	call_deferred("setup_tab_order")

func _all_sections_collapsed(order: Array) -> bool:
	for section_id in order:
		if not section_collapsed[section_id]:
			return false
	return true

func _update_compact_model_layout(is_model: bool) -> void:
	var compact_left := is_model and _all_sections_collapsed(left_section_order)
	var compact_right := is_model and _all_sections_collapsed(right_section_order)
	var fully_compact := compact_left and compact_right
	$Body/ModelPanel.anchor_right = 0.17 if compact_left else 0.310417
	var main_view: Panel = $Viewport/Panel
	main_view.anchor_left = 0.18 if compact_left else 0.325
	main_view.anchor_right = 0.85 if compact_right else 0.79375
	main_view.anchor_top = 0.025 if fully_compact else 0.0417476
	main_view.anchor_bottom = 0.93 if fully_compact else 0.915534

func _layout_collapsible_sections() -> void:
	if section_controls_layer == null or $Body/ModelPanel/Navbar.current_tab != 1:
		return
	for node in section_original_offsets:
		var offsets: Vector2 = section_original_offsets[node]
		node.offset_top = offsets.x
		node.offset_bottom = offsets.y
	_layout_section_column(left_section_order, 34.0, $Body/ModelPanel.get_global_rect().end.x - 32.0)
	_layout_section_column(right_section_order, 34.0, $Viewport/NucleusPanelRect.get_global_rect().end.x - 30.0)

func _layout_section_column(order: Array, collapsed_height: float, button_x: float) -> void:
	var first_header: Control = section_definitions[order[0]]["header"]
	var cursor: float = first_header.global_position.y
	var base_header_positions: Array[float] = []
	for section_id in order:
		var base_header: Control = section_definitions[section_id]["header"]
		base_header_positions.append(base_header.global_position.y)
	for index in range(order.size()):
		var section_id: String = order[index]
		var definition: Dictionary = section_definitions[section_id]
		var header: Control = definition["header"]
		var base_header_y: float = header.global_position.y
		var shift: float = cursor - base_header_y
		for node: Control in definition["layout"]:
			node.global_position = Vector2(node.global_position.x, node.global_position.y + shift)
		var button: Button = section_buttons[section_id]
		button.position = Vector2(button_x, header.global_position.y - 1.0)
		button.size = Vector2(26, 26)
		if index < order.size() - 1:
			var expanded_height: float = base_header_positions[index + 1] - base_header_positions[index]
			cursor += collapsed_height if section_collapsed[section_id] else expanded_height

func _sun_section_body() -> Array[Control]:
	return [$Body/CometTab/Control/SunPanel, $Body/CometTab/Control/EditSunIncl, $Body/CometTab/Control/EditSunDir, $Body/CometTab/Control/SunCometDistLabel, $Body/CometTab/Control/EditSunCometDist, $Body/CometTab/Control/SubsolarPLabel, $Body/CometTab/Control/SubsolarPLineEdit, $Body/CometTab/Control/SunInfoBtn, $Body/CometTab/Control/HSeparator2]
func _sun_section_layout() -> Array[Control]: return _with_header($Body/CometTab/Control/SunPanelLabel, _sun_section_body())

func _nucleus_section_body() -> Array[Control]:
	return [$Body/CometTab/Control/CometPanel, $Body/CometTab/Control/EditRadius, $Body/SimTab/Control/FrequencyEdit, $Body/CometTab/Control/NumRotationLabel, $Body/CometTab/Control/NumRotationEdit, $Body/CometTab/Control/AlphaPSanEdit, $Body/CometTab/Control/DeltaPSanEdit, $Body/CometTab/Control/EditCometDir, $Body/CometTab/Control/EditCometIncl, $Body/CometTab/Control/LambdaLabel, $Body/CometTab/Control/LambdaLineEdit, $Body/CometTab/Control/PhiLabel, $Body/CometTab/Control/PhiLineEdit, $Body/CometTab/Control/BetaLabel, $Body/CometTab/Control/BetaLineEdit, $Body/CometTab/Control/ILabel, $Body/CometTab/Control/ILineEdit, $Body/CometTab/Control/SpinAxisInfoBtn, $Body/CometTab/Control/HSeparator]
func _nucleus_section_layout() -> Array[Control]: return _with_header($Body/CometTab/Control/CometPanelLabel, _nucleus_section_body())

func _dust_section_body() -> Array[Control]:
	return [$Body/CometTab/Control/ParticlePanel, $Body/CometTab/Control/EditAlbedo, $Body/CometTab/Control/AlbedoLabel, $Body/CometTab/Control/EditParticleDiameter, $Body/CometTab/Control/ParticleDiameterLabel, $Body/CometTab/Control/EditParticleDensity, $Body/CometTab/Control/ParticleDensityLabel, $Body/CometTab/Control/BetaValLineEdit, $Body/CometTab/Control/BetaValLabel, $Body/SimTab/Control/AccelValLineEdit, $Body/SimTab/Control/AccelValLabel, $Body/CometTab/Control/DustInfoBtn, $Body/CometTab/Control/HSeparator3]
func _dust_section_layout() -> Array[Control]: return _with_header($Body/CometTab/Control/ParticlePanelLabel, _dust_section_body())

func _jets_section_body() -> Array[Control]: return [$Body/JetsTab/Control/JetPanel, $Body/JetsTab/Control/JetTable, $Body/JetsTab/Control/JetRateEdit, $Body/JetsTab/Control/JetRateLabel, $Body/CometTab/Control/JetsInfoBtn]
func _jets_section_layout() -> Array[Control]: return _with_header($Body/JetsTab/Control/ParticlePanelLabel, _jets_section_body())

func _nucleus_model_section_body() -> Array[Control]: return [$Viewport/NucleusPanelRect, $Viewport/NucleusPanel, $Viewport/MiniViewportContainer, $Body/TabButtons/ToggleNucleusGridBtn, $Body/TabButtons/ToggleSunBtn, $Body/TabButtons/ToggleYBtn, $Body/TabButtons/ToggleAxesBtn, $Body/TabButtons/ToggleNucleusDateBtn, $Body/TabButtons/SaveNucleusBtn, $Body/TabButtons/MiniNucleusToggleInfoBtn]
func _nucleus_model_section_layout() -> Array[Control]: return _with_header($Viewport/NucleusModelLabel, _nucleus_model_section_body())

func _date_section_body() -> Array[Control]: return [$Body/CometTab/Control/SwitchDate/CometPanel, $Body/CometTab/Control/SwitchDate/PrevDateFullBtn, $Body/CometTab/Control/SwitchDate/PrevDateBtn, $Body/CometTab/Control/SwitchDate/NextDateBtn, $Body/CometTab/Control/SwitchDate/NextDateFullBtn, $Body/CometTab/Control/ChangeDateInfoBtn]
func _date_section_layout() -> Array[Control]: return [$Body/CometTab/Control/SwitchDate, $Body/CometTab/Control/ChangeDateInfoBtn]

func _ccd_section_body() -> Array[Control]: return [$Body/SimTab/Control/CCDImagePanel, $Body/SimTab/Control/ToggleTransparency, $Body/SimTab/Control/ModelTransparencyLabel, $Body/SimTab/Control/TransparencySlider, $Body/SimTab/Control/ImageOpacityLabel, $Body/SimTab/Control/ImageOpacitySlider, $Body/SimTab/Control/CCDImageInfoBtn, $Body/ScaleTab/Control]
func _ccd_section_layout() -> Array[Control]: return _with_header($Body/SimTab/Control/CCDImgLabel, _ccd_section_body())

func _run_section_body() -> Array[Control]: return [$Body/TabButtons/RunModelBtn, $Body/TabButtons/AnimationSlider, $Body/TabButtons/SaveSimBtn, $Body/TabButtons/RunModelInfoBtn]
func _run_section_layout() -> Array[Control]: return _with_header($Body/TabButtons/RunModelLabel, _run_section_body())

func _place_control(control: Control, rect: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size

func _layout_nucleus_parameters() -> void:
	# Keep the three rotation inputs in separate columns, above the RA/Dec rows.
	var panel: Control = $Body/CometTab/Control/CometPanel
	var origin := panel.position + Vector2(12, 4)
	var available := panel.size.x - 48.0
	var radius_width := available * 0.30
	var period_width := available * 0.37
	var rotations_width := available - radius_width - period_width
	var radius: Control = $Body/CometTab/Control/EditRadius
	var period: Control = $Body/SimTab/Control/FrequencyEdit
	_place_control(radius, Rect2(origin, Vector2(radius_width, 46)))
	# Frequency belongs to a different CanvasLayer; convert the panel position.
	var period_origin := panel.global_position + Vector2(24 + radius_width, 4)
	period_origin -= period.get_parent().global_position
	_place_control(period, Rect2(period_origin, Vector2(period_width, 46)))
	for field in [radius, period]:
		var label: Label = field.get_node("Label")
		label.scale = Vector2.ONE
		label.add_theme_font_size_override("font_size", 14)
		_place_control(label, Rect2(0, 0, field.size.x, 24))
		_place_control(field.get_node("Slider"), Rect2(0, 27, field.size.x - 68, 24))
		_place_control(field.get_node("SanitizedEdit"), Rect2(field.size.x - 60, 24, 60, 28))
	var rotation_origin := origin + Vector2(radius_width + period_width + 24, 0)
	var rotation_label: Label = $Body/CometTab/Control/NumRotationLabel
	rotation_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rotation_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rotation_label.add_theme_font_size_override("font_size", 14)
	_place_control(rotation_label, Rect2(rotation_origin, Vector2(rotations_width, 24)))
	_place_control($Body/CometTab/Control/NumRotationEdit,
		Rect2(rotation_origin + Vector2(0, 24), Vector2(rotations_width, 28)))

	# Each following row reserves the full input height plus an seven-pixel gap.
	# RA/Dec use an inline caption so their labels do not occupy the previous row.
	var inner_width := panel.size.x - 24.0
	for row in range(2):
		var field: Control = $Body/CometTab/Control.get_node(
			"AlphaPSanEdit" if row == 0 else "DeltaPSanEdit")
		_place_control(field, Rect2(panel.position + Vector2(12, 67 + row * 39), Vector2(inner_width, 31)))
		var caption: Label = field.get_node("Label")
		caption.scale = Vector2.ONE
		caption.add_theme_font_size_override("font_size", 14)
		_place_control(caption, Rect2(0, 0, 48, 31))
		field.get_node("Slider").scale = Vector2.ONE
		_place_control(field.get_node("Slider"), Rect2(52, 4, inner_width - 124, 24))
		_place_control(field.get_node("SanitizedEdit"), Rect2(inner_width - 60, 0, 60, 31))

	for row in range(2):
		var y := 145.0 + row * 39.0
		var field: Control = $Body/CometTab/Control.get_node(
			"EditCometDir" if row == 0 else "EditCometIncl")
		_place_control(field, Rect2(panel.position + Vector2(12, y), Vector2(250, 31)))
		var caption: Label = field.get_node("Label")
		caption.scale = Vector2.ONE
		caption.add_theme_font_size_override("font_size", 14)
		_place_control(caption, Rect2(0, 0, 182, 31))
		_place_control(field.get_node("SanitizedEdit"), Rect2(184, 0, 60, 31))
		var names := ["Lambda", "Phi"] if row == 0 else ["Beta", "I"]
		for column in range(2):
			var x := 276.0 + column * 124.0
			var prefix: String = names[column]
			var caption_node: Control = $Body/CometTab/Control.get_node(prefix + "Label")
			caption_node.scale = Vector2.ONE
			_place_control(caption_node, Rect2(panel.position + Vector2(x, y + 4), Vector2(38, 27)))
			_place_control($Body/CometTab/Control.get_node(prefix + "LineEdit"),
				Rect2(panel.position + Vector2(x + 40, y), Vector2(76, 31)))
	
func _input(event: InputEvent) -> void:
	# Refresh before Godot handles TAB: tabs and jet rows can change at runtime.
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		setup_tab_order()

func setup_tab_order() -> void:
	var controls: Array[Control] = []

	_collect_focusable(self, controls)

	controls.sort_custom(func(a, b):
		if is_equal_approx(a.global_position.y, b.global_position.y):
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

		if c is CanvasLayer and not c.visible:
			continue

		if c is Control and !c.is_visible_in_tree():
			continue

		if c is Control:
			# Remove links to controls in panels that were previously visible.
			c.focus_next = NodePath()
			c.focus_previous = NodePath()
		if c is Control and c.focus_mode == Control.FOCUS_ALL:
			if c is LineEdit and c.editable:
				arr.append(c)
			elif c is BaseButton and not c.disabled:
				arr.append(c)
			elif c is Slider and c.editable:
				arr.append(c)
			# SpinBox's internal LineEdit participates without a duplicate stop.

		_collect_focusable(c, arr)
		
		
func _setup_help_page() -> void:
	if help_navigation != null:
		return
	help_title = Label.new()
	help_title.add_theme_font_size_override("font_size", 24)
	help_title.add_theme_color_override("font_color", AETHER_THEME.ACCENT_BRIGHT)
	help_subtitle = Label.new()
	help_subtitle.add_theme_color_override("font_color", AETHER_THEME.TEXT_SECONDARY)
	help_navigation = VBoxContainer.new()
	help_navigation.add_theme_constant_override("separation", 8)
	var panel: Panel = $Body/HelpPanel/HelpContentPanel/CometPanel
	panel.add_child(help_title)
	panel.add_child(help_subtitle)
	panel.add_child(help_navigation)
	for index in range(HELP_CONTENT.SECTION_NAMES_IT.size()):
		var section_button := Button.new()
		section_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		section_button.focus_mode = Control.FOCUS_ALL
		section_button.pressed.connect(_select_help_section.bind(index))
		help_navigation.add_child(section_button)
		help_section_buttons.append(section_button)
	for content: RichTextLabel in [help_ita, help_eng]:
		content.fit_content = false
		content.scroll_active = true
		content.add_theme_constant_override("line_separation", 6)
	button_ita.scale = Vector2.ONE
	button_eng.scale = Vector2.ONE
	button_ita.text = "IT  Italiano"
	button_eng.text = "EN  English"
	button_ita.expand_icon = true
	button_eng.expand_icon = true
	button_ita.add_theme_constant_override("icon_max_width", 22)
	button_eng.add_theme_constant_override("icon_max_width", 22)
	button_ita.show()
	button_eng.show()
	panel.resized.connect(_layout_help_page)
	_layout_help_page()
	_refresh_help_page()

func _layout_help_page() -> void:
	if help_navigation == null:
		return
	var panel: Panel = $Body/HelpPanel/HelpContentPanel/CometPanel
	var margin := 24.0
	var header_height := 68.0
	var navigation_width := clampf(panel.size.x * 0.17, 190.0, 250.0)
	_place_control(help_title, Rect2(margin, 14, panel.size.x - 360, 30))
	_place_control(help_subtitle, Rect2(margin, 44, panel.size.x - 360, 24))
	_place_control(button_ita, Rect2(panel.size.x - 286, 18, 126, 38))
	_place_control(button_eng, Rect2(panel.size.x - 150, 18, 126, 38))
	_place_control(help_navigation, Rect2(margin, header_height + 22, navigation_width, panel.size.y - header_height - 46))
	var content_x := margin + navigation_width + 28.0
	var content_rect := Rect2(content_x, header_height + 16, panel.size.x - content_x - margin, panel.size.y - header_height - 34)
	_place_control(help_ita, content_rect)
	_place_control(help_eng, content_rect)

func _select_help_section(index: int) -> void:
	help_section = index
	_refresh_help_page()

func _refresh_help_page() -> void:
	if help_navigation == null:
		return
	var italian := help_language == "it"
	help_title.text = "Guida utente AETHER" if italian else "AETHER User Guide"
	help_subtitle.text = "Procedura, parametri ed esportazione" if italian else "Workflow, parameters and export"
	help_ita.visible = italian
	help_eng.visible = not italian
	help_ita.text = HELP_CONTENT.section("it", help_section)
	help_eng.text = HELP_CONTENT.section("en", help_section)
	help_ita.scroll_to_line(0)
	help_eng.scroll_to_line(0)
	button_ita.set_pressed_no_signal(italian)
	button_eng.set_pressed_no_signal(not italian)
	button_ita.disabled = italian
	button_eng.disabled = not italian
	var names: Array = HELP_CONTENT.section_names(help_language)
	for index in range(help_section_buttons.size()):
		help_section_buttons[index].text = names[index]
		help_section_buttons[index].disabled = index == help_section

func _on_ita_pressed():
	help_language = "it"
	_refresh_help_page()

func _on_eng_pressed():
	help_language = "en"
	_refresh_help_page()
