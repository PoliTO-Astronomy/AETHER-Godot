@tool
extends Node

## Preview only the scene being edited; never make the HUD autoload a tool script.
@export_enum("Settings", "Model", "Help", "Credits") var editor_page := 0:
	set(value):
		editor_page = value
		if Engine.is_editor_hint() and is_inside_tree():
			call_deferred("_preview_page")

func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_preview_page")

func _preview_page() -> void:
	if not Engine.is_editor_hint():
		return
	var hud := get_parent()
	if hud != EditorInterface.get_edited_scene_root():
		return
	var groups := ["settings_tab", "model_tab", "help_tab", "credits_tab"]
	for node in hud.find_children("*", "", true, false):
		for index in range(groups.size()):
			if node.is_in_group(groups[index]) and (node is CanvasItem or node is CanvasLayer):
				node.visible = index == editor_page
	hud.get_node("Body/ModelPanel/Navbar").current_tab = editor_page
	hud.get_node("SectionCollapseControls").visible = editor_page == 1
	hud.get_node("FullscreenViewerControls").visible = editor_page == 1
