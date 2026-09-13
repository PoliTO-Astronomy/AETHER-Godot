extends VBoxContainer
class_name JetTable
var jet_entry_scene := preload("res://scenes/ui/jet_entry.tscn")
var emitter_scene := preload("res://scenes/particle_emitter.tscn")
var entry_emitter_dict := Dictionary()
@export var content_node: Container
@export var scroll_container: ScrollContainer
@export var max_height: float = 300

var _is_id_update_pending := false

func _ready() -> void:
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		printerr("Scroll container or content node not correctly assigned")
		return
	get_node("../JetPanel").resized.connect(_update_scroll_container_height)
	
## Update the scroll container height based on how many children (JetEntry) it has
func _update_scroll_container_height() -> void:
	await get_tree().process_frame
	#in case node is freed
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		return
	var total_content_node_height := content_node.get_combined_minimum_size().y
	var panel: Control = get_node("../JetPanel")
	var bottom := panel.get_global_rect().end.y - 12.0
	var available := (bottom - scroll_container.global_position.y) / scale.y
	available -= $AddJetEntryBtn.get_combined_minimum_size().y + get_theme_constant("separation")
	var new_height: float = min(total_content_node_height, min(max_height, max(40.0, available)))
	if scroll_container.custom_minimum_size.y != new_height:
		scroll_container.custom_minimum_size.y = new_height
		size.y = get_combined_minimum_size().y
	

## Called by Navbar._on_file_explorer_file_selected().
## Save the jet table data into the config
func save_data() -> void:
	# first I erase the section jets
	if SaveManager.config.has_section("jets"):
		SaveManager.config.erase_section("jets")
	for entry: JetEntry in content_node.get_children():
		SaveManager.config.set_value("jets", str(entry.jet_id), [entry.speed, entry.latitude, entry.longitude, entry.diffusion, entry.color, int(entry.density)])

func _connect_entry_to_emitter(entry: JetEntry, emitter: Emitter) -> void:
	entry.speed_edit.sanitized_edit_focus_exited.connect(emitter.update_speed)
	entry.latitude_edit.sanitized_edit_focus_exited.connect(emitter.update_lat)
	entry.longitude_edit.sanitized_edit_focus_exited.connect(emitter.update_long)
	entry.density_edit.sanitized_edit_focus_exited.connect(emitter.update_dens)
	entry.diffusion_edit.sanitized_edit_focus_exited.connect(emitter.update_diff)
	entry.color_edit.color_changed.connect(emitter.update_color)
	# The emitter is not in the 3D tree yet, so initialise its data directly.
	emitter.speed = entry.speed
	emitter.latitude = entry.latitude
	emitter.longitude = entry.longitude
	emitter.density = entry.density
	emitter.diffusion = entry.diffusion
	emitter.color = entry.color


## Called by Navbar._on_file_explorer_file_selected().
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	# first I remove all jet_entries
	# print("Before deleting the current jet_body" + str(entry_emitter_dict))
	_clear_data_for_load()
	var old_global_n_points := int(SaveManager.config.get_value("simulation", "n_points", 1))
	# print("After deleting current jet_body" + str(entry_emitter_dict))
	if SaveManager.config.has_section("jets"):
		var entries_to_add: PackedStringArray = SaveManager.config.get_section_keys("jets")
		# print("Entries to add:" + str(entries_to_add))
		for entry in entries_to_add:
			var loaded_entry: Array[Variant] = SaveManager.config.get_value("jets", str(entry))
			var new_entry := jet_entry_scene.instantiate() as JetEntry
			new_entry.set_id_label(int(entry))
			content_node.add_child(new_entry)

			var emitter := emitter_scene.instantiate() as Emitter


			new_entry.set_speed(loaded_entry[0])
			new_entry.set_latitude(loaded_entry[1])
			new_entry.set_longitude(loaded_entry[2])
			new_entry.set_diffusion(loaded_entry[3])
			new_entry.set_color(loaded_entry[4])
			
			var loaded_n_points := old_global_n_points
			if loaded_entry.size() > 5:
				loaded_n_points = loaded_entry[5]
			new_entry.set_density(loaded_n_points)
			_connect_entry_to_emitter(new_entry, emitter)
			emitter.jet_id = new_entry.jet_id

			# Saving (jet_entry,emitter) to a dictionary so that later on I can remove both entry(HUD) and the emitter node
			entry_emitter_dict.set(new_entry.get_instance_id(), emitter.get_instance_id())
			# print("Adding entry" + str(new_entry.get_instance_id()))
			# spawning an emitter at (0,0)
			get_tree().call_group("latitude", "spawn_emitter_at", new_entry.latitude, new_entry.longitude, emitter)
			emitter.update_position(Util.comet_radius)
	# print("Dict after finished loading" + str(entry_emitter_dict))
	# print("--------------------")
	_update_scroll_container_height()
	pass
func _on_add_jet_entry_btn_pressed() -> void:
	# creating the entry in the hud
	var new_entry := jet_entry_scene.instantiate() as JetEntry
	var entries := get_tree().get_nodes_in_group("jet_entry")
	var max_id := entries.size()
	new_entry.set_id_label(max_id)
	# new_entry.set_speed(0.0)

	# adding the entry to the vertical container
	content_node.add_child(new_entry)
	_update_scroll_container_height()

	# instantiating an emitter so that I can pass it to the CometMesh and thus setting correctly the position according
	# to the comet radius
	var emitter := emitter_scene.instantiate() as Emitter

	# connecting the emitter to SanitizedEdit signals so that whenever one of those SanitizedEdit value changes,
	# the corresponding update method is called on the emitter
	_connect_entry_to_emitter(new_entry, emitter)

	# Saving (jet_entry,emitter) to a dictionary so that later on I can remove both entry(HUD) and the emitter node
	entry_emitter_dict.set(new_entry.get_instance_id(), emitter.get_instance_id())
	# spawning an emitter at (0,0)
	get_tree().call_group("latitude", "spawn_emitter_at", new_entry.latitude, new_entry.longitude, emitter)
	emitter.update_position(Util.comet_radius)
	
func _clear_data_for_load() -> void:
	for child: Node in content_node.get_children().duplicate():
		var id := child.get_instance_id()
		var emitter_id: int = entry_emitter_dict[id]
		entry_emitter_dict.erase(id)
		child.queue_free()
		get_tree().call_group("comet", "remove_emitter", emitter_id)


## CalledbyJetEntry._on_remove_jet_btn_pressed()
func remove_jet_entry(id: int) -> void:
	# first deleting the entry, then removing the emitter by calling a comet's method
	var entry := instance_from_id(id)
	var emitter_id: int = entry_emitter_dict[id]
	entry_emitter_dict.erase(id)
	entry.queue_free()
	# # removing corresponding jet section
	get_tree().call_group("comet", "remove_emitter", emitter_id)

	# update container size and ids of each jet entry
	# the call is deferred so that it works properly even if multiple jets have been queued for deletion 
	_ensure_id_update_is_scheduled()


## Update ids and scroll size if an update_id has not been issued yet
func _ensure_id_update_is_scheduled() -> void:
	if not _is_id_update_pending:
		_is_id_update_pending = true
		call_deferred("_deferred_update_ids_and_scroll")


## Defers the update of ids and scroll container
func _deferred_update_ids_and_scroll() -> void:
	_is_id_update_pending = false
	_update_scroll_container_height()

	var entries := $JetBodyScrollBar/JetBody.get_children()
	var tmp_id := 0

	for _entry in entries as Array[JetEntry]:
		if _entry is JetEntry and is_instance_valid(_entry):
			if _entry.is_queued_for_deletion():
				continue
			# updating the id only if it's different
			if _entry.jet_id != tmp_id:
				_entry.set_id_label(tmp_id)
			tmp_id += 1

## CalledbyJetEntry._on_toggle_jet_btn_pressed()
func toggle_jet_entry(id: int) -> void:
	var emitter_to_toggle := instance_from_id(entry_emitter_dict[id])
	emitter_to_toggle.visible = not emitter_to_toggle.visible
