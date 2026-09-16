extends RefCounted
class_name FitsImageLoader

const FITS_BLOCK_SIZE := 2880
const FITS_CARD_SIZE := 80
const MAX_IMAGE_PIXELS := 67108864
const MAX_SAMPLE_VALUES := 65536
const SUPPORTED_BITPIX := [8, 16, 32, 64, -32, -64]

static func load_image(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("The FITS file could not be opened.")

	var hdu_offset: int = 0
	while hdu_offset + FITS_BLOCK_SIZE <= file.get_length():
		var hdu := _read_hdu_header(file, hdu_offset)
		if not hdu.get("ok", false):
			return hdu
		var header: Dictionary = hdu["header"]
		var bitpix := int(header.get("BITPIX", 0))
		var naxis := int(header.get("NAXIS", 0))
		var width := int(header.get("NAXIS1", 0))
		var height := int(header.get("NAXIS2", 0))
		var extension_type := str(header.get("XTENSION", "")).strip_edges().to_upper()
		if extension_type == "BINTABLE" and bool(header.get("ZIMAGE", false)):
			return _failure("Compressed FITS images are not supported yet. Please provide an uncompressed FITS file.")
		var is_image_hdu := header.has("SIMPLE") or extension_type == "IMAGE"
		var is_image := is_image_hdu and naxis >= 2 and width > 0 and height > 0 and bitpix in SUPPORTED_BITPIX
		if is_image:
			return _decode_image_hdu(file, header, int(hdu["data_offset"]), width, height, bitpix)

		var data_size := _hdu_data_size(header)
		if data_size < 0:
			return _failure("The FITS header contains invalid image dimensions.")
		hdu_offset = int(hdu["data_offset"]) + _padded_size(data_size)

	return _failure("No supported image was found in the FITS file.")

static func _read_hdu_header(file: FileAccess, offset: int) -> Dictionary:
	file.seek(offset)
	var header: Dictionary = {}
	var cards_read := 0
	var found_end := false
	while file.get_position() + FITS_CARD_SIZE <= file.get_length():
		var card := file.get_buffer(FITS_CARD_SIZE).get_string_from_ascii()
		cards_read += 1
		var keyword := card.substr(0, 8).strip_edges()
		if keyword == "END":
			found_end = true
			break
		if keyword.is_empty() or card.substr(8, 1) != "=":
			continue
		header[keyword] = _parse_header_value(_value_without_comment(card.substr(10)))
		if cards_read > 100000:
			return _failure("The FITS header is unexpectedly large.")
	if not found_end:
		return _failure("The FITS header is incomplete: END card not found.")
	var header_size := _padded_size(cards_read * FITS_CARD_SIZE)
	return {"ok": true, "header": header, "data_offset": offset + header_size}

static func _value_without_comment(value: String) -> String:
	var in_string := false
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if character == "'":
			in_string = not in_string
		elif character == "/" and not in_string:
			return value.substr(0, index).strip_edges()
	return value.strip_edges()

static func _parse_header_value(value: String) -> Variant:
	var clean := value.strip_edges()
	if clean.begins_with("'"):
		var closing_quote := clean.rfind("'")
		return clean.substr(1, maxi(closing_quote - 1, 0)).replace("''", "'").strip_edges()
	if clean == "T":
		return true
	if clean == "F":
		return false
	var numeric := clean.replace("D", "E").replace("d", "e")
	if numeric.is_valid_int():
		return int(numeric)
	if numeric.is_valid_float():
		return float(numeric)
	return clean

static func _hdu_data_size(header: Dictionary) -> int:
	var bitpix := absi(int(header.get("BITPIX", 0)))
	var naxis := int(header.get("NAXIS", 0))
	if bitpix == 0 or naxis <= 0:
		return 0
	var elements: int = 1
	for axis in range(1, naxis + 1):
		var axis_size := int(header.get("NAXIS%d" % axis, 0))
		if axis_size < 0:
			return -1
		elements *= axis_size
	var pcount := int(header.get("PCOUNT", 0))
	var gcount := int(header.get("GCOUNT", 1))
	return (bitpix / 8) * gcount * (pcount + elements)

static func _decode_image_hdu(file: FileAccess, header: Dictionary, data_offset: int, width: int, height: int, bitpix: int) -> Dictionary:
	var pixel_count := width * height
	if pixel_count <= 0 or pixel_count > MAX_IMAGE_PIXELS:
		return _failure("The FITS image is too large to display safely (%d × %d pixels)." % [width, height])
	var bytes_per_value := absi(bitpix) / 8
	if data_offset + pixel_count * bytes_per_value > file.get_length():
		return _failure("The FITS image data is incomplete.")

	var bscale := float(header.get("BSCALE", 1.0))
	var bzero := float(header.get("BZERO", 0.0))
	var has_blank := bitpix > 0 and header.has("BLANK")
	var blank_value := int(header.get("BLANK", 0))
	var sample_step := maxi(1, ceili(float(pixel_count) / MAX_SAMPLE_VALUES))
	var samples: Array[float] = []
	file.seek(data_offset)
	file.big_endian = true
	for index in range(pixel_count):
		var raw: Variant = _read_value(file, bitpix)
		if _is_missing_value(raw, bitpix, has_blank, blank_value):
			continue
		if index % sample_step == 0:
			samples.append(float(raw) * bscale + bzero)
	if samples.is_empty():
		return _failure("The FITS image contains no finite pixel values.")

	samples.sort()
	var low_index := clampi(floori((samples.size() - 1) * 0.01), 0, samples.size() - 1)
	var high_index := clampi(ceili((samples.size() - 1) * 0.995), 0, samples.size() - 1)
	var display_min := samples[low_index]
	var display_max := samples[high_index]
	if display_max <= display_min:
		display_min = samples.front()
		display_max = samples.back()
	if display_max <= display_min:
		display_max = display_min + 1.0

	var pixels := PackedByteArray()
	pixels.resize(pixel_count * 4)
	file.seek(data_offset)
	file.big_endian = true
	for source_index in range(pixel_count):
		var raw: Variant = _read_value(file, bitpix)
		var intensity := 0.0
		if not _is_missing_value(raw, bitpix, has_blank, blank_value):
			var physical_value := float(raw) * bscale + bzero
			intensity = clampf((physical_value - display_min) / (display_max - display_min), 0.0, 1.0)
			# A square-root stretch preserves bright structure and reveals faint coma detail.
			intensity = sqrt(intensity)
		@warning_ignore("integer_division")
		var source_y: int = source_index / width
		var source_x := source_index % width
		var target_index := ((height - 1 - source_y) * width + source_x) * 4
		var channel := clampi(roundi(intensity * 255.0), 0, 255)
		pixels[target_index] = channel
		pixels[target_index + 1] = channel
		pixels[target_index + 2] = channel
		pixels[target_index + 3] = 255

	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
	var result := {
		"ok": true,
		"image": image,
		"width": width,
		"height": height,
		"bitpix": bitpix,
		"display_min": display_min,
		"display_max": display_max,
	}
	result.merge(_extract_pixel_scale_arcsec(header))
	return result

static func _extract_pixel_scale_arcsec(header: Dictionary) -> Dictionary:
	# These commonly used keywords already express angular size per pixel in arcseconds.
	for keyword in ["PIXSCALE", "SECPIX", "CCDSCALE"]:
		var direct_value := _positive_header_number(header, keyword)
		if direct_value > 0.0:
			return _pixel_scale_result(direct_value, direct_value, keyword)

	for keyword_pair in [["PIXSCAL1", "PIXSCAL2"], ["SECPIX1", "SECPIX2"]]:
		var paired_values: Array[float] = []
		for keyword in keyword_pair:
			var paired_value := _positive_header_number(header, keyword)
			if paired_value > 0.0:
				paired_values.append(paired_value)
		if not paired_values.is_empty():
			return _pixel_scale_from_values(paired_values, "%s/%s" % [keyword_pair[0], keyword_pair[1]])

	# A CD matrix stores the celestial transformation in angular units per pixel.
	var cd_keys := ["CD1_1", "CD1_2", "CD2_1", "CD2_2"]
	var has_cd_matrix := false
	for keyword in cd_keys:
		if header.has(keyword):
			has_cd_matrix = true
			break
	if has_cd_matrix:
		var unit_1 := _angular_unit_to_arcsec(str(header.get("CUNIT1", "deg")))
		var unit_2 := _angular_unit_to_arcsec(str(header.get("CUNIT2", "deg")))
		if unit_1 > 0.0 and unit_2 > 0.0:
			var cd11 := _header_number(header, "CD1_1") * unit_1
			var cd12 := _header_number(header, "CD1_2") * unit_1
			var cd21 := _header_number(header, "CD2_1") * unit_2
			var cd22 := _header_number(header, "CD2_2") * unit_2
			var scale_x := sqrt(cd11 * cd11 + cd21 * cd21)
			var scale_y := sqrt(cd12 * cd12 + cd22 * cd22)
			var cd_result := _pixel_scale_result(scale_x, scale_y, "CD matrix")
			if not cd_result.is_empty():
				return cd_result

	# CDELT is the standard WCS increment. CUNIT defaults to degrees in celestial WCS.
	var cdelt_values: Array[float] = []
	for axis in [1, 2]:
		var keyword := "CDELT%d" % axis
		if not header.has(keyword):
			continue
		var unit_factor := _angular_unit_to_arcsec(str(header.get("CUNIT%d" % axis, "deg")))
		var value := absf(_header_number(header, keyword)) * unit_factor
		if is_finite(value) and value > 0.0:
			cdelt_values.append(value)
	if not cdelt_values.is_empty():
		return _pixel_scale_from_values(cdelt_values, "CDELT")

	# Some acquisition systems provide physical pixel size (micrometres) and focal length (mm).
	var focal_length_mm := _positive_header_number(header, "FOCALLEN")
	if focal_length_mm > 0.0:
		var physical_values: Array[float] = []
		for keyword in ["XPIXSZ", "YPIXSZ"]:
			var pixel_size_um := _positive_header_number(header, keyword)
			if pixel_size_um > 0.0:
				physical_values.append(206.264806 * pixel_size_um / focal_length_mm)
		if not physical_values.is_empty():
			return _pixel_scale_from_values(physical_values, "pixel size/focal length")

	return {}

static func _pixel_scale_from_values(values: Array[float], source: String) -> Dictionary:
	if values.size() == 1:
		return _pixel_scale_result(values[0], values[0], source)
	return _pixel_scale_result(values[0], values[1], source)

static func _pixel_scale_result(scale_x: float, scale_y: float, source: String) -> Dictionary:
	if not is_finite(scale_x) or not is_finite(scale_y) or scale_x <= 0.0 or scale_y <= 0.0:
		return {}
	# AETHER currently accepts one scale value, so use the area-preserving mean for non-square pixels.
	return {
		"pixel_scale_arcsec": sqrt(scale_x * scale_y),
		"pixel_scale_x_arcsec": scale_x,
		"pixel_scale_y_arcsec": scale_y,
		"pixel_scale_source": source,
	}

static func _positive_header_number(header: Dictionary, keyword: String) -> float:
	var value := absf(_header_number(header, keyword))
	return value if is_finite(value) and value > 0.0 else 0.0

static func _header_number(header: Dictionary, keyword: String) -> float:
	if not header.has(keyword):
		return 0.0
	var value: Variant = header[keyword]
	if value is int or value is float:
		return float(value)
	var text := str(value).strip_edges().replace("D", "E").replace("d", "e")
	return float(text) if text.is_valid_float() else 0.0

static func _angular_unit_to_arcsec(unit: String) -> float:
	var normalized := unit.strip_edges().to_lower().replace(" ", "")
	match normalized:
		"", "deg", "degree", "degrees":
			return 3600.0
		"arcsec", "arcsecond", "arcseconds", "asec":
			return 1.0
		"arcmin", "arcminute", "arcminutes", "amin":
			return 60.0
		"rad", "radian", "radians":
			return 206264.80624709636
	return 0.0

static func _read_value(file: FileAccess, bitpix: int) -> Variant:
	match bitpix:
		8:
			return file.get_8()
		16:
			var value_16 := file.get_16()
			return value_16 - 65536 if value_16 >= 32768 else value_16
		32:
			var value_32 := file.get_32()
			return value_32 - 4294967296 if value_32 >= 2147483648 else value_32
		64:
			return file.get_64()
		-32:
			return file.get_float()
		-64:
			return file.get_double()
	return NAN

static func _is_missing_value(value: Variant, bitpix: int, has_blank: bool, blank_value: int) -> bool:
	if bitpix < 0:
		var floating_value := float(value)
		return is_nan(floating_value) or is_inf(floating_value)
	return has_blank and int(value) == blank_value

static func _padded_size(size: int) -> int:
	return ceili(float(size) / FITS_BLOCK_SIZE) * FITS_BLOCK_SIZE if size > 0 else 0

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
