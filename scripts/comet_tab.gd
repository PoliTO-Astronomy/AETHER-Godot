extends CanvasLayer


## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	print("Distanza sole: " + $Control/EditSunCometDist.text)
	print(Util.jpl_data)
	SaveManager.config.set_value("comet", "selected_date", Util.date_label.text)
	SaveManager.config.set_value("comet", "distance_from_sun", $Control/EditSunCometDist.text)
	SaveManager.config.set_value("comet", "direction", $Control/EditCometDir/SanitizedEdit.text)
	SaveManager.config.set_value("comet", "inclination", $Control/EditCometIncl/SanitizedEdit.text)
	SaveManager.config.set_value("comet", "radius", $Control/EditRadius/SanitizedEdit.text)
	SaveManager.config.set_value("comet", "alpha_p", $Control/AlphaPSanEdit/SanitizedEdit.text)
	SaveManager.config.set_value("comet", "delta_p", $Control/DeltaPSanEdit/SanitizedEdit.text)

	SaveManager.config.set_value("sun", "direction", $Control/EditSunDir/SanitizedEdit.text)
	SaveManager.config.set_value("sun", "inclination", $Control/EditSunIncl/SanitizedEdit.text)

	SaveManager.config.set_value("particle", "albedo", $Control/EditAlbedo.text)
	SaveManager.config.set_value("particle", "diameter", $Control/EditParticleDiameter.text)
	SaveManager.config.set_value("particle", "density", $Control/EditParticleDensity.text)

	
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	var saved_date : String = str(SaveManager.config.get_value("comet", "selected_date", ""))
	if saved_date != "":
		get_tree().call_group("switch_date", "switch_date_load_saved_date", saved_date)
	$Control/EditSunCometDist.set_value(float(SaveManager.config.get_value("comet", "distance_from_sun", 0)))
	$Control/EditRadius.set_value(float(SaveManager.config.get_value("comet", "radius", 0)))
	$Control/EditCometIncl.set_value(float(SaveManager.config.get_value("comet", "inclination", 0)))
	$Control/EditCometDir.set_value(float(SaveManager.config.get_value("comet", "direction", 0)))
	var saved_alpha := float(SaveManager.config.get_value("comet", "alpha_p", 0))
	var saved_delta := float(SaveManager.config.get_value("comet", "delta_p", 0))
	$Control/AlphaPSanEdit.set_value(float(SaveManager.config.get_value("comet", "alpha_p", 0)))
	$Control/DeltaPSanEdit.set_value(float(SaveManager.config.get_value("comet", "delta_p", 0)))
	# forza l'aggiornamento dei valori reali usati nei calcoli
	get_tree().call_group("alpha_p", "update_alpha_p", saved_alpha)
	get_tree().call_group("delta_p", "update_delta_p", saved_delta)
	$Control/EditSunDir.set_value(float(SaveManager.config.get_value("sun", "direction", 0)))
	$Control/EditSunIncl.set_value(float(SaveManager.config.get_value("sun", "inclination", 0)))

	$Control/EditAlbedo.set_value(float(SaveManager.config.get_value("particle", "albedo", 0)))
	$Control/EditParticleDiameter.set_value(float(SaveManager.config.get_value("particle", "diameter", 0)))
	$Control/EditParticleDensity.set_value(float(SaveManager.config.get_value("particle", "density", 0)))


func _on_next_date_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_next_date")


func _on_prev_date_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_prev_date")


func _on_prev_date_full_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_first_date")


func _on_next_date_full_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_last_date")


func _on_next_date_btn_button_down() -> void:
	get_tree().call_group("switch_date", "_on_next_btn_button_down")


func _on_next_date_btn_button_up() -> void:
	get_tree().call_group("switch_date", "_on_next_btn_button_up")


func _on_prev_date_btn_button_down() -> void:
	get_tree().call_group("switch_date", "_on_prev_btn_button_down")


func _on_prev_date_btn_button_up() -> void:
	get_tree().call_group("switch_date", "_on_prev_btn_button_up")


func _on_hold_start_timer_timeout() -> void:
	get_tree().call_group("switch_date", "_on_hold_start_timer_timeout_forward")


func _on_repeat_timer_timeout() -> void:
	get_tree().call_group("switch_date", "_on_repeat_timer_timeout_forward")
