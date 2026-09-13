extends RefCounted
class_name AetherTheme

const BACKGROUND := Color("07141f")
const PANEL := Color("102a3a")
const SECTION := Color("164255")
const INPUT := Color("0b202d")
const BORDER := Color("32647a")
const ACCENT := Color("238aa3")
const ACCENT_BRIGHT := Color("45b8cf")
const TEXT := Color("f2f6f8")
const TEXT_SECONDARY := Color("b7c7cf")
const DISABLED := Color("71838c")
const DISABLED_BG := Color("172c36")

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16

	for type_name in ["Label", "RichTextLabel"]:
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_shadow_color", type_name, Color(0, 0, 0, 0.35))

	for type_name in ["Button", "OptionButton", "MenuButton"]:
		_style_button(theme, type_name)

	for type_name in ["CheckBox", "CheckButton"]:
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_hover_color", type_name, TEXT)
		theme.set_color("font_pressed_color", type_name, TEXT)
		theme.set_color("font_disabled_color", type_name, DISABLED)
		theme.set_constant("h_separation", type_name, 8)
		# CheckBox and CheckButton inherit Button styles. Clear those backgrounds so
		# the selected state is communicated by the check/switch itself; hover is
		# then shown only by the brighter icon created below.
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			theme.set_stylebox(state, type_name, StyleBoxEmpty.new())
	var checkbox_unchecked := _checkbox_icon(false, false)
	var checkbox_checked := _checkbox_icon(true, false)
	var checkbox_unchecked_highlight := _checkbox_icon(false, false, true)
	var checkbox_checked_highlight := _checkbox_icon(true, false, true)
	theme.set_icon("unchecked", "CheckBox", checkbox_unchecked)
	theme.set_icon("checked", "CheckBox", checkbox_checked)
	theme.set_icon("unchecked_disabled", "CheckBox", _checkbox_icon(false, true))
	theme.set_icon("checked_disabled", "CheckBox", _checkbox_icon(true, true))
	for state in ["hover", "pressed", "hover_pressed", "focus"]:
		theme.set_icon("unchecked_" + state, "CheckBox", checkbox_unchecked_highlight)
		theme.set_icon("checked_" + state, "CheckBox", checkbox_checked_highlight)
	var switch_off := _switch_icon(false, false)
	var switch_on := _switch_icon(true, false)
	var switch_off_highlight := _switch_icon(false, false, true)
	var switch_on_highlight := _switch_icon(true, false, true)
	theme.set_icon("unchecked", "CheckButton", switch_off)
	theme.set_icon("checked", "CheckButton", switch_on)
	theme.set_icon("unchecked_disabled", "CheckButton", _switch_icon(false, true))
	theme.set_icon("checked_disabled", "CheckButton", _switch_icon(true, true))
	for state in ["hover", "pressed", "hover_pressed", "focus"]:
		theme.set_icon("unchecked_" + state, "CheckButton", switch_off_highlight)
		theme.set_icon("checked_" + state, "CheckButton", switch_on_highlight)

	for type_name in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", type_name, _box(INPUT, BORDER, 1, 5, 6.0))
		theme.set_stylebox("focus", type_name, _box(INPUT, ACCENT_BRIGHT, 2, 5, 5.0))
		theme.set_stylebox("read_only", type_name, _box(DISABLED_BG, PANEL, 1, 5, 6.0))
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_uneditable_color", type_name, TEXT_SECONDARY)
		theme.set_color("font_placeholder_color", type_name, Color(TEXT_SECONDARY, 0.7))
		theme.set_color("caret_color", type_name, ACCENT_BRIGHT)
		theme.set_color("selection_color", type_name, Color(ACCENT, 0.65))

	for type_name in ["Panel", "PanelContainer"]:
		theme.set_stylebox("panel", type_name, _box(PANEL, BORDER, 1, 6, 5.0))
	theme.set_stylebox("panel", "PopupPanel", _box(PANEL, BORDER, 1, 7, 8.0))
	theme.set_stylebox("panel", "TooltipPanel", _box(INPUT, BORDER, 1, 5, 6.0))
	theme.set_color("font_color", "TooltipLabel", TEXT)

	theme.set_stylebox("panel", "TabContainer", _box(PANEL, BORDER, 1, 5, 4.0))
	for type_name in ["TabContainer", "TabBar"]:
		theme.set_stylebox("tab_unselected", type_name, _box(INPUT, PANEL, 1, 4, 7.0))
		theme.set_stylebox("tab_hovered", type_name, _box(SECTION, BORDER, 1, 4, 7.0))
		theme.set_stylebox("tab_selected", type_name, _box(SECTION, BORDER, 1, 4, 7.0))
		theme.set_stylebox("tab_disabled", type_name, _box(DISABLED_BG, PANEL, 1, 4, 7.0))
		theme.set_stylebox("tab_focus", type_name, StyleBoxEmpty.new())
		theme.set_color("font_unselected_color", type_name, TEXT_SECONDARY)
		theme.set_color("font_hovered_color", type_name, TEXT)
		theme.set_color("font_selected_color", type_name, TEXT)
		theme.set_color("font_disabled_color", type_name, DISABLED)

	var track := _box(INPUT, PANEL, 0, 3, 0.0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var active_track := _box(ACCENT, ACCENT, 0, 3, 0.0)
	active_track.content_margin_top = 3
	active_track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", active_track)
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT_BRIGHT, ACCENT_BRIGHT, 0, 3, 0.0))

	for type_name in ["Tree", "ItemList"]:
		theme.set_stylebox("panel", type_name, _box(INPUT, BORDER, 1, 4, 4.0))
		theme.set_stylebox("selected", type_name, _box(ACCENT, ACCENT, 0, 3, 2.0))
		theme.set_stylebox("selected_focus", type_name, _box(ACCENT, ACCENT_BRIGHT, 1, 3, 2.0))
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_selected_color", type_name, TEXT)

	for type_name in ["HSeparator", "VSeparator"]:
		theme.set_stylebox("separator", type_name, _box(BORDER, BORDER, 0, 0, 0.0))

	theme.set_stylebox("background", "ProgressBar", _box(INPUT, PANEL, 1, 4, 0.0))
	theme.set_stylebox("fill", "ProgressBar", _box(ACCENT, ACCENT, 0, 4, 0.0))
	theme.set_color("font_color", "ProgressBar", TEXT)
	return theme

static func _style_button(theme: Theme, type_name: String) -> void:
	theme.set_stylebox("normal", type_name, _box(INPUT, BORDER, 1, 5, 6.0))
	theme.set_stylebox("hover", type_name, _box(SECTION, ACCENT_BRIGHT, 1, 5, 6.0))
	theme.set_stylebox("pressed", type_name, _box(ACCENT, ACCENT_BRIGHT, 1, 5, 6.0))
	theme.set_stylebox("focus", type_name, _box(SECTION, ACCENT_BRIGHT, 2, 5, 5.0))
	theme.set_stylebox("disabled", type_name, _box(DISABLED_BG, PANEL, 1, 5, 6.0))
	theme.set_color("font_color", type_name, TEXT)
	theme.set_color("font_hover_color", type_name, TEXT)
	theme.set_color("font_pressed_color", type_name, TEXT)
	theme.set_color("font_focus_color", type_name, TEXT)
	theme.set_color("font_disabled_color", type_name, DISABLED)
	theme.set_color("icon_normal_color", type_name, TEXT)
	theme.set_color("icon_hover_color", type_name, ACCENT_BRIGHT)
	theme.set_color("icon_pressed_color", type_name, TEXT)
	theme.set_color("icon_disabled_color", type_name, DISABLED)

static func _box(bg: Color, border: Color, border_width: int, radius: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func _checkbox_icon(checked: bool, disabled: bool, highlighted: bool = false) -> Texture2D:
	var fill := "#263D48" if disabled and checked else ("#172C36" if disabled else ("#164255" if highlighted and checked else ("#102A3A" if checked else "#0B202D")))
	var stroke := "#52646D" if disabled else ("#45B8CF" if highlighted else ("#32647A" if checked else "#52646D"))
	var check := ""
	if checked:
		check = '<path d="M5.5 10.2L8.5 13.2L14.7 6.8" fill="none" stroke="%s" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>' % ("#B7C7CF" if disabled else "#F2F6F8")
	var source := '<svg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><rect x="1.5" y="1.5" width="17" height="17" rx="3.5" fill="%s" stroke="%s" stroke-width="1.5"/>%s</svg>' % [fill, stroke, check]
	return _texture_from_svg(source)

static func _switch_icon(checked: bool, disabled: bool, highlighted: bool = false) -> Texture2D:
	var fill := "#263D48" if disabled and checked else ("#172C36" if disabled else ("#164255" if highlighted and checked else ("#102A3A" if checked else "#172C36")))
	var stroke := "#52646D" if disabled else ("#45B8CF" if highlighted else ("#32647A" if checked else "#52646D"))
	var knob := "#71838C" if disabled else ("#F2F6F8" if checked else "#B7C7CF")
	var knob_x := 28 if checked else 10
	var source := '<svg width="30" height="16" viewBox="0 0 38 20" xmlns="http://www.w3.org/2000/svg"><rect x="1" y="1" width="36" height="18" rx="9" fill="%s" stroke="%s" stroke-width="1.5"/><circle cx="%d" cy="10" r="6" fill="%s"/></svg>' % [fill, stroke, knob_x, knob]
	return _texture_from_svg(source)

static func _texture_from_svg(source: String) -> Texture2D:
	var image := Image.new()
	var error := image.load_svg_from_string(source)
	if error != OK:
		push_error("Unable to build an interface icon from SVG data.")
		return ImageTexture.new()
	return ImageTexture.create_from_image(image)
