@tool
extends TextureButton

signal date_selected(date_obj)

@export
var image_normal: CompressedTexture2D = load("res://addons/calendar_button/btn_img/btn_64x64_03.png")
@export
var image_pressed: CompressedTexture2D = load("res://addons/calendar_button/btn_img/btn_64x64_04.png")

var calendar := Calendar.new()
var selected_date := Date.new()
var window_restrictor := WindowRestrictor.new()

var popup: Popup
var calendar_buttons: CalendarButtons
var month_picker: OptionButton
var year_edit: LineEdit

func _enter_tree():
	set_toggle_mode(true)
	setup_calendar_icon()
	popup = create_popup_scene()
	_style_calendar()
	popup.popup_hide.connect(close_popup)
	calendar_buttons = create_calendar_buttons()
	setup_month_and_year_signals(popup)
	refresh_data()

func _style_calendar() -> void:
	popup.size = Vector2i(356, 370)
	popup.min_size = Vector2i(356, 370)
	var panel: PanelContainer = popup.get_node("PanelContainer")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102a3a")
	style.border_color = Color("32647a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box: VBoxContainer = panel.get_node("vbox")
	box.add_theme_constant_override("separation", 8)
	box.get_node("hbox_deadspace").hide()
	var header: HBoxContainer = box.get_node("hbox_month_year")
	var order := ["button_prev_year", "button_prev_month", "label_month_year", "button_next_month", "button_next_year"]
	for i in range(order.size()):
		header.move_child(header.get_node(order[i]), i)
	header.get_node("label_month_year").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tips := ["Previous year", "Previous month", "", "Next month", "Next year"]
	for i in range(order.size()):
		header.get_node(order[i]).tooltip_text = tips[i]
	header.get_node("button_prev_year").hide()
	header.get_node("button_next_year").hide()
	header.get_node("label_month_year").hide()
	month_picker = OptionButton.new()
	month_picker.name = "MonthPicker"
	month_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	month_picker.tooltip_text = "Choose month"
	for month_name in ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]:
		month_picker.add_item(month_name)
	header.add_child(month_picker)
	header.move_child(month_picker, 2)
	month_picker.item_selected.connect(_month_selected)
	year_edit = LineEdit.new()
	year_edit.name = "YearEdit"
	year_edit.custom_minimum_size.x = 76
	year_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	year_edit.tooltip_text = "Type a year (1–9999), then press Enter or choose a day"
	year_edit.text_changed.connect(_filter_year)
	year_edit.text_submitted.connect(func(_value: String): _commit_year())
	year_edit.focus_exited.connect(_commit_year)
	header.add_child(year_edit)
	header.move_child(year_edit, 3)
	for row_name in ["hbox_label_days", "hbox_days"]:
		var grid: GridContainer = box.get_node(row_name)
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for item in grid.get_children():
			item.custom_minimum_size = Vector2(42, 32)
			if item is Button:
				item.focus_mode = Control.FOCUS_ALL
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(footer)
	var today := Button.new()
	today.text = "Today"
	today.custom_minimum_size = Vector2(100, 32)
	today.pressed.connect(func():
		selected_date = Date.new()
		refresh_data()
		date_selected.emit(Date.new(selected_date.day(), selected_date.month(), selected_date.year()))
		close_popup())
	footer.add_child(today)

func _filter_year(value: String) -> void:
	var filtered := ""
	var caret := 0
	for i in range(value.length()):
		if value[i] in "0123456789" and filtered.length() < 4:
			filtered += value[i]
			if i < year_edit.caret_column:
				caret += 1
	if value != filtered:
		year_edit.text = filtered
		year_edit.caret_column = caret

func _commit_year() -> void:
	var year := year_edit.text.to_int()
	if year >= 1 and year <= 9999:
		selected_date.set_year(year)
	refresh_data()

func _month_selected(index: int) -> void:
	selected_date.set_month(index + 1)
	refresh_data()

func setup_calendar_icon():
	# var normal_texture: ImageTexture = create_button_texture("btn_64x64_03.png")
	# var pressed_texture: ImageTexture = create_button_texture("btn_64x64_04.png")
	pass
func create_button_texture(image_name: String) -> ImageTexture:
	var image_normal := Image.load_from_file("res://addons/calendar_button/btn_img/" + image_name)
	var image_texture_normal := ImageTexture.create_from_image(image_normal)
	return image_texture_normal

func create_popup_scene() -> Popup:
	return preload("res://addons/calendar_button/popup.tscn").instantiate() as Popup

func create_calendar_buttons() -> CalendarButtons:
	var calendar_container: GridContainer = popup.get_node("PanelContainer/vbox/hbox_days")
	return CalendarButtons.new(self, calendar_container)

func setup_month_and_year_signals(popup: Popup):
	var month_year_path = "PanelContainer/vbox/hbox_month_year/"
	popup.get_node(month_year_path + "button_prev_month").connect("pressed", Callable(self, "go_prev_month"))
	popup.get_node(month_year_path + "button_next_month").connect("pressed", Callable(self, "go_next_month"))
	popup.get_node(month_year_path + "button_prev_year").connect("pressed", Callable(self, "go_prev_year"))
	popup.get_node(month_year_path + "button_next_year").connect("pressed", Callable(self, "go_next_year"))

func set_popup_title(title: String):
	var label_month_year_node := popup.get_node("PanelContainer/vbox/hbox_month_year/label_month_year") as Label
	label_month_year_node.set_text(title)

func refresh_data():
	selected_date.set_day(mini(selected_date.day(), calendar.get_days_in_month(selected_date.month(), selected_date.year())))
	month_picker.select(selected_date.month() - 1)
	year_edit.text = str(selected_date.year())
	var title: String = str(calendar.get_month_name(selected_date.month()) + " " + str(selected_date.year()))
	set_popup_title(title)
	calendar_buttons.update_calendar_buttons(selected_date)

# when focus exit

func day_selected(btn_node):
	close_popup()
	var day := int(btn_node[0].text)
	selected_date.set_day(day)
	emit_signal("date_selected", selected_date)

func go_prev_month():
	if selected_date.year() == 1 and selected_date.month() == 1:
		return
	selected_date.change_to_prev_month()
	refresh_data()

func go_next_month():
	if selected_date.year() == 9999 and selected_date.month() == 12:
		return
	selected_date.change_to_next_month()
	refresh_data()

func go_prev_year():
	if selected_date.year() <= 1:
		return
	selected_date.change_to_prev_year()
	refresh_data()

func go_next_year():
	if selected_date.year() >= 9999:
		return
	selected_date.change_to_next_year()
	refresh_data()


func close_popup():
	popup.hide()
	set_pressed(false)

func _toggled(is_pressed):
	if (!has_node("popup")):
		add_child(popup)
	if (!is_pressed):
		close_popup()
	else:
		if (has_node("popup")):
			popup.show()
		else:
			add_child(popup)
	
	window_restrictor.restrict_popup_inside_screen(popup)
