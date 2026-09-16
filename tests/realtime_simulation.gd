extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func refresh(comet: Comet) -> void:
	comet._process(0)
	await get_tree().create_timer(0.3).timeout

func _ready() -> void:
	for frame in range(5):
		await get_tree().process_frame
	var comet := get_node("/root/World/CometMesh") as Comet
	comet.set_process(false)
	var controls := comet.animation_slider
	var table := Hud.get_node("Body/JetsTab/Control/JetTable")
	table._on_add_jet_entry_btn_pressed()
	comet.update_frequency(1)
	comet.update_num_rotation(1)
	comet.update_jet_rate(5)
	comet.update_particle_diameter(0.03)
	comet.update_particle_density(0.8)
	comet.update_sun_comet_distance(1.2)
	var emitter: Emitter = get_tree().get_first_node_in_group("emitter")
	emitter.update_speed(30)
	controls._on_play_instant_btn_pressed()
	var initial_count := emitter.mm_emitter.multimesh.instance_count
	check(initial_count > 0 and initial_count <= 12, "Initial INST emits from illuminated steps")
	comet.update_radius(0.2)
	emitter.update_dens(3)
	await refresh(comet)
	check(emitter.mm_emitter.multimesh.instance_count == initial_count * 3, "INST rebuild uses new density without duplication")
	check(is_equal_approx(emitter.position.length(), 0.2), "INST rebuild uses current radius")
	var previous_acceleration := emitter.a
	comet.update_particle_diameter(0.06)
	await refresh(comet)
	check(emitter.a < previous_acceleration, "Rebuilt dust acceleration")
	comet.update_direction_rotation(35)
	var new_origin := comet.quaternion
	await refresh(comet)
	check(comet.simulation_origin.is_equal_approx(new_origin), "New pole orientation retained")
	controls._on_stop_btn_pressed()
	controls._on_play_btn_pressed()
	for step in range(4):
		comet._process(0.016)
	comet.update_radius(0.3)
	await refresh(comet)
	check(Util.is_simulation, "SIM mode preserved")
	check(comet.step_counter == 1, "SIM starts a new buffer from the first step")
	check(emitter.mm_emitter.multimesh.instance_count == 36, "SIM buffer capacity rebuilt")
	controls._on_pause_btn_pressed()
	emitter.update_speed(45)
	await refresh(comet)
	check(comet.animation_state == Comet.ANIMATION_STATE.PAUSED, "Pause preserved")
	check(not controls.get_node("PlayBtn").disabled, "Paused SIM can resume")
	comet.update_num_rotation(2)
	comet._process(0)
	controls._on_stop_btn_pressed()
	await get_tree().create_timer(0.3).timeout
	check(emitter.mm_emitter.multimesh.instance_count == 0, "STOP cancels pending rebuild")
	comet.update_radius(0.4)
	await refresh(comet)
	check(emitter.mm_emitter.multimesh.instance_count == 0, "Edits after STOP do not restart")
	controls._on_play_instant_btn_pressed()
	check(comet.n_steps == 24 and emitter.mm_emitter.multimesh.instance_count > 0 and emitter.mm_emitter.multimesh.instance_count <= 72, "Next INST uses latest rotation count")
	table._on_add_jet_entry_btn_pressed()
	await refresh(comet)
	check(get_tree().get_nodes_in_group("emitter").size() == 2, "Adding a jet while active rebuilds")
	table.remove_jet_entry(table.content_node.get_child(1).get_instance_id())
	await refresh(comet)
	check(get_tree().get_nodes_in_group("emitter").size() == 1, "Removing a jet while active rebuilds")
	comet.update_frequency(0)
	await refresh(comet)
	check(not controls.is_stop_enabled(), "Invalid duration stops safely")
	print("REALTIME CHECK: ", failures.size(), " failures")
	get_tree().quit(0 if failures.is_empty() else 1)
