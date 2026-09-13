extends Node2D

const PREFERENCES_PATH := "user://aether_preferences.cfg"
const DEFAULT_FOLDER_NAME := "Project Aether"

var config := ConfigFile.new()
var preferences := ConfigFile.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	preferences.load(PREFERENCES_PATH)
	_ensure_default_directory()

func save(filename: StringName) -> void:
	config.save(filename)
func load(filename: StringName) -> void:
	config = ConfigFile.new()
	config.load(filename)

## Opens every import/export dialog in the last directory used by the user.
## On first use, creates "Project Aether" inside the operating system Documents folder.
func prepare_file_dialog(dialog: FileDialog, suggested_file: String = "") -> void:
	var directory := get_default_directory()
	dialog.current_dir = directory
	dialog.current_file = suggested_file

## Stores the directory of the most recently imported or exported file.
func remember_file_directory(path: String) -> void:
	if path.is_empty():
		return
	var directory := path.get_base_dir()
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory):
		return
	preferences.set_value("files", "last_directory", directory)
	preferences.save(PREFERENCES_PATH)

func get_default_directory() -> String:
	var stored := str(preferences.get_value("files", "last_directory", ""))
	if not stored.is_empty() and DirAccess.dir_exists_absolute(stored):
		return stored
	return _ensure_default_directory()

func _ensure_default_directory() -> String:
	var documents := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents.is_empty():
		documents = OS.get_data_dir()
	var directory := documents.path_join(DEFAULT_FOLDER_NAME)
	if not DirAccess.dir_exists_absolute(directory):
		var error := DirAccess.make_dir_recursive_absolute(directory)
		if error != OK:
			push_warning("Unable to create the default Project Aether folder: %s" % directory)
			return documents
	return directory
