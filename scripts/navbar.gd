extends CanvasLayer

# @onready var rot_camera_viewport: SubViewport = $"/root/Hud/Body/SubViewportContainer/SubViewport"
@onready var sub_viewport_container: SubViewportContainer = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/SubViewportContainer"
@onready var rot_camera_viewport: SubViewport = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/SubViewportContainer/SubViewport"
@onready var minicamera_viewport: SubViewport = $"/root/Hud/Viewport/MiniViewportContainer/SubViewport"
@onready var aspect_ratio_container: AspectRatioContainer = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer"
@onready var mini_viewport_container: SubViewportContainer = $"/root/Hud/Viewport/MiniViewportContainer"
@onready var cam: Camera3D = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/SubViewportContainer/SubViewport/RotatingCamera"
@onready var file_explorer: FileDialog = $TabButtons/ColorRect/HBoxContainer/SaveImg
@onready var coordinate_grid: Control = $"/root/Hud/Viewport/Panel/CoordinateGrid"

# @onready var plane: MeshInstance3D = $"/root/World/Plane"
@onready var comet: MeshInstance3D = $"/root/World/CometMesh"
# @onready var comet2: MeshInstance3D = $"/root/World/CometMesh2"

const MIN_VP_SIDE := 256
var alpha_check: CheckBox

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_save_load_buttons()
	aspect_ratio_container.resized.connect(_sync_center)
	await get_tree().process_frame

	# ✅ Disabilita stretch prima
	sub_viewport_container.stretch = false
	mini_viewport_container.stretch = false

	# ✅ Ora puoi settare size
	#rot_camera_viewport.size = Vector2i(900, 900)
	#minicamera_viewport.size = Vector2i(900, 900)

	# ✅ Riabilita stretch dopo
	sub_viewport_container.stretch = true
	mini_viewport_container.stretch = true

#	_sync_center()
	alpha_check = CheckBox.new()
	alpha_check.text = "Save with transparent background (alpha)"
	alpha_check.button_pressed = true  # default consigliato

	# 👇 QUESTA È LA RIGA CHIAVE
	file_explorer.get_vbox().add_child(alpha_check)

	if not file_explorer.file_selected.is_connected(_on_file_explorer_file_selected):
		file_explorer.file_selected.connect(_on_file_explorer_file_selected)


func _sync_center() -> void:
	sub_viewport_container.size = Vector2i(aspect_ratio_container.size)

	var side := int(min(sub_viewport_container.size.x, sub_viewport_container.size.y))
	side = max(side, MIN_VP_SIDE)
	#rot_camera_viewport.size = Vector2i(side, side)
	#minicamera_viewport.size = Vector2i(side, side)

	Util.window_size = float(side)

	get_tree().call_group("scale", "update_window_size", Util.window_size)
	get_tree().call_group("scale", "update_scale_factor")
	get_tree().call_group("camera", "update_ruler")
	get_tree().call_group("comet", "update_coordinate_grid_labels")

		
#TODO: Simplify this!
## Toggle CometTab and hides all other tabs
func _on_cometbtn_pressed() -> void:
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	if $JPLTab.visible:
		$JPLTab.visible = false
	$CometTab.visible = not $CometTab.visible

## Toggle JetsTab and hides all other tabs
func _on_jetsbtn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	if $JPLTab.visible:
		$JPLTab.visible = false
	$JetsTab.visible = not $JetsTab.visible

## Toggle SimTab and hides all other tabs
func _on_sim_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	if $JPLTab.visible:
		$JPLTab.visible = false

	$SimTab.visible = not $SimTab.visible

## Toggle HelpTab and hides all other tabs
func _on_help_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	if $JPLTab.visible:
		$JPLTab.visible = false
	$HelpPanel.visible = not $HelpPanel.visible
	
func _on_scale_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $JPLTab.visible:
		$JPLTab.visible = false
	$ScaleTab.visible = not $ScaleTab.visible

func _on_jpl_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$JPLTab.visible = not $JPLTab.visible
	return

		
# Maybe make a scene button that automatically on pressed trigger this function?
func _on_trigger_rot_btn_pressed() -> void:
	get_tree().call_group("trigger_rotation", "trigger_rotation")
func _on_reset_rotn_btn_pressed() -> void:
	get_tree().call_group("reset_rotation", "reset_rotation")

## Toggle X and Z Axes
func _on_toggle_axes_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.VELOCITY)
	#get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.X)
	#get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.Z)
## Toggle Y Axis
func _on_toggle_y_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.Y)
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.REVERSE_Y)

## Toggle Sun Axis
func _on_toggle_sun_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.SUN)

## Spawns an emitter at a given latitude and longitude. No Longer Used
func _on_spawn_emitter_pressed() -> void:
	var lat: float = float($"JetsTab/Control/Latitude".text)
	var long: float = float($"JetsTab/Control/Longitude".text)
	
	get_tree().call_group("latitude", "spawn_emitter_at", lat, long)

## Opens the OS Native file explorer to save the current configuration in a file
func _on_save_btn_pressed() -> void:
	print(OS.get_data_dir())
	if not Util.has_jpl_data():
		Util.create_popup(
			"JPL data not loaded",
			"Please load JPL data before saving the configuration."
		)
		return
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.txt;Configuration File"]
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.set_meta("is_screenshot_mini", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "config"
	
	file_explorer.visible = true
## Opens the OS Native file explorer to load a configuration from a chosen file
func _on_load_btn_pressed() -> void:
	if not Util.has_jpl_data():
		Util.create_popup(
			"JPL data not loaded",
			"Please load JPL data before loading the configuration."
		)
		return
	file_explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_explorer.filters = ["*.txt;Configuration File"]
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.set_meta("is_screenshot_mini", false)
	file_explorer.popup_centered()
	
	file_explorer.visible = true

func disable_btn(btn_name: String) -> void:
	var btn := $TabButtons/ColorRect/HBoxContainer.get_node(btn_name)
	if btn:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		print("Button not found: ", name)
func enable_btn(btn_name: String) -> void:
	var btn := $TabButtons/ColorRect/HBoxContainer.get_node(btn_name)
	if btn:
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 1)
	else:
		print("Button not found: ", name)

func _on_screenshot_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.png;Image File"]
	file_explorer.set_meta("is_screenshot", true)
	file_explorer.set_meta("is_screenshot_mini", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "screenshot"
	
	file_explorer.visible = true

func _on_save_nucleus_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.png;Image File"]
	file_explorer.set_meta("is_screenshot_mini", true)
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "screenshot"
	
	file_explorer.visible = true


## Called when a file, either through the save or load methods, is selected.
## Saves/Loads a configuration
func _on_file_explorer_file_selected(path: String) -> void:
	if file_explorer.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		#if file_explorer.get_meta("is_screenshot", false):
		#	var want_alpha := alpha_check != null and alpha_check.button_pressed
		#	var img := await screenshot_subviewport(rot_camera_viewport, want_alpha)
		#	img.resize(1200, 1200)
		#	img.save_png(path)
		#	print("Screenshot saved to: ", path, " alpha=", want_alpha)
		if file_explorer.get_meta("is_screenshot", false):
			var want_alpha := alpha_check != null and alpha_check.button_pressed

			var img := await screenshot_composited_with_overlays(rot_camera_viewport, want_alpha)

			img.resize(1200, 1200)
			img.convert(Image.FORMAT_RGBA8)
			img.save_png(path)
			print("Screenshot saved to: ", path, " alpha=", want_alpha, " overlays=true")
		elif file_explorer.get_meta("is_screenshot_mini", false):
			# var minicamera_img := minicamera_viewport.get_texture().get_image()
			var nucleus_model_panel := $"/root/Hud/Viewport/NucleusPanelRect"
			var minicamera_img := await screenshot_panel(nucleus_model_panel)
			minicamera_img.save_png(path)
			print("Minicamera screenshot saved to: ", path)
		else:
			get_tree().call_group("save", "save_data")
			SaveManager.save(path)
	if file_explorer.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		SaveManager.load(path)
		get_tree().call_group("load", "load_data")
		await get_tree().process_frame

		var loaded_radius := float(SaveManager.config.get_value("comet", "radius", Util.comet_radius))
		get_tree().call_group("comet", "update_radius", loaded_radius)

func screenshot_subviewport(vp: SubViewport, want_alpha: bool) -> Image:
	var old := vp.transparent_bg

	# Se vogliamo alpha, cattura realmente trasparente.
	# Se NON vogliamo alpha, cattura direttamente opaco.
	vp.transparent_bg = want_alpha

	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := vp.get_texture().get_image()

	# Ripristina il valore originale
	vp.transparent_bg = old

	return img

func flatten_on_black(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()

	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 1)) # nero opaco

	# blend_rect rispetta l'alpha di img
	out.blend_rect(img, Rect2i(0, 0, w, h), Vector2i(0, 0))
	return out


## Takes a screenshot of the whole frame and then crops it only to the given panel rect
func screenshot_panel(panel: Control) -> Image:
	await RenderingServer.frame_post_draw

	var vp := get_viewport()
	var img := vp.get_texture().get_image()

	var vis := vp.get_visible_rect().size
	if vis.x <= 0.0 or vis.y <= 0.0:
		return img # fallback sicuro

	var sx := float(img.get_width()) / float(vis.x)
	var sy := float(img.get_height()) / float(vis.y)

	if not is_finite(sx) or not is_finite(sy):
		return img

	var r := panel.get_global_rect()
	r.position *= Vector2(sx, sy)
	r.size *= Vector2(sx, sy)

	var ri := Rect2i(r.position, r.size)

	# clamp dentro img
	ri.position.x = clamp(ri.position.x, 0, img.get_width() - 1)
	ri.position.y = clamp(ri.position.y, 0, img.get_height() - 1)
	ri.size.x = clamp(ri.size.x, 1, img.get_width() - ri.position.x)
	ri.size.y = clamp(ri.size.y, 1, img.get_height() - ri.position.y)

	return img.get_region(ri)



## Now is used as a button for debugging purposes
func _on_full_viewport_btn_pressed() -> void:
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = not node.visible
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = not node.visible
	# get_visible_area_at_distance(42)
	## Prova plane
	#region plane
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	# plane.transform.basis = comet.transform.basis * Basis(Vector3(1, 0, 0), deg_to_rad(-90))
	# plane.rotate(plane.transform.basis.z, deg_to_rad(90 - Util.i))
	# plane.rotate(plane.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_position.y = 0
	# plane.rotate(Vector3.FORWARD, deg_to_rad(90 - Util.i))
	# plane.rotate(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	#endregion plane
	## Prova comet vincent
	#region comet vincent
	# comet.rotate(Vector3.FORWARD, deg_to_rad(90 - Util.i))
	# comet.rotate(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	#endregion comet vincent
	## Prova degrees
	#region degrees
	# comet.transform.basis = comet2.transform.basis
	# comet.transform.basis = Util.get_equatorial_to_orbital_basis() * comet.transform.basis
	#endregion degrees
	## Prova lookat
	#region lookat
	# var tmp := comet.transform
	# comet.look_at(Util.sun_direction_vector, Vector3.UP)
	# comet.rotate(comet.transform.basis.y, deg_to_rad(-90))
	# comet.transform = tmp
	#endregion lookat
	## Prova quaternion
	#region quaternion
	# var quat1: Quaternion = Quaternion(comet.transform.basis.z, deg_to_rad(90 - Util.i))
	# var quat2: Quaternion = Quaternion(comet.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# var tot_quat := quat1 * quat2
	# tot_quat = tot_quat.normalized()
	# comet.quaternion = tot_quat
	#endregion quaternion
	return
	# if not rot_camera_viewport.size == Vector2i(900, 900):
	# 	# rot_camera_viewport.get_parent().position =
	# 	rot_camera_viewport.size = Vector2(900, 900)
	# 	rot_camera_viewport.get_parent().position = camera_position
	# else:
	# 	camera_position = rot_camera_viewport.get_parent().position
	# 	rot_camera_viewport.size = get_window().size
	# 	rot_camera_viewport.get_parent().position = Vector2(0, 0)


func _on_change_camera_btn_pressed() -> void:
	get_tree().call_group("camera", "change_camera")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_settings_btn_pressed() -> void:
	if not $Navbar/ModelBtn.button_pressed:
		return
	if not $Navbar/SettingsBtn.button_pressed:
		return
	print("Enabling settings tab, disabling model tab")
	$Navbar/ModelBtn.button_pressed = false
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = false
	var help_tab_nodes := get_tree().get_nodes_in_group("help_tab")
	for node in help_tab_nodes:
		node.visible = false
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = true
	


func _on_model_btn_pressed() -> void:
	if not $Navbar/SettingsBtn.button_pressed:
		return
	print("Enabling model tab, disabling settings tab")
	$Navbar/SettingsBtn.button_pressed = false
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = true
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = false
	var help_tab_nodes := get_tree().get_nodes_in_group("help_tab")
	for node in help_tab_nodes:
		node.visible = false
		
func _on_help_node_btn_pressed() -> void:
	if not $Navbar/HelpBtn.button_pressed:
		return
	print("Enabling model tab, disabling settings tab")
	$Navbar/HelpBtn.button_pressed = false
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = false
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = false
	var help_tab_nodes := get_tree().get_nodes_in_group("help_tab")
	for node in help_tab_nodes:
		node.visible = true

func _on_navbar_tab_changed(tab: int) -> void:
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	var help_tab_nodes := get_tree().get_nodes_in_group("help_tab")
	print(tab)
	match tab:
		0:
			for node in model_tab_nodes:
				node.visible = false
			for node in settings_tab_nodes:
				node.visible = true
			for node in help_tab_nodes:
				node.visible = false
		1:
			for node in model_tab_nodes:
				node.visible = true
			for node in settings_tab_nodes:
				node.visible = false
			for node in help_tab_nodes:
				node.visible = false
		2:
			for node in model_tab_nodes:
				node.visible = false
			for node in settings_tab_nodes:
				node.visible = false
			for node in help_tab_nodes:
				node.visible = true


func _on_toggle_date_btn_pressed() -> void:
	Util.date_label.visible = not Util.date_label.visible

func _on_toggle_nucleus_date_btn_pressed() -> void:
	print("Toggling nucleus date label visibility")
	Util.nucleus_date_label.visible = not Util.nucleus_date_label.visible


func _on_toggle_transparency_toggled(toggled_on: bool) -> void:
	if $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/OverlayImg".texture == null:
		return
	$/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/OverlayImg.visible = toggled_on
	# check if overlay_img exists
	sub_viewport_container.get_node("SubViewport").transparent_bg = toggled_on

func _on_toggle_nucleus_grid_btn_pressed() -> void:
	get_tree().call_group("comet", "toggle_nucleus_grid")


func _on_toggle_model_grid_btn_pressed() -> void:
	var grid_sprite := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/Sprite2D") as CanvasItem
	var ra_central := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/RACenterLabel") as CanvasItem
	var ra_left := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/RALeftLabel") as CanvasItem
	var ra_right := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/RARightLabel") as CanvasItem
	var dec_center := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/DECCenterLabel") as CanvasItem
	var dec_left := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/DECLeftLabel") as CanvasItem
	var dec_right := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/DECRightLabel") as CanvasItem
	
	grid_sprite.visible = not grid_sprite.visible
	ra_central.visible = not ra_central.visible
	ra_left.visible = not ra_left.visible
	ra_right.visible = not ra_right.visible
	dec_center.visible = not dec_center.visible
	dec_left.visible = not dec_left.visible
	dec_right.visible = not dec_right.visible

func _on_toggle_scale_btn_pressed() -> void:
	var viewport_scale := get_node("/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl/Scale") as CanvasItem
	Util.current_fov_label.visible = not Util.current_fov_label.visible
	viewport_scale.visible = not viewport_scale.visible
	
func update_save_load_buttons() -> void:
	var has_data := Util.has_jpl_data()

	if has_data:
		enable_btn("SaveBtn")
		enable_btn("LoadBtn")
	else:
		disable_btn("SaveBtn")
		disable_btn("LoadBtn")

func screenshot_composited_with_overlays(vp: SubViewport, want_alpha: bool) -> Image:
	var base: Image = await screenshot_subviewport(vp, want_alpha)
	var overlays: Image = await capture_overlays_with_alpha()

	if overlays.get_width() != base.get_width() or overlays.get_height() != base.get_height():
		overlays.resize(base.get_width(), base.get_height(), Image.INTERPOLATE_BILINEAR)

	var out: Image = Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(base, Rect2i(0, 0, base.get_width(), base.get_height()), Vector2i.ZERO)
	out.blend_rect(overlays, Rect2i(0, 0, overlays.get_width(), overlays.get_height()), Vector2i.ZERO)

	return out


func capture_overlays_with_alpha() -> Image:
	var root: Control = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer"

	var wanted_nodes: Array[CanvasItem] = [
		$"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/Sprite2D",
		$"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/DataControl",
		$"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/LabelControl",
	]

	var excluded_nodes: Array[CanvasItem] = [
		$"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/SubViewportContainer",
		$"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/OverlayImg",
	]

	var old_visibilities: Array[bool] = []
	for node in excluded_nodes:
		old_visibilities.append(node.visible)
		node.visible = false

	var capture_rect: Rect2 = _get_combined_global_rect(wanted_nodes)

	var black_bg: ColorRect = await _add_temp_background(root, Color(0, 0, 0, 1))
	var img_black: Image = await screenshot_rect(capture_rect)
	black_bg.queue_free()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var white_bg: ColorRect = await _add_temp_background(root, Color(1, 1, 1, 1))
	var img_white: Image = await screenshot_rect(capture_rect)
	white_bg.queue_free()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	for i in range(excluded_nodes.size()):
		excluded_nodes[i].visible = old_visibilities[i]

	return reconstruct_alpha_from_black_white(img_black, img_white)


func _add_temp_background(panel: Control, color: Color) -> ColorRect:
	var bg: ColorRect = ColorRect.new()
	bg.name = "__temp_export_bg__"
	bg.color = color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0

	panel.add_child(bg)
	panel.move_child(bg, 0)

	await panel_ready_for_capture(panel)
	return bg


func panel_ready_for_capture(panel: Control) -> void:
	panel.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw


func reconstruct_alpha_from_black_white(img_black: Image, img_white: Image) -> Image:
	var w: int = min(img_black.get_width(), img_white.get_width())
	var h: int = min(img_black.get_height(), img_white.get_height())

	var out: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)

	for y in range(h):
		for x in range(w):
			var cb: Color = img_black.get_pixel(x, y)
			var cw: Color = img_white.get_pixel(x, y)

			var ar: float = 1.0 - (cw.r - cb.r)
			var ag: float = 1.0 - (cw.g - cb.g)
			var ab: float = 1.0 - (cw.b - cb.b)

			var a: float = clamp((ar + ag + ab) / 3.0, 0.0, 1.0)

			var out_color: Color = Color(0, 0, 0, 0)

			if a > 0.0001:
				out_color.r = clamp(cb.r / a, 0.0, 1.0)
				out_color.g = clamp(cb.g / a, 0.0, 1.0)
				out_color.b = clamp(cb.b / a, 0.0, 1.0)
				out_color.a = a
			else:
				out_color = Color(0, 0, 0, 0)

			out.set_pixel(x, y, out_color)

	return out
	
func _get_combined_global_rect(nodes: Array[CanvasItem]) -> Rect2:
	var has_rect: bool = false
	var result: Rect2 = Rect2()

	for node in nodes:
		if node == null or not is_instance_valid(node) or not node.visible:
			continue

		var r: Rect2 = _get_canvas_item_global_rect(node)
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			continue

		if not has_rect:
			result = r
			has_rect = true
		else:
			result = result.merge(r)

	return result


func _get_canvas_item_global_rect(node: CanvasItem) -> Rect2:
	if node is Control:
		return (node as Control).get_global_rect()

	if node is Sprite2D:
		var sprite: Sprite2D = node as Sprite2D
		if sprite.texture == null:
			return Rect2(sprite.global_position, Vector2.ZERO)

		var size: Vector2 = sprite.texture.get_size() * sprite.scale
		var top_left: Vector2

		if sprite.centered:
			top_left = sprite.global_position - size * 0.5
		else:
			top_left = sprite.global_position

		return Rect2(top_left, size)

	return Rect2()

func screenshot_rect(global_rect: Rect2) -> Image:
	await RenderingServer.frame_post_draw

	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()

	var vis: Vector2 = vp.get_visible_rect().size
	if vis.x <= 0.0 or vis.y <= 0.0:
		return img

	var sx: float = float(img.get_width()) / float(vis.x)
	var sy: float = float(img.get_height()) / float(vis.y)

	var r: Rect2 = global_rect
	r.position *= Vector2(sx, sy)
	r.size *= Vector2(sx, sy)

	var ri: Rect2i = Rect2i(r.position, r.size)

	ri.position.x = clamp(ri.position.x, 0, img.get_width() - 1)
	ri.position.y = clamp(ri.position.y, 0, img.get_height() - 1)
	ri.size.x = clamp(ri.size.x, 1, img.get_width() - ri.position.x)
	ri.size.y = clamp(ri.size.y, 1, img.get_height() - ri.position.y)

	return img.get_region(ri)
