extends CanvasLayer

const AETHER_THEME = preload("res://scripts/aether_theme.gd")

@onready var search_bar: LineEdit = $Control/SearchBar
@onready var start_date_ledit: LineEdit = $Control/StartDateLineEdit
@onready var end_date_ledit: LineEdit = $Control/EndDateLineEdit
@onready var scroll_container: ScrollContainer = $Control/EphemScroll
@onready var ephem_table: VBoxContainer = $Control/EphemScroll/EphemTable
@onready var des_options_popup: PopupMenu = $Control/DesignOptionsPopupMenu
@onready var loading_label: Label = $Control/LoadingLabel
var http_request: HTTPRequest
var http_request_name: HTTPRequest
var start_date: Date
var end_date: Date
var step_size: float = 24.0
var date_hints: Array[Label] = []
var observation_title: Label
var results_title: Label
var empty_results_label: Label
var empty_results_overlay: CenterContainer

func _filter_date_characters(_text: String, edit: LineEdit) -> void:
	var filtered := ""
	var caret := 0
	for i in range(edit.text.length()):
		var character := edit.text[i]
		if (character in "0123456789/") and filtered.length() < 10:
			filtered += character
			if i < edit.caret_column:
				caret += 1
	if filtered != edit.text:
		edit.text = filtered
		edit.caret_column = caret

func parse_input_date(value: String) -> Date:
	var matcher := RegEx.new()
	matcher.compile("^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})$")
	var result := matcher.search(value.strip_edges())
	if result == null:
		return null
	var day := result.get_string(1).to_int()
	var month := result.get_string(2).to_int()
	var year := result.get_string(3).to_int()
	if year < 1 or month < 1 or month > 12 or day < 1:
		return null
	var days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if year % 400 == 0 or (year % 4 == 0 and year % 100 != 0):
		days[1] = 29
	if day > days[month - 1]:
		return null
	return Date.new(day, month, year)

func _setup_date_inputs() -> void:
	for index in range(2):
		var edit: LineEdit = start_date_ledit if index == 0 else end_date_ledit
		var prefix := "Start" if index == 0 else "End"
		edit.editable = true
		edit.focus_mode = Control.FOCUS_ALL
		edit.text_changed.connect(_filter_date_characters.bind(edit))
		edit.placeholder_text = "dd/mm/yyyy"
		edit.tooltip_text = "Enter day/month/year, for example 29/02/2028, or use the calendar."
		edit.text_submitted.connect(func(_text: String): _commit_date_input(index))
		edit.focus_exited.connect(_commit_date_input.bind(index))
		var hint: Label = $Control.get_node(prefix + "DateHint")
		date_hints.append(hint)
	_validate_dates(false)
	_setup_settings_titles()
	_layout_settings_screen()

func _setup_settings_titles() -> void:
	_setup_psamv_option()
	if observation_title != null:
		return
	observation_title = $Control/ObservationTitle
	results_title = $Control/ResultsTitle
	empty_results_overlay = $Control/EmptyResultsOverlay
	empty_results_label = $Control/EmptyResultsOverlay/EmptyResultsLabel

func _setup_psamv_option() -> void:
	if $Control/TableSettings.has_node("cbPsAMV"):
		return
	var checkbox := CheckBox.new()
	checkbox.name = "cbPsAMV"
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.button_pressed = true
	checkbox.tooltip_text = "Show the projected dust-tail direction returned by JPL Horizons."
	checkbox.toggled.connect(_on_cb_psamv_toggled)
	$Control/TableSettings.add_child(checkbox)
	var label := Label.new()
	label.name = "cbPsAMVLabel"
	label.text = "Dust-tail direction (PsAMV)"
	label.tooltip_text = "Position angle of the projected negative heliocentric velocity vector."
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	$Control/TableSettings.add_child(label)

func _layout_settings_screen() -> void:
	if not Hud.automatic_layout:
		return
	if observation_title == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	$Control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var left_x := viewport_size.x * 0.024
	var left_width := viewport_size.x * 0.278
	var top := maxf(66.0, viewport_size.y * 0.064)
	var vertical_scale := clampf((viewport_size.y - 80.0) / 780.0, 0.78, 1.0)
	var gap := 18.0 * vertical_scale
	var search_height := 220.0 * vertical_scale
	var orbital_height := 220.0 * vertical_scale
	var table_height := 280.0 * vertical_scale
	var orbital_top := top + search_height + gap
	var table_top := orbital_top + orbital_height + gap

	Hud._place_control($Control/SearchDataPanel, Rect2(left_x, top, left_width, search_height))
	Hud._place_control($Control/OrbitalElemPanel, Rect2(left_x, orbital_top, left_width, orbital_height))
	Hud._place_control($Control/TableSettingsPanel, Rect2(left_x, table_top, left_width, table_height))
	Hud._place_control(observation_title, Rect2(left_x + 20, top + 10, left_width - 40, 28))

	var label_x := left_x + 22.0
	var label_width := left_width * 0.31
	var field_x := left_x + left_width * 0.42
	var right := left_x + left_width - 18.0
	var row_height := 34.0
	var first_row := top + 48.0
	var row_gap := (search_height - 70.0) / 4.0
	_layout_search_row($Control/CometSearchLabel, $Control/CometNameInfoBtn, first_row, label_x, label_width)
	Hud._place_control($Control/SearchBar, Rect2(field_x, first_row, right - field_x - 48, row_height))
	Hud._place_control($Control/SearchBtn, Rect2(right - 40, first_row, 40, row_height))
	for row in range(2):
		var y := first_row + row_gap * (row + 1)
		var label: Label = $Control/StartDateLabel if row == 0 else $Control/EndDateLabel
		var info: TextureButton = $Control/TimespanInfoBtn if row == 0 else null
		_layout_search_row(label, info, y, label_x, label_width)
		var edit: LineEdit = start_date_ledit if row == 0 else end_date_ledit
		var clear: Button = $Control/ClearStartDateBtn if row == 0 else $Control/ClearEndDateBtn
		var calendar: TextureButton = $Control/StartCalendarBtn if row == 0 else $Control/EndCalendarBtn
		Hud._place_control(edit, Rect2(field_x, y, right - field_x - 84, row_height))
		Hud._place_control(clear, Rect2(right - 76, y, 32, row_height))
		Hud._place_control(calendar, Rect2(right - 36, y + 1, 34, 32))
		if row < date_hints.size():
			Hud._place_control(date_hints[row], Rect2(field_x, y + row_height, right - field_x, 16))
	var step_y := first_row + row_gap * 3.0
	_layout_search_row($Control/StepSizeLabel, $Control/StepsizeInfoBtn, step_y, label_x, label_width)
	Hud._place_control($Control/StepSizeSanEdit, Rect2(right - 68, step_y, 68, row_height))
	$Control/HSeparator.hide()
	$Control/HSeparator2.hide()

	_layout_orbital_card(left_x, left_width, orbital_top, orbital_height)
	_layout_table_settings(left_x, left_width, table_top, table_height)

	var results_x := left_x + left_width + 32.0
	var results_width := viewport_size.x - results_x - 32.0
	var results_height := viewport_size.y - top - 26.0
	Hud._place_control($Control/JPLTablePanel, Rect2(results_x, top, results_width, results_height))
	Hud._place_control(results_title, Rect2(results_x + 22, top + 12, results_width - 44, 30))
	Hud._place_control($Control/EphemScroll, Rect2(results_x + 22, top + 50, results_width - 44, results_height - 116))
	$Control/EphemScroll.scale = Vector2.ONE
	Hud._place_control(empty_results_overlay, Rect2(results_x + 22, top + 50, results_width - 44, results_height - 116))
	empty_results_overlay.visible = ephem_table.get_child_count() == 0
	Hud._place_control($Control/ExportCSVBtn, Rect2(results_x + results_width - 208, top + results_height - 52, 186, 36))
	Hud._place_control($Control/LoadingLabel, Rect2(results_x + results_width * 0.35, top + results_height * 0.45, results_width * 0.3, 42))
	$Control/LoadingLabel.scale = Vector2.ONE

func _layout_search_row(label: Label, info: TextureButton, y: float, x: float, width: float) -> void:
	Hud._place_control(label, Rect2(x, y + 5, width, 26))
	if info != null:
		Hud._place_control(info, Rect2(x + width - 24, y + 5, 22, 22))

func _layout_orbital_card(x: float, width: float, y: float, height: float) -> void:
	Hud._place_control($Control/OrbitalElemLabel, Rect2(x + 20, y + 10, width - 52, 26))
	Hud._place_control($Control/OrbitalInfoBtn, Rect2(x + width - 42, y + 10, 22, 22))
	$Control/OrbitalElemLabel.add_theme_font_size_override("font_size", 17)
	$Control/OrbitalElemLabel.add_theme_color_override("font_color", AETHER_THEME.ACCENT_BRIGHT)
	var labels := [$Control/ECLabel, $Control/QRLabel, $Control/TPLabel, $Control/OMLabel, $Control/WLabel, $Control/INLabel]
	var edits := [$Control/ECLineEdit, $Control/QRLineEdit, $Control/TPLineEdit, $Control/OMLineEdit, $Control/WLineEdit, $Control/INLineEdit]
	var column_width := (width - 62.0) / 2.0
	var row_step := (height - 44.0) / 3.0
	for index in range(6):
		var column := index % 2
		var row := index / 2
		var column_x := x + 20.0 + column * (column_width + 22.0)
		var row_y := y + 40.0 + row * row_step
		Hud._place_control(labels[index], Rect2(column_x, row_y, column_width, 20))
		labels[index].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		Hud._place_control(edits[index], Rect2(column_x, row_y + 20, column_width, 32))

func _layout_table_settings(x: float, width: float, y: float, height: float) -> void:
	Hud._place_control($Control/TableSettingsLabel, Rect2(x + 20, y + 10, width - 52, 26))
	Hud._place_control($Control/TableSettingsInfoBtn, Rect2(x + width - 42, y + 10, 22, 22))
	$Control/TableSettingsLabel.add_theme_font_size_override("font_size", 17)
	$Control/TableSettingsLabel.add_theme_color_override("font_color", AETHER_THEME.ACCENT_BRIGHT)
	Hud._place_control($Control/TableSettings, Rect2(x + 20, y + 42, width - 40, height - 52))
	var checkbox_names := ["cbRaDec", "cbDelta", "cbSngAng", "cbHeliocentric", "cbSTO", "cbPlAng", "cbTrueAnomaly", "cbPsAMV", "cbSkyMotion"]
	var label_names := ["cbRaDecLabel", "cbDeltaLabel", "cbSnAngLabel", "cbHeliocentricLabel", "cbSTOLabel", "cbPlAngLabel", "cbTrueAnomalyLabel", "cbPsAMVLabel", "cbSkyMotionLabel"]
	var row_height: float = ($Control/TableSettings.size.y - 4.0) / checkbox_names.size()
	for index in range(checkbox_names.size()):
		var checkbox: CheckBox = $Control/TableSettings.get_node(checkbox_names[index])
		var label: Label = $Control/TableSettings.get_node(label_names[index])
		checkbox.scale = Vector2.ONE
		label.scale = Vector2.ONE
		Hud._place_control(checkbox, Rect2(0, index * row_height, 24, 24))
		Hud._place_control(label, Rect2(32, index * row_height + 1, $Control/TableSettings.size.x - 32, 24))

func _commit_date_input(index: int) -> void:
	var edit: LineEdit = start_date_ledit if index == 0 else end_date_ledit
	var parsed := parse_input_date(edit.text)
	if parsed != null:
		edit.text = "%02d/%02d/%04d" % [parsed.day(), parsed.month(), parsed.year()]
		var picker = $Control.get_node("StartCalendarBtn" if index == 0 else "EndCalendarBtn")
		picker.selected_date = Date.new(parsed.day(), parsed.month(), parsed.year())
		picker.refresh_data()
	_validate_dates(false)

func _validate_dates(require_start: bool = true) -> bool:
	start_date = parse_input_date(start_date_ledit.text)
	end_date = parse_input_date(end_date_ledit.text)
	var errors: Array[String] = ["", ""]
	if start_date == null and (require_start or not start_date_ledit.text.strip_edges().is_empty()):
		errors[0] = "Enter a valid date: dd/mm/yyyy"
	if end_date == null and not end_date_ledit.text.strip_edges().is_empty():
		errors[1] = "Enter a valid date: dd/mm/yyyy"
	if start_date != null and end_date != null:
		var start_key := start_date.year() * 10000 + start_date.month() * 100 + start_date.day()
		var end_key := end_date.year() * 10000 + end_date.month() * 100 + end_date.day()
		if end_key < start_key:
			errors[1] = "End date must not precede start date"
	for index in range(date_hints.size()):
		var edit: LineEdit = start_date_ledit if index == 0 else end_date_ledit
		date_hints[index].text = errors[index]
		date_hints[index].add_theme_color_override("font_color", Color("e9827a"))
		if errors[index].is_empty():
			edit.remove_theme_stylebox_override("normal")
		else:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("0b202d")
			style.border_color = Color("e9827a")
			style.set_border_width_all(2)
			style.set_corner_radius_all(4)
			edit.add_theme_stylebox_override("normal", style)
	return errors[0].is_empty() and errors[1].is_empty()
var alpha_p: float = 0.0
var delta_p: float = 0.0
# var target = "C/2013 R1"
var api_url := "https://ssd.jpl.nasa.gov/api/horizons.api"
var api_url_designation := "https://ssd.jpl.nasa.gov/api/horizons_support.api"

# url encode semicolon
const SC := "%3B"

# var quantities := "1,19,20,23"
var quantities := "1,16,19,20,24,27,28,41,47"

# options
var options := {
	"RA_DEC": true,
	"Delta": true,
	"SngAng": true,
	"Heliocentric": true,
	"STO": true,
	"PlAngle": true,
	"TrueAnomaly": true,
	"PsAMV": true,
	"SkyMotion": true
}

# Regex Related
var regex_params: Array[String] = [
		"(\\d{4}-\\w{3}-\\d{2})", # Matches the date, e.g., 1998-Jan-01
		"(\\d{2}:\\d{2}(?::\\d{2}(?:\\.\\d{3})?)?)", # Matches the time, e.g., 10:00 or 10:00:00.000
		"([+-]?\\d+\\.\\d+)", # Matches right ascension, e.g., 314.921234
		"([+-]?\\d+\\.\\d+)", # Matches declination, e.g., -18.556789

		# "([+-]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d{2})", # Matches right ascension, e.g., 20 55 41.20
		# "([-+]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d)", # Matches declination, e.g., -18 33 23.0
		"([+-]?\\d+\\.\\d+)", # Sun PA (single float value)
		"([+-]?\\d+\\.\\d+)", # SN.dist (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Sun Distance R (single float value)
		"([+-]?\\d+\\.\\d+)", # r.dot (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Delta (single float value)
		"([+-]?\\d+\\.\\d+)", # deldot (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # STO (single float value)
		"([+-]?\\d+\\.\\d+)", # PsAng: projected extended Sun-to-target radius PA
		"([+-]?\\d+\\.\\d+)", # PsAMV: projected negative heliocentric velocity PA
		"([+-]?\\d+\\.\\d+)", # PlAngle (single float value)
		"([+-]?\\d+\\.\\d+)", # True anomaly (single float value)
		"([+-]?\\d+\\.\\d+)", # Sky motion (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Sky motion PA (single float value)
	]

var number_params := regex_params.size()
var full_pattern := "\\s+".join(PackedStringArray(regex_params))
var jpl_regex := RegEx.new()
var compiled := jpl_regex.compile(full_pattern)

var om_w_in_regex: RegEx = RegEx.new()
# Pattern to match " OM= 124.567, W= 123.456, IN= 78.910"
var om_w_in_compiled := om_w_in_regex.compile("\\s*OM=\\s*([-+]?\\d*\\.\\d+)\\s*W=\\s*([-+]?\\d*\\.\\d+)\\s*IN=\\s*([-+]?\\d*\\.\\d+)")

var ec_qr_tp_regex: RegEx = RegEx.new()
var ec_qr_tp_compiled := ec_qr_tp_regex.compile("\\s*EC=\\s*([-+]?\\d*\\.\\d+)\\s*QR=\\s*([-+]?\\d*\\.\\d+)\\s*TP=\\s*([-+]?\\d*\\.\\d+)")

func _ready() -> void:
	call_deferred("_setup_date_inputs")
	get_viewport().size_changed.connect(func(): call_deferred("_layout_settings_screen"))
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	http_request_name = HTTPRequest.new()
	add_child(http_request_name)
	http_request_name.request_completed.connect(self._http_request_name_completed)
	
## 1.Send search request to get designation ID
func _on_search_btn_pressed() -> void:
	if not _validate_dates():
		return
	var query := search_bar.text
	if query == "":
		Util.create_popup("Error", "Please enter a valid target name or designation.")
		return
	if start_date == null:
		Util.create_popup("Error", "Please select a valid start date.")
		return
	if step_size <= 0:
		Util.create_popup("Error", "Please select a valid step size (greater than 0).")
		return

	print("Fetching designation ID for:", query)
	get_designation_id(query)
	

## 2.API Call to retrieve designation ID from name
func get_designation_id(comet_name: String) -> void:
	_show_loading_label(true)
	var url_request := "%s?sstr=%s&time-span=1&www=1" % [api_url_designation, comet_name.uri_encode()]
	print("Designation ID Request URL: ", url_request)
	# encode url
	
	var tls_options := TLSOptions.client_unsafe()
	http_request_name.set_tls_options(tls_options)
	var error := http_request_name.request(url_request)
	var error_msg: String = ""
	match error:
		OK:
			error_msg = "HTTP request sent successfully."
		ERR_UNCONFIGURED:
			_show_loading_label(false)
			error_msg = "HTTPRequest node is not configured."
		ERR_BUSY:
			_show_loading_label(false)
			error_msg = "HTTPRequest node is busy with another request."
		ERR_INVALID_PARAMETER:
			_show_loading_label(false)
			error_msg = "Invalid parameter provided to HTTPRequest."
		ERR_CANT_CONNECT:
			_show_loading_label(false)
			error_msg = "Cannot connect to the server."
		_:
			_show_loading_label(false)
			error_msg = "Default error message."
	print("HTTP Request Status: ", error_msg)

## 3.Handle designation ID response
func _http_request_name_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_show_loading_label(false)
	var json_parser := JSON.new()
	var body_string := body.get_string_from_utf8()
	json_parser.parse(body_string)
	# print(json_parser.data)
	if _response_code != 200 and _response_code != 300:
		print("Error, response code: ", _response_code)
		Util.create_popup("Error", "Errore in chiamata.\n")
		return
	if json_parser.data.has("error"):
		Util.create_popup("Error", "Failed to retrieve designation ID:\n%s" % json_parser.data.error)
		return
	if json_parser.data.count == 0:
		Util.create_popup("Error", "No designation ID found for the given name.")
		return
	# if count is 1, then there's no need to retrieve the designatn id
	if json_parser.data.count == 1:
		var des_id: String = json_parser.data.data.id
		print("Designation ID found:", des_id)
		var command_parameter := "DES=" + str(des_id) + SC + "NOFRAG" + SC
		print("Command Parameter: ", command_parameter)
		request_ephemeris(command_parameter)
		return
	# else, show a popup to select the designation id
	var raw_list: Array = json_parser.data.list
	# print(raw_list)
	var designation_options: Array[Dictionary] = []
	# convert raw_list to array of dictionaries through json
	for raw_item: Dictionary in raw_list:
		designation_options.append(raw_item)
	des_options_popup.clear()
	des_options_popup.add_item("Select an orbit", 0)
	des_options_popup.set_item_disabled(0, true)
	des_options_popup.add_separator()
	for i in range(designation_options.size()):
		var option := designation_options[i]
		var display_text := "%s " % [option.name]
		des_options_popup.add_item(display_text, i)
		des_options_popup.set_item_metadata(i, {"id": option.id, "orbit_id": option.orbit_id})
	des_options_popup.popup_centered()
	des_options_popup.popup()


## 3B.Handle designation selection from popup
func _on_design_options_popup_menu_id_pressed(id: int) -> void:
	print("AAAAAAAA")
	var selected_option: Dictionary = des_options_popup.get_item_metadata(id)
	print("Selected designation ID: ", selected_option)
	var command_parameter := "DES=" + str(selected_option["id"]) + SC + "NOFRAG" + SC + "SOLN=" + str(selected_option["orbit_id"]) + SC
	print("Command Parameter: ", command_parameter)
	request_ephemeris(command_parameter)
	# You can now use the selected_option (which contains the ID) for further processing.

## 4.Send ephemeris request. Command must be in the form of DES=designation_id;NOFRAG;SOLN=orbit_id; or DES=designation_id;
func request_ephemeris(command_parameter: String) -> void:
	_show_loading_label(true)
	var params := {
			"format": "json",
			"COMMAND": "'%s'" % [command_parameter],
			"OBJ_DATA": "NO",
			"MAKE_EPHEM": "YES",
			"EPHEM_TYPE": "OBSERVER",
			"CENTER": "'500@399'", # Geocentric (Observatory at the center of Earth)
			
			"STEP_SIZE": "'%sh'" % int(step_size),
			"ANG_FORMAT": "DEG",
			"QUANTITIES": "'%s'" % quantities
		}
	if end_date == null or end_date.date("YYYY-MM-DD") == start_date.date("YYYY-MM-DD"):
		params["TLIST"] = "'%s 00:00'" % start_date.date("YYYY-MM-DD")
	else:
		params["START_TIME"] = "'%s 00:00'" % start_date.date("YYYY-MM-DD")
		params["STOP_TIME"] = "'%s 00:00'" % end_date.date("YYYY-MM-DD")
		# Construct the query string from the parameters
	var query_string := ""
	for key: String in params.keys():
		if query_string != "":
			query_string += "&"
		query_string += "%s=%s" % [key, params[key]]
	var url := "{api_url}?{query_string}".format({"api_url": api_url, "query_string": query_string})
	# make a post instead of get
	#

	# print("API URL:")
	print("Request URL: ", url)
	var tls_options := TLSOptions.client_unsafe()
	http_request.set_tls_options(tls_options)
	var error := http_request.request(url)
	var error_msg: String = ""
	match error:
		OK:
			error_msg = "HTTP request sent successfully."
		ERR_UNCONFIGURED:
			_show_loading_label(false)
			error_msg = "HTTPRequest node is not configured."
		ERR_BUSY:
			_show_loading_label(false)
			error_msg = "HTTPRequest node is busy with another request."
		ERR_INVALID_PARAMETER:
			_show_loading_label(false)
			error_msg = "Invalid parameter provided to HTTPRequest."
		ERR_CANT_CONNECT:
			_show_loading_label(false)
			error_msg = "Cannot connect to the server."
		_:
			_show_loading_label(false)
			error_msg = "Default error message."
	print("HTTP Request Status: ", error_msg)
	# Util.create_popup("Request Status", error_msg)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	print("----------")

## 5.Handle ephemeris response
func _http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_show_loading_label(false)
	var json_parser := JSON.new()
	var body_string := body.get_string_from_utf8()
	json_parser.parse(body_string)
	# print("JSON\n")
	# print(body_string)
	# Util.create_popup("Data Loaded", body_string)
	if _response_code != 200 or json_parser.data.has("error"):
		push_error("Error: %s" % json_parser.data.error)
		Util.create_popup("Error", "Failed to retrieve ephemeris data:\n%s" % json_parser.data.error)
		return

	var data: Variant = json_parser.data
	var eph_tmp := parse_ephemeris(data.result)
	if eph_tmp == "":
		push_error("Failed to parse ephemeris data.")
		Util.create_popup("Error", "Failed to parse ephemeris data. One or more fields may be wrong.")
		return
	json_parser.parse(eph_tmp)
	print("Json:\n")
	print(json_parser.data)
	var ephemeris_data: Variant = json_parser.data

	$Control/ECLineEdit.text = str(ephemeris_data.ec)
	$Control/QRLineEdit.text = str(ephemeris_data.qr)
	$Control/TPLineEdit.text = str(ephemeris_data.tp)
	$Control/OMLineEdit.text = str(ephemeris_data.om)
	$Control/WLineEdit.text = str(ephemeris_data.w)
	$Control/INLineEdit.text = str(ephemeris_data.inc)
	clear_container()
	populate_container(ephemeris_data.data)


func parse_ephemeris(data: String) -> String:
	var data_start_marker := "$$SOE"
	var data_end_marker := "$$EOE"
	var start_index := data.find(data_start_marker)
	var end_index := data.find(data_end_marker)

	if start_index == -1:
		push_error("Data start marker not found.")
		return ""
	if end_index == -1:
		push_error("Data end marker not found.")
		return ""

	var ec_index := data.find(" EC=")
	if ec_index == -1:
		push_error("EC line not found.")
		return ""
	var ec_end_index := data.find("\n", ec_index)
	var ec_line := data.substr(ec_index, ec_end_index - ec_index).strip_edges()
	var ec_result := ec_qr_tp_regex.search(ec_line)
	if ec_result == null:
		push_error("No matches found in the EC/QR/TP line: %s" % ec_line)
		return ""
	var ec := ec_result.get_string(1)
	var qr := ec_result.get_string(2)
	var tp := ec_result.get_string(3)

	# from the body, extract the line containing OM=.. , W=.. , IN=...
	# and extract the object name from it
	var om_index := data.find(" OM=")
	if om_index == -1:
		push_error("OM/W/IN line not found.")
		return ""

	var om_end_index := data.find("\n", om_index)
	var om_line := data.substr(om_index, om_end_index - om_index).strip_edges()
	var om_result := om_w_in_regex.search(om_line)
	if om_result == null:
		push_error("No matches found in the OM/W/IN line: %s" % om_line)
		return ""
	var om := om_result.get_string(1)
	var w := om_result.get_string(2)
	var inc := om_result.get_string(3)
	# print("OM: %s, W: %s, IN: %s" % [om, w, inc])
	# set the object name in the search bar
	# extracting only the ephemeris body (which is enclosed between the start and end markers)
	var eph_body := data.substr((start_index + data_start_marker.length()), (end_index - start_index - data_start_marker.length()))
	eph_body = eph_body.replace("/L", "")
	var _eph_lines := eph_body.split("\n")

	# from packedstringarray to array[string]
	var eph_lines: Array[String] = []
	for line in _eph_lines:
		if line.strip_edges() != "":
			eph_lines.append(line.strip_edges())


	Util.ec = float(ec)
	Util.qr = float(qr)
	Util.tp = float(tp)
	Util.om = float(om)
	Util.w = float(w)
	Util.incl = float(inc)

	# extracting each column, line by line, using regex
	var json_text := "{\"ec\": %s, \"qr\": %s, \"tp\": %s, \"om\": %s, \"w\": %s, \"inc\": %s, \"data\": [" % [Util.ec, Util.qr, Util.tp, Util.om, Util.w, Util.incl]
	for index in range(len(eph_lines)):
		var line := eph_lines[index]
		# print(line)
		var result := jpl_regex.search(line)
		if result == null:
			push_error("No matches found in the ephemeris data line: %s" % line)
			continue
		var entry := {}
		# for i in range(1, result.get_group_count() + 1):
		entry = {
			"date": result.get_string(1),
			"time": result.get_string(2),
		"right_ascension": result.get_string(3),
		"declination": result.get_string(4),
		"sun_pa": result.get_string(5),
		"sun_pa_dist": result.get_string(6),
		"sun_distance_r": result.get_string(7),
		"sun_r_dot": result.get_string(8),
		"delta": result.get_string(9),
		"delta_dot": result.get_string(10),
		"sto": result.get_string(11),
		"psang": result.get_string(12),
		"psamv": result.get_string(13),
		"pl_ang": result.get_string(14),
		"true_anomaly": result.get_string(15),
		"sky_motion": result.get_string(16),
		"sky_motion_pa": result.get_string(17)
		}
		# print(entry)

		json_text += JSON.stringify(entry)
		if index < len(eph_lines) - 1:
			json_text += ","
	json_text += "]}"
	return json_text

# Clear the container before populating it with new data.
func clear_container() -> void:
	for child in ephem_table.get_children():
		ephem_table.remove_child(child)
		child.queue_free()
	# adjust scroll to top
	scroll_container.custom_minimum_size.y = 0
	scroll_container.scroll_vertical = 0
	_set_empty_results_visible(true)
# Populate the container with tabular data from the ephemeris, retrieved from Nasa JPL API.
func populate_container(data: Variant) -> void:
	_set_empty_results_visible(false)
	var HEADER := {
		"date": "Date",
		"time": "Time",
		"right_ascension": "Right Ascension (Deg)",
		"declination": "Declination (Deg)",
		"delta": "Delta (AU)",
		# "delta_dot": "Delta Dot",
		"sun_pa": "Sun PA (Deg)",
		# "sun_pa_dist": "Sun PA Dist",
		"sun_distance_r": "Sun Distance R (AU)",
		# "sun_r_dot": "Sun Distance R Dot",
		"sto": "STO (Deg)",
		"psamv": "PsAMV (Deg)",
		"pl_ang": "Sky Plane Angle (Deg)",
		"true_anomaly": "True Anomaly (Deg)",
		# "sky_motion": "Sky Motion",
		"sky_motion_pa": "Sky Motion PA (Deg)"
	}
	if options["RA_DEC"] == false:
		HEADER.erase("right_ascension")
		HEADER.erase("declination")
	if options["Delta"] == false:
		HEADER.erase("delta")
		# HEADER.erase("delta_dot")
	if options["SngAng"] == false:
		HEADER.erase("sun_pa")
		# HEADER.erase("sun_pa_dist")
	if options["Heliocentric"] == false:
		HEADER.erase("sun_distance_r")
		# HEADER.erase("sun_r_dot")
	if options["STO"] == false:
		HEADER.erase("sto")
	if options["PsAMV"] == false:
		HEADER.erase("psamv")
	if options["PlAngle"] == false:
		HEADER.erase("pl_ang")
	if options["TrueAnomaly"] == false:
		HEADER.erase("true_anomaly")
	if options["SkyMotion"] == false:
		# HEADER.erase("sky_motion")
		HEADER.erase("sky_motion_pa")
	Util.jpl_data = data
	Util.psang = float(data[0].get("psang", data[0].get("sun_pa", 0.0)))
	Util.psamv = float(data[0].get("psamv", data[0].get("sky_motion_pa", 0.0)))
	Util.sky_motion_pa = float(data[0].get("sky_motion_pa", Util.psamv))
	
	var date_str: String = str(data[0]["date"])
	var time_str: String = str(data[0]["time"])
	# only the first 2 digits
	time_str = time_str.substr(0, 2)
	get_tree().call_group("switch_date", "switch_date_set_date", date_str + " " + time_str + ":00", true)
	# print(data)
	var column_width := maxf(150.0, (scroll_container.size.x - 20.0) / HEADER.size())
	var header_panel := PanelContainer.new()
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = AETHER_THEME.INPUT
	header_style.border_color = AETHER_THEME.BORDER
	header_style.set_border_width_all(1)
	header_style.set_corner_radius_all(4)
	header_panel.add_theme_stylebox_override("panel", header_style)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 0)
	for key: String in HEADER.keys():
		header_row.add_child(_make_ephemeris_cell(str(HEADER[key]), column_width, true))
	header_panel.add_child(header_row)
	ephem_table.add_child(header_panel)
	for row_index in range(data.size()):
		var entry: Dictionary = data[row_index]
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(AETHER_THEME.PANEL if row_index % 2 == 0 else AETHER_THEME.INPUT, 0.72)
		row_panel.add_theme_stylebox_override("panel", row_style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		for key: String in HEADER.keys():
			row.add_child(_make_ephemeris_cell(str(entry[key]), column_width, false))
		row_panel.add_child(row)
		ephem_table.add_child(row_panel)
	# scroll_container.scroll_vertical = scroll_container.get_v_scrollbar().max_value

func _set_empty_results_visible(show_empty: bool) -> void:
	if empty_results_overlay != null:
		empty_results_overlay.visible = show_empty

func _make_ephemeris_cell(value: String, width: float, is_header: bool) -> Label:
	var cell := Label.new()
	cell.text = value
	cell.tooltip_text = value
	cell.custom_minimum_size = Vector2(width, 42 if is_header else 32)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_theme_font_size_override("font_size", 13 if is_header else 14)
	cell.add_theme_color_override("font_color", AETHER_THEME.ACCENT_BRIGHT if is_header else AETHER_THEME.TEXT)
	return cell


func _on_start_calendar_btn_date_selected(date_obj: Date) -> void:
	start_date_ledit.text = "%02d/%02d/%04d" % [date_obj.day(), date_obj.month(), date_obj.year()]
	_commit_date_input(0)


func _on_end_calendar_btn_date_selected(date_obj: Date) -> void:
	end_date_ledit.text = "%02d/%02d/%04d" % [date_obj.day(), date_obj.month(), date_obj.year()]
	_commit_date_input(1)


func update_step_size(value: float) -> void:
	step_size = value
	# print("Step size updated to: ", step_size)


func _on_clear_start_date_btn_pressed() -> void:
	start_date = null
	start_date_ledit.text = ""
	_validate_dates(false)
func _on_clear_end_date_btn_pressed() -> void:
	end_date = null
	end_date_ledit.text = ""
	_validate_dates(false)


func _on_cb_ra_dec_toggled(toggled_on: bool) -> void:
	options["RA_DEC"] = toggled_on


func _on_cb_delta_toggled(toggled_on: bool) -> void:
	options["Delta"] = toggled_on


func _on_cb_sng_ang_toggled(toggled_on: bool) -> void:
	options["SngAng"] = toggled_on


func _on_cb_heliocentric_toggled(toggled_on: bool) -> void:
	options["Heliocentric"] = toggled_on


func _on_cb_sto_toggled(toggled_on: bool) -> void:
	options["STO"] = toggled_on


func _on_cb_pl_ang_toggled(toggled_on: bool) -> void:
	options["PlAngle"] = toggled_on


func _on_cb_true_anomaly_toggled(toggled_on: bool) -> void:
	options["TrueAnomaly"] = toggled_on


func _on_cb_psamv_toggled(toggled_on: bool) -> void:
	options["PsAMV"] = toggled_on


func _on_cb_sky_motion_toggled(toggled_on: bool) -> void:
	options["SkyMotion"] = toggled_on


func _on_export_csv_btn_pressed() -> void:
	$Control/FileExplorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$Control/FileExplorer.filters = ["*.csv;CSV File"]
	SaveManager.prepare_file_dialog($Control/FileExplorer, "jpl_ephemeris.csv")
	$Control/FileExplorer.popup_centered()
	$Control/FileExplorer.visible = true
	

func _on_file_explorer_file_selected(path: String) -> void:
	SaveManager.remember_file_directory(path)
	# convert json data to csv
	if Util.jpl_data == null or Util.jpl_data.size() == 0:
		Util.create_popup("Error", "No ephemeris data to export.")
		return
	# print("Exporting CSV")
	var csv_text := ""
	var HEADER := {"date": "Date",
		"time": "Time", }
	if options["RA_DEC"] == true:
		HEADER["right_ascension"] = "Right Ascension (Deg)"
		HEADER["declination"] = "Declination (Deg)"
	if options["Delta"] == true:
		HEADER["delta"] = "Delta (AU)"
		# HEADER["delta_dot"] = "Delta Dot"
	if options["SngAng"] == true:
		HEADER["sun_pa"] = "Sun PA (Deg)"
		# HEADER["sun_pa_dist"] = "Sun PA Dist"
	if options["Heliocentric"] == true:
		HEADER["sun_distance_r"] = "Sun Distance R (AU)"
		# HEADER["sun_r_dot"] = "Sun Distance R Dot"
	if options["STO"] == true:
		HEADER["sto"] = "STO (Deg)"
	if options["PsAMV"] == true:
		HEADER["psamv"] = "PsAMV (Deg)"
	if options["PlAngle"] == true:
		HEADER["pl_ang"] = "Sky Plane Angle (Deg)"
	if options["TrueAnomaly"] == true:
		HEADER["true_anomaly"] = "True Anomaly (Deg)"
	if options["SkyMotion"] == true:
		# HEADER["sky_motion"] = "Sky Motion"
		HEADER["sky_motion_pa"] = "Sky Motion PA (Deg)"

	for key: String in HEADER.keys():
		csv_text += "%s," % HEADER[key]
	csv_text = csv_text.trim_suffix(",") + "\n"
	for line: Dictionary in Util.jpl_data:
		var line_string := ""
		for key: String in HEADER.keys():
			line_string += "%s," % str(line[key])
		csv_text += line_string.trim_suffix(",") + "\n"
	# save csv_text to file
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		Util.create_popup("Error", "Failed to open file for writing.")
		return
	file.store_string(csv_text)
	file.close()

	Util.create_popup("Export Successful", "Ephemeris data exported to %s" % path)


func _show_loading_label(bool_value: bool) -> void:
	loading_label.visible = bool_value
