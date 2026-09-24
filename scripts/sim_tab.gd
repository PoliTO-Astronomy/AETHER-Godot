extends CanvasLayer
const FITS_IMAGE_LOADER = preload("res://scripts/fits_image_loader.gd")
@onready var file_explorer: FileDialog = $"/root/Hud/Body/SimTab/Control/FileExplorer"
@onready var overlay_img_linedit: LineEdit = $"/root/Hud/Body/ScaleTab/Control/OverlayImgLineEdit"
@onready var overlay_img_picker_btn: Button = $"/root/Hud/Body/ScaleTab/Control/OverlayImgPickerBtn"
@onready var del_overlay_img_btn: Button = $"/root/Hud/Body/ScaleTab/Control/DelOverlayImgBtn"
# @onready var transparency_label: Label = $"Control/TransparencyLabel"
@onready var transparency_slider: HSlider = $"/root/Hud/Body/SimTab/Control/TransparencySlider"
@onready var overlay_img: TextureRect = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/OverlayImg"
@onready var sub_viewport_container: SubViewportContainer = $"/root/Hud/Viewport/Panel/CoordinateGrid/AspectRatioContainer/SubViewportContainer"
var image_opacity_slider: HSlider
var image_opacity_label: Label
@onready var brightness_slider: HSlider = $Control/BrightnessSlider
@onready var brightness_label: Label = $Control/BrightnessLabel
@onready var contrast_slider: HSlider = $Control/ContrastSlider
@onready var contrast_label: Label = $Control/ContrastLabel
var display_adjustment_material: ShaderMaterial
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# $Control/FrequencyEdit.set_value(1)
	# $Control/NumRotationEdit.set_value(1)
	# $Control/JetRateEdit.set_value(5)
	image_opacity_slider = $Control/ImageOpacitySlider
	image_opacity_label = $Control/ImageOpacityLabel
	image_opacity_slider.value_changed.connect(_on_image_opacity_changed)
	brightness_slider.value_changed.connect(_on_display_adjustment_changed)
	contrast_slider.value_changed.connect(_on_display_adjustment_changed)
	_setup_display_adjustment_material()
	_update_opacity_labels()
	$Control/CCDImagePanel.resized.connect(_layout_opacity_controls)
	call_deferred("_layout_opacity_controls")

func _layout_opacity_controls() -> void:
	if not Hud.automatic_layout:
		return
	var panel: Control = $Control/CCDImagePanel
	var width := (panel.size.x - 44.0) / 2.0
	var origin := panel.position + Vector2(16, 32)
	var model_label: Label = $Control/ModelTransparencyLabel
	for label in [model_label, image_opacity_label, brightness_label, contrast_label]:
		label.add_theme_font_size_override("font_size", 14)
	var label_width := 78.0
	var slider_width := maxf(42.0, width - label_width)
	Hud._place_control(model_label, Rect2(origin, Vector2(label_width, 22)))
	Hud._place_control(transparency_slider, Rect2(origin + Vector2(label_width, 0), Vector2(slider_width, 22)))
	Hud._place_control(image_opacity_label, Rect2(origin + Vector2(width + 12, 0), Vector2(label_width, 22)))
	Hud._place_control(image_opacity_slider, Rect2(origin + Vector2(width + 12 + label_width, 0), Vector2(slider_width, 22)))
	Hud._place_control(brightness_label, Rect2(origin + Vector2(0, 24), Vector2(label_width, 22)))
	Hud._place_control(brightness_slider, Rect2(origin + Vector2(label_width, 24), Vector2(slider_width, 22)))
	Hud._place_control(contrast_label, Rect2(origin + Vector2(width + 12, 24), Vector2(label_width, 22)))
	Hud._place_control(contrast_slider, Rect2(origin + Vector2(width + 12 + label_width, 24), Vector2(slider_width, 22)))
	Hud._place_control($Control/CCDImageInfoBtn, Rect2(panel.position + Vector2(112, 6), Vector2(20, 20)))
	Hud._place_control($Control/CCDImgLabel, Rect2(panel.position + Vector2(14, 5), Vector2(96, 24)))
	Hud._place_control($Control/ToggleTransparency,
		Rect2(panel.position + Vector2(panel.size.x - 88, 7), Vector2(38, 24)))
	_update_opacity_labels()

func _update_opacity_labels() -> void:
	$Control/ModelTransparencyLabel.text = "Model: %d%%" % roundi(transparency_slider.value * 100)
	image_opacity_label.text = "Image: %d%%" % roundi(image_opacity_slider.value * 100)
	brightness_label.text = "Bright: %+.2f" % brightness_slider.value
	contrast_label.text = "Contrast: %.2f" % contrast_slider.value

func _on_image_opacity_changed(value: float) -> void:
	overlay_img.modulate.a = value
	_update_opacity_labels()

func _setup_display_adjustment_material() -> void:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float brightness = 0.0;
uniform float contrast = 1.0;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 adjusted = clamp((source.rgb - vec3(0.5)) * contrast + vec3(0.5 + brightness), vec3(0.0), vec3(1.0));
	COLOR = vec4(adjusted, source.a) * COLOR;
}"""
	display_adjustment_material = ShaderMaterial.new()
	display_adjustment_material.shader = shader
	overlay_img.material = display_adjustment_material
	_on_display_adjustment_changed(0.0)

func _on_display_adjustment_changed(_value: float) -> void:
	if display_adjustment_material != null:
		display_adjustment_material.set_shader_parameter("brightness", brightness_slider.value)
		display_adjustment_material.set_shader_parameter("contrast", contrast_slider.value)
	_update_opacity_labels()

## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	SaveManager.config.set_value("display", "image_opacity", image_opacity_slider.value)
	SaveManager.config.set_value("display", "model_opacity", transparency_slider.value)
	SaveManager.config.set_value("display", "image_brightness", brightness_slider.value)
	SaveManager.config.set_value("display", "image_contrast", contrast_slider.value)
	SaveManager.config.set_value("simulation", "frequency", $Control/FrequencyEdit/SanitizedEdit.text)
	SaveManager.config.set_value("simulation", "num_rotations", $"../CometTab/Control/NumRotationEdit".text)
	SaveManager.config.set_value("simulation", "jet_rate", $"../JetsTab/Control/JetRateEdit".text)
	SaveManager.config.set_value("simulation", "scale", $Control/KmScaleEdit.text)
	SaveManager.config.set_value("simulation", "i", $Control/IEdit.text)
	SaveManager.config.set_value("simulation", "phi", $Control/PhiEdit.text)
	SaveManager.config.set_value("simulation", "true_anomaly", $Control/TrueAnomalyEdit.text)
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	image_opacity_slider.value = float(SaveManager.config.get_value("display", "image_opacity", 1.0))
	transparency_slider.value = float(SaveManager.config.get_value("display", "model_opacity", 1.0))
	brightness_slider.value = float(SaveManager.config.get_value("display", "image_brightness", 0.0))
	contrast_slider.value = float(SaveManager.config.get_value("display", "image_contrast", 1.0))
	$Control/FrequencyEdit.set_value(float(SaveManager.config.get_value("simulation", "frequency", 0)))
	$"../CometTab/Control/NumRotationEdit".set_value(float(SaveManager.config.get_value("simulation", "num_rotations", 0)))
	var saved_integration_step := float(SaveManager.config.get_value(
		"simulation", "jet_rate", Util.DEFAULT_INTEGRATION_STEP_MINUTES))
	$"../JetsTab/Control/JetRateEdit".set_value(maxf(
		saved_integration_step, Util.MIN_INTEGRATION_STEP_MINUTES))
	$Control/KmScaleEdit.set_value(float(SaveManager.config.get_value("simulation", "scale", 0)))


func _on_overlay_img_chosen() -> void:
	print("lol")
# shows the navbar.file_explorer
func _on_overlay_img_picker_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_explorer.filters = ["*.png,*.jpg,*.jpeg,*.webp,*.fits,*.fit,*.fts;CCD images"]
	SaveManager.prepare_file_dialog(file_explorer)
	file_explorer.popup_centered()
	
	file_explorer.visible = true


func _on_file_explorer_file_selected(path: String) -> void:
	if not load_texture(path):
		return
	SaveManager.remember_file_directory(path)
	overlay_img_linedit.visible = true
	overlay_img_linedit.text = path.get_file()
	overlay_img_linedit.tooltip_text = "%s\n%d × %d px" % [path, overlay_img.texture.get_width(), overlay_img.texture.get_height()]

	# overlay_img_picker_btn.visible = false
	# del_overlay_img_btn.visible = true

	# # transparency_label.visible = true
	# transparency_slider.visible = true

	sub_viewport_container.get_node("SubViewport").transparent_bg = true

	overlay_img.visible = true
	$Control/ToggleTransparency.set_pressed_no_signal(true)
	sub_viewport_container.modulate.a = transparency_slider.value

func load_texture(path: String) -> bool:
	var img: Image
	var extension := path.get_extension().to_lower()
	var fits_metadata: Dictionary = {}
	if path.to_lower().ends_with(".fits.fz"):
		Util.create_popup("FITS image not loaded", "Compressed FITS images are not supported yet. Please provide an uncompressed FITS file.")
		return false
	if extension in ["fits", "fit", "fts"]:
		fits_metadata = FITS_IMAGE_LOADER.load_image(path)
		if not fits_metadata.get("ok", false):
			Util.create_popup("FITS image not loaded", str(fits_metadata.get("error", "The selected FITS file could not be read.")))
			return false
		img = fits_metadata["image"]
	else:
		img = Image.load_from_file(path)
	if img == null or img.is_empty():
		Util.create_popup("Image not loaded", "The selected file could not be read. Choose a FITS, PNG, JPEG or WebP image.")
		return false
	overlay_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_img.texture = ImageTexture.create_from_image(img)
	overlay_img.modulate.a = image_opacity_slider.value
	# The square model view represents the longest image side; padding preserves pixel scale.
	$"../ScaleTab/Control/TelImageSizeEdit".set_value(max(img.get_width(), img.get_height()))
	var image_details := "%d × %d px; longest side used for the square field of view" % [img.get_width(), img.get_height()]
	if not fits_metadata.is_empty():
		image_details += "\nFITS BITPIX %d; automatic display range %.5g to %.5g" % [
			int(fits_metadata["bitpix"]),
			float(fits_metadata["display_min"]),
			float(fits_metadata["display_max"]),
		]
		var resolution_edit: SanitizedEdit = $"../ScaleTab/Control/TelResolutionEdit"
		var pixel_scale := float(fits_metadata.get("pixel_scale_arcsec", 0.0))
		if pixel_scale > 0.0:
			resolution_edit.set_value(pixel_scale)
			var scale_source := str(fits_metadata.get("pixel_scale_source", "FITS header"))
			var scale_x := float(fits_metadata.get("pixel_scale_x_arcsec", pixel_scale))
			var scale_y := float(fits_metadata.get("pixel_scale_y_arcsec", pixel_scale))
			image_details += "\nResolution %.7g arcsec/pixel read from %s" % [pixel_scale, scale_source]
			if not is_equal_approx(scale_x, scale_y):
				image_details += " (X %.7g; Y %.7g; area-preserving mean)" % [scale_x, scale_y]
			resolution_edit.tooltip_text = "Automatically read from the FITS header (%s). You can replace it manually." % scale_source
		else:
			resolution_edit.tooltip_text = "No angular resolution was found in the FITS header. Enter arcsec/pixel manually."
	$"../ScaleTab/Control/TelImageSizeEdit".tooltip_text = image_details
	return true

func _on_del_overlay_img_btn_pressed() -> void:
	# overlay_img_linedit.visible = false
	overlay_img_linedit.text = ""
	# overlay_img_picker_btn.visible = true
	# del_overlay_img_btn.visible = false
	# # transparency_label.visible = false
	# transparency_slider.value = 0.5
	# transparency_slider.visible = false
	# remove overlay image
	overlay_img.texture = null

	sub_viewport_container.modulate.a = 1.0
	sub_viewport_container.get_node("SubViewport").transparent_bg = false
	overlay_img_linedit.tooltip_text = ""

func _on_transparency_slider_value_changed(value: float) -> void:
	_update_opacity_labels()
	if overlay_img.texture == null or not overlay_img.visible:
		sub_viewport_container.modulate.a = 1.0
		return
	sub_viewport_container.modulate.a = value
