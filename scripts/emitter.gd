
extends Node3D
class_name Emitter
const RAY_LENGHT = 1000000
# const N_POINTS = 5
# const N_POINTS = 0

var particle_scene := preload("res://scenes/particle.tscn")
# @onready var comet: MeshInstance3D = $"/root/World/CometMesh"

var particles_alive: Array[Particle]

var _point_mesh: PointMesh

var particle_mesh: MeshInstance3D

# properties of emitter/jet_entry
var jet_id: int
var speed: float
var latitude: float
var longitude: float
## Total number of particles emitted by this jet at each integration step.
var density: int = 1
var diffusion: float
var color: Color

## acceleration of a single particle
var a: float = 0.0


#multimesh
var mm_emitter: MultiMeshInstance3D = MultiMeshInstance3D.new()
var global_positions: Array[Vector3] ## global position of the mm_emitter at each instance spawned
var initial_positions: Array[Vector3] ## initial position of the mm_emitter at each instance spawned
var particle_speeds: Array[float] ## speeds of each particle
var normal_dirs: Array[Vector3] ## normal_dir of the mm_emitter at each instance spawned
var time_alive: Array[int] = [] # number of ticks each particle has been alive
var total_space: Array[float] = [] # total space travelled by the particles

#sim related
var num_particles: int = 0

var is_lit: bool = true
@export var max_particles: int = 10
@export var particle_per_second: int = 5
@export var particle_radius: float = 0.05
@export var enabled: bool = true
@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
var norm: Vector3 = Vector3(0, 1, 0)
var initial_norm: Vector3 = Vector3(0, 1, 0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var unshaded_material := StandardMaterial3D.new()
	unshaded_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	unshaded_material.vertex_color_use_as_albedo = true
	particle_mesh = $ParticleMesh
	
	#$Particle/ParticleArea/ParticleShape.shape.set_radius($Particle.mesh.radius)
	$ParticleMesh/ParticleArea/ParticleShape.shape.set_radius(particle_mesh.mesh.radius)
	particle_mesh.get_surface_override_material(0).albedo_color = color
	
	_point_mesh = PointMesh.new()
	unshaded_material.use_point_size = true
	unshaded_material.point_size = 1
	
	_point_mesh.surface_set_material(0, unshaded_material)
	
	# _box_mesh = BoxMesh.new()
	# _box_mesh.size = Vector3(particle_radius, particle_radius, particle_radius)
	# _box_mesh.surface_set_material(0, unshaded_material)
	# to reduce the polygons

	# longitude is shifted by 90° in spawn_emitter_at
	longitude += 90

	var lat_rad := deg_to_rad(latitude)
	var lon_rad := deg_to_rad(longitude)
 
	initial_norm = Vector3(
		cos(lat_rad) * cos(lon_rad) * 5,
		sin(lat_rad) * 5,
		cos(lat_rad) * sin(lon_rad) * 5
	).normalized()
	norm = initial_norm
	update_norm()

	init_multimesh(mm_emitter)
	add_child(mm_emitter)
	mm_emitter.global_position = Vector3(0, 0, 0)
	# mm_emitter.basis = Util.orbital_basis
	# for top_level = true
	# mm_emitter.global_position = global_position
	
	# norm = norm.rotated(Vector3.RIGHT, deg_to_rad(longitude))
	update_acceleration()

	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func init_multimesh(multi_mesh_istance: MultiMeshInstance3D) -> void:
	# init multimesh object
	multi_mesh_istance.multimesh = MultiMesh.new()
	multi_mesh_istance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_emitter.multimesh.use_colors = true
	mm_emitter.multimesh.use_custom_data = true
	# init instance count(max particles) to an arbitrary number bc yes lol
	multi_mesh_istance.multimesh.instance_count = 1000
	multi_mesh_istance.multimesh.visible_instance_count = 0 # 0 so no particles are shown at the beginning
	# setting particle radius
	multi_mesh_istance.multimesh.mesh = _point_mesh

	multi_mesh_istance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multi_mesh_istance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	multi_mesh_istance.lod_bias = 0.0001
	multi_mesh_istance.ignore_occlusion_culling = true
	# only the second layer is used for the particles, so that MiniCamera doesn't render them
	multi_mesh_istance.set_layer_mask_value(1, false)
	multi_mesh_istance.set_layer_mask_value(2, true)
	mm_emitter.top_level = true
	# mm_emitter.global_position = Vector3(0, 0, 0)
	
func _physics_process(_delta: float) -> void:
	if not visible:
		return
	## Raycasting-based solution
	# var space_state := get_world_3d().direct_space_state
	# var light_pos := light_source.global_position
	# var emitter_pos := global_position
	# var query := PhysicsRayQueryParameters3D.create(light_pos, emitter_pos)
	# query.collide_with_areas = true	
	# query.exclude = [$Particle/ParticleArea.get_rid()]
	# var _result := space_state.intersect_ray(query)
	# if not is_lit and result.is_empty():
	# 	#enabled = true
	# 	#print("LIT\n")
	# 	is_lit = true
	# 	$Particle.get_surface_override_material(0).albedo_color = Color.WHITE
	# elif is_lit and not result.is_empty():
	# 	is_lit = false
	# 	#print("NOT LIT\n"+str(result))
	# 	$Particle.get_surface_override_material(0).albedo_color = Color.RED

	## Dotproduct-based solution
	is_lit = is_lit_math()
	if is_lit:
		particle_mesh.get_surface_override_material(0).albedo_color = color
	else:
		particle_mesh.get_surface_override_material(0).albedo_color = color.darkened(0.5) # shading the color


## Returns whether the emitter is lit by the sun or not, 
## based on sun inclination and direction angle, comet inclination and comet current rotation angle
## FIXME: probably this doesn't work properly
func is_lit_math() -> bool:
	var comet_basis: Basis = get_parent().global_transform.basis
	var global_space_normal: Vector3 = comet_basis * norm
	global_space_normal = global_space_normal.normalized().rotated(Vector3.LEFT, deg_to_rad(Util.sun_direction + 90))
	var result: float = (Util.sun_direction_vector).dot(global_space_normal)
	result = (-Util.sun_direction_vector).dot(norm)
	is_lit = result > 0
	return is_lit

func is_lit_math2(_n_step: int, _angle_per_step: float, _normal: Vector3) -> bool:
	var comet_basis: Basis = get_parent().global_transform.basis
	comet_basis = comet_basis * comet_basis.rotated(Vector3.UP, deg_to_rad(_n_step * _angle_per_step))
	var global_space_normal: Vector3 = _normal.normalized().rotated(Vector3.LEFT, deg_to_rad(Util.sun_direction + 90))
	# var global_space_normal: Vector3 = _normal.normalized()
	var result: float = (Util.sun_direction_vector).dot(global_space_normal)
	result = (-Util.sun_direction_vector).dot(_normal)
	is_lit = result > 0
	return is_lit


#region Simulation related
## Instant simulation of n_steps with angle_per_step each step.
## First, it computes when each particle spawns, then based on that it computes the final position of each particle.
## TODO: fare in modo che instant_simulation supporti posizione di cometa e sole variabile -> ciò dipende da due variabili globali: 
## get_parent().global_transform.origin e Util.sun_direction_vector
## jpl_import: if set, it contains a dictionary with the JPL data to use for the simulation. Simulation data includes:
## "date" (String, format "YYYY-MM-DD"), "time" (String, format "HH:MM"),
## "right_ascension" (String, format "HH MM SS.SS"), "declination" (String, format "DD MM SS.S")
## It's in the form of {date:[...], time:[...], ...}
func instant_simulation(_n_steps: int, _angle_per_step: float, jpl_import: Dictionary = {}) -> void:
	mm_emitter.multimesh.instance_count = 0
	mm_emitter.multimesh.use_colors = true
	mm_emitter.multimesh.use_custom_data = false
	if density <= 0:
		return

	var particle_transforms: Array[Transform3D] = []
	var _normal_dirs: Array[Vector3] = []
	var time_alive2: Array[int] = []
	var mm_buffer: PackedFloat32Array = PackedFloat32Array()
	var is_jpl_import: bool = jpl_import.size() > 0
	# var start_comet_transform: Transform3D = get_parent().global_transform
	# var start_comet_inclination: float = Util.comet_inclination
	# var start_comet_direction: float = Util.comet_direction
	# var start_sun_inclination: float = Util.sun_inclination
	# var start_sun_direction: float = Util.sun_direction

	# var total_space_cumulative: Array[float] = []
	# for each steps i, compute position of ith particle (if it's spawned)
	# ie: at step 40(out of 100) the emitter is lit and thus spawns a particle -> compute that particle position at the end of simulation (step 100)
	for i in range(_n_steps):
		if is_jpl_import:
			# TODO: this
			# var ith_ra := jpl_import["right_ascension"][i]
			# var ith_dec := jpl_import["declination"][i]
			# get_tree().call_group("comet", "update_comet_inc_rotation", Util.ra_dec_to_inclination(ith_ra, ith_dec))
			# get_tree().call_group("comet", "update_comet_dir_rotation", Util.ra_dec_to_direction(ith_ra, ith_dec))
			# get_tree().call_group("sun", "update_sun_inc_rotation", jpl_import["sun_inclination"][i])
			# get_tree().call_group("sun", "update_sun_dir_rotation", jpl_import["sun_direction"][i])
			# update acceleration
			# update fov
			pass
		var comet_basis: Basis = get_parent().global_transform.basis
		comet_basis = comet_basis * Basis(Vector3.UP, deg_to_rad((i + 1) * _angle_per_step))
		var _normal := update_norm2(initial_norm, comet_basis)
		# continue to next 
		if not is_lit_math2(i, _angle_per_step, _normal):
			continue
		_normal_dirs.append(_normal)
		time_alive2.append(i) # time alive is the number of steps left until the end of simulation

		# _n_steps - i so that it correctly defines the time the ith particle has been alive (ie: i=0, nsteps=100 -> particle alive for 100)
		# just "i" would've worked just fine but it wasn't logically correct
		var ith_transform := _accelerate_particle2(_n_steps - i, _normal)
		particle_transforms.append(ith_transform)
		# The central trajectory counts as one of the particles emitted per step.
		_append_data_to_mm_buffer(mm_buffer, ith_transform, color)
		if diffusion <= 0:
			for _particle_index in range(1, density):
				_append_data_to_mm_buffer(mm_buffer, ith_transform, color)

	print("buffer_size: %d" % mm_buffer.size())
	# numerical integration to reconstruct diffusion particles
	if density > 1 and diffusion > 0:
		@warning_ignore("integer_division")
		var SUBSTEPS: int = clamp(_n_steps / 10, 10, 25)
		for idx in range(particle_transforms.size()):
			var final_t := particle_transforms[idx]
			var age := _n_steps - time_alive2[idx] # however you tracked “time_alive2” per particle
			var normal := _normal_dirs[idx] # same for your _normal passed in

			# approximate arc‐length via sampling:
			var travelled_space := 0.0
			var prev_pos := Vector3.ZERO
			for s in range(1, SUBSTEPS + 1):
				@warning_ignore("integer_division")
				var sub_age := int(age * s / SUBSTEPS)
				var sub_t := _accelerate_particle2(sub_age, normal)
				var pos := sub_t.origin
				travelled_space += (pos - prev_pos).length()
				prev_pos = pos

			# now generate small cloud around the *true* path‐length:
			var cloud := _generate_diffusion_particles2(travelled_space, final_t.origin)
			for p in cloud:
				_append_data_to_mm_buffer(mm_buffer, p, color)
	# print("mm_buffer size: %d" % mm_buffer.size())
	@warning_ignore("integer_division")
	mm_emitter.multimesh.instance_count = mm_buffer.size() / 16 # 16 is the number of floats per instance (12 for transform, 4 for color)
	# print("Emitter %d multimesh instance count: %d" % [jet_id, mm_emitter.multimesh.instance_count])
	mm_emitter.multimesh.visible_instance_count = -1
	mm_emitter.multimesh.set_buffer(mm_buffer)
	if is_jpl_import:
		# reset comet and sun to initial position
		# TODO: this
		# get_tree().call_group("comet", "update_comet_inc_rotation", start_comet_inclination)
		# get_tree().call_group("comet", "update_comet_dir_rotation", start_comet_direction)
		# get_tree().call_group("sun", "update_sun_inc_rotation", start_sun_inclination)
		# get_tree().call_group("sun", "update_sun_dir_rotation", start_sun_direction)
		pass
func _accelerate_particle2(time_alive2: int, _normal_dir: Vector3) -> Transform3D:
	var new_basis := Util.orbital_basis
	var time_passed: float = time_alive2 * Util.jet_rate * 60.0

	var global_initial_velocity: Vector3 = _normal_dir * speed
	var sun_accel_magnitude: float = 0.5 * a * (time_passed ** 2)

	var local_velocity := global_initial_velocity * new_basis
	var local_displacement := Vector3(local_velocity * time_passed)
	local_displacement.x -= sun_accel_magnitude

	var global_displacement: Vector3 = local_displacement * new_basis.transposed()

	# qui la particella parte davvero dalla posizione dell’emitter
	var scaled_displacement := global_displacement / Util.scale
	var final_global_position: Vector3 = global_position + scaled_displacement

	global_positions.append(final_global_position)
	var final_global_transform := Transform3D(new_basis, final_global_position)
	return final_global_transform
	
func _generate_diffusion_particles2(travelled_space: float, particle_origin: Vector3) -> Array[Transform3D]:
	if density <= 1:
		return []
	var diffusion_particles: Array[Transform3D] = []
	var pc_radius := travelled_space * (diffusion / 100) * randf() # pointcloud radius based on total space travelled by the particle and diffusion factor
	# print("Radius:%f" % pc_radius)
	for i in range(density - 1):
		# generating a random position around the particle
		var new_pos := Util.generate_gaussian_vector(0, 1, pc_radius)
		diffusion_particles.append(Transform3D(Basis(), particle_origin + new_pos))
	return diffusion_particles

## Append data to a multimesh buffer. https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-multimesh-set-buffer
func _append_data_to_mm_buffer(buffer: PackedFloat32Array, transf: Transform3D, _color: Color) -> void:
	# basis.x.x, basis.y.x, basis.z.x, origin.x, basis.x.y, basis.y.y, basis.z.y, origin.y, basis.x.z, basis.y.z, basis.z.z, origin.z).
	buffer.append(transf.basis.x.x)
	buffer.append(transf.basis.y.x)
	buffer.append(transf.basis.z.x)
	buffer.append(transf.origin.x)
	buffer.append(transf.basis.x.y)
	buffer.append(transf.basis.y.y)
	buffer.append(transf.basis.z.y)
	buffer.append(transf.origin.y)
	buffer.append(transf.basis.x.z)
	buffer.append(transf.basis.y.z)
	buffer.append(transf.basis.z.z)
	buffer.append(transf.origin.z)
	buffer.append(_color.r)
	buffer.append(_color.g)
	buffer.append(_color.b)
	buffer.append(_color.a)
func tick_optimized(_n_iteration: int) -> void:
	if density <= 0:
		return
	# moving each particle
	for i in range(0, mm_emitter.multimesh.visible_instance_count, density):
		## Accelerate the central particle of each emission group.
		_accelerate_particle(i)
		_generate_diffusion_particles(i)
		
	# if _is_lit:
	# whether to spawn a new particle or not
	if is_lit_math():
		var first_id := mm_emitter.multimesh.visible_instance_count
		if first_id + density <= mm_emitter.multimesh.instance_count:
			_spawn_particle(first_id)
			mm_emitter.multimesh.visible_instance_count = first_id + density
	update_norm()


## Update the position of the i-th particle in the multimesh by accelerating it according to the formula in the Vincent's paper.
## The formula is: X = V * t - 1/2 * a * t
## Y= V * t 	Z= V * t
func _accelerate_particle(i: int) -> void:
	# --- 1. Get Particle-Specific Data ---
	var _normal_dir_as_color := mm_emitter.multimesh.get_instance_custom_data(i) as Color
	var _normal_dir := Vector3(_normal_dir_as_color.r, _normal_dir_as_color.g, _normal_dir_as_color.b)
	var new_basis := Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
	new_basis = Util.orbital_basis
	var time_passed: float = time_alive[i] * Util.jet_rate * 60.0
	time_alive[i] += 1
	# --- 2. Calculate Initial Global Velocity and Acceleration Term  in the global space ---
	var global_initial_velocity: Vector3 = _normal_dir * speed
	var sun_accel_magnitude: float = 0.5 * a * (time_passed ** 2)
	# --- 3. Change of Basis ---
	var local_velocity := global_initial_velocity * new_basis
	# --- 4. Calculate Displacement in the new space  ---
	# X = V * t - 1/2 * a * t^2 	Y= V * t 	Z= V * t
	var local_displacement := Vector3(local_velocity * time_passed)
	local_displacement.x -= sun_accel_magnitude
	# --- 5. Convert Local Displacement back to a Global Vector ---
	# This gives us a single displacement vector in the main world space.
	# .transposed() is used to convert the local displacement back to the global space.
	var global_displacement: Vector3 = local_displacement * new_basis.transposed()
	# --- 6. Calculate Final Global Position ---
	var scaled_displacement := global_displacement / Util.scale
	var final_global_position: Vector3 = initial_positions[i] + scaled_displacement

	total_space[i] += (final_global_position - global_positions[i]).length()
	global_positions[i] = final_global_position

	var final_global_transform := Transform3D(new_basis, final_global_position)

	# `set_instance_transform` requires the transform to be LOCAL to the MultiMeshInstance3D node.
	# We convert our desired global transform into a local one.
	# var instance_local_transform := mm_global_inverse * final_global_transform
	var instance_local_transform := final_global_transform
	mm_emitter.multimesh.set_instance_transform(i, instance_local_transform)
## TODO: refactor so that there's only one function that accelerates the particle

## Generate the remaining particles of an emission group around its central particle.
## It doesn't update multimesh.visible_instance_count!
func _generate_diffusion_particles(i: int) -> void:
	if density <= 1:
		return # no diffusion particles to generate
	var center_particle := mm_emitter.multimesh.get_instance_transform(i)
	var center_particle_color := mm_emitter.multimesh.get_instance_color(i)
	var pc_radius := total_space[i] * (diffusion / 100) * randf() # pointcloud radius based on total space travelled by the particle and diffusion factor
	# TODO: maybe use compute shader to generate the particles around the center particle
	for j in range(1, density):
		# generating a random position around the particle
		var new_pos := Util.generate_gaussian_vector(0, 1, pc_radius)
		mm_emitter.multimesh.set_instance_transform(i + j, Transform3D(Basis(), center_particle.origin + new_pos))
		mm_emitter.multimesh.set_instance_color(i + j, center_particle_color)

## Spawns a new particle group in the multimesh at the current emitter position.
## It doesn't update multimesh.visible_instance_count!
func _spawn_particle(first_id: int) -> void:
	var _initial_position := global_position
	var initial_transform := Transform3D(Basis(Vector3.UP, Vector3.LEFT, Vector3.FORWARD), Vector3.ZERO)
	for particle_offset in range(density):
		var particle_id := first_id + particle_offset
		mm_emitter.multimesh.set_instance_color(particle_id, color)
		mm_emitter.multimesh.set_instance_custom_data(particle_id, Color(norm.x, norm.y, norm.z))
		mm_emitter.multimesh.set_instance_transform(particle_id, initial_transform)
		time_alive.append(0)
		global_positions.append(_initial_position)
		initial_positions.append(_initial_position)
		normal_dirs.append(norm)
		particle_speeds.append(speed)
		total_space.append(0)

## Computes radiation-pressure acceleration and beta with Qpr = 1.
## Optical albedo is not part of this calculation.
func update_acceleration() -> void:
	var values := Util.calculate_dust_radiation(
		Util.particle_diameter, Util.particle_density, Util.sun_comet_distance)
	if values.is_empty():
		a = 0.0
		Util.accel_val_line_edit.text = "N/A"
		Util.beta_val_line_edit.text = "N/A"
		return
	a = float(values["acceleration"])
	Util.accel_val_line_edit.text = String.num(a, 10)
	Util.beta_val_line_edit.text = String.num(float(values["beta"]), 10)
	if Util.PRINT_UPDATE_METHOD: print("Acceleration: %.10f m/s²" % a)

func update_initial_norm(_lat: float, _long: float) -> void:
	var lat_rad := deg_to_rad(_lat)
	var lon_rad := deg_to_rad(_long)
	initial_norm = Vector3(
		cos(lat_rad) * cos(lon_rad) * 5,
		sin(lat_rad) * 5,
		cos(lat_rad) * sin(lon_rad) * 5
	).normalized()
	norm = initial_norm
	update_norm()
func update_norm() -> void:
	var rotation_matrix: Basis = get_parent().global_transform.basis
	norm = initial_norm * rotation_matrix.inverse()
	norm = norm.normalized()
	pass
## update_norm that doesn't use global variables. It takes a vector3 and a basis as parameters.
## It returns a normal vector3 that is normalized and transformed by the inverse of the basis.
func update_norm2(v: Vector3, b: Basis) -> Vector3:
	var result := (v * b.inverse())
	return result.normalized()

func set_number_particles(num: int) -> void:
	num_particles = num * maxi(density, 0)
	mm_emitter.multimesh.instance_count = num_particles

# Cleanup methods
func reset_particles() -> void:
	for particle in particles_alive:
		particle.queue_free()
	particles_alive.clear()
func reset_multimesh() -> void:
	mm_emitter.multimesh.instance_count = 0
	mm_emitter.multimesh.visible_instance_count = 0
	mm_emitter.multimesh.use_custom_data = true
	mm_emitter.multimesh.use_colors = true
	total_space.clear()
	global_positions.clear()
	initial_positions.clear()
	normal_dirs.clear()
	particle_speeds.clear()
	time_alive.clear()
func destroy_multimesh() -> void:
	mm_emitter.queue_free()
#endregion Simulation related

###################################################################################
# Update methods called when sanitized_edit.sanitized_edit_focus_exited is emitted
# Connection of signals is done in JetTable._on_add_jet_entry_btn_pressed
###################################################################################
#region update methods
## updating the emitter position (and mesh size) on a sphere of radius "radius"
## called when the comet is resized
func update_position(radius: float) -> void:
	var new_pos := Util.latlon_to_vector3(latitude, longitude, radius)

	# the particle mesh is 1/25 of the comet mesh, chosen arbitrarly
	particle_mesh.mesh.radius = radius * (1.0 / 25)
	particle_mesh.mesh.height = particle_mesh.mesh.radius * 2
	$ParticleMesh/ParticleArea/ParticleShape.shape.set_radius(particle_mesh.mesh.radius)

	position = new_pos

	# riallinea anche la normale del jet
	update_initial_norm(latitude, longitude)
	update_norm()
	
func update_speed(_speed: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated speed:%f"%_speed)
	speed = _speed
	pass
func update_lat(lat: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated lat:%f"%lat)
	latitude = lat
	var new_pos := Util.latlon_to_vector3(latitude, longitude, Util.comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func update_long(long: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated long:%f"%long)
	longitude = long + 90
	var new_pos := Util.latlon_to_vector3(latitude, longitude, Util.comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func update_dens(_density: float) -> void:
	density = maxi(roundi(_density), 1)
	if Util.PRINT_UPDATE_METHOD: print("Updated particles per step:%d" % density)
	pass
func update_diff(_diffusion: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated diffusion:%f"%_diffusion)
	diffusion = _diffusion
	pass
func update_color(_color: Color) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated albedo:%s"%str(_color))
	color = _color
#endregion update methods


func tick() -> void:
	# trigger tick() on every particles alive
	for particle in particles_alive:
		particle.tick()
	# then spawn a new particle if needed
	if is_lit and particles_alive.size() < max_particles:
		var particle := particle_scene.instantiate() as Particle
		# particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		particle.top_level = true
		particle.normal_direction = norm
		particle.enabled = true
		particle.time_to_live = 10
		particle.color = color
		add_child(particle)
		particle.global_position = self.global_position
		particle.add_to_group("particle")
		particles_alive.append(particle)
	update_norm()
