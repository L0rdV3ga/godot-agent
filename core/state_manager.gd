@tool
extends Node

var editor_interface

func set_editor_interface(ei):
	editor_interface = ei

func collect_context():
	var context = {}
	if editor_interface == null:
		push_error("EditorInterface missing")
		return {"scene": {}, "filesystem": {}, "scripts": []}

	var root = editor_interface.get_edited_scene_root()
	if root == null:
		print("⚠️ No scene open")
		return {"scene": {}, "filesystem": {}, "scripts": []}

	context["scene"] = _serialize(root)

	var fs_api = preload("res://api/filesystem_api.gd").new()
	context["filesystem"] = fs_api.list_dir("res://")

	var scr_api = preload("res://api/scripts_api.gd").new()
	context["scripts"] = scr_api.list_scripts(root)

	return context

func _serialize(node):
	var data = {
		"name": node.name,
		"type": node.get_class(),
		"children": []
	}
	for c in node.get_children():
		data.children.append(_serialize(c))
	return data
