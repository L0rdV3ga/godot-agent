@tool
extends Node

var api_script = preload("res://api/scene_api.gd")
var api = null
var editor_interface = null

func set_editor_interface(ei):
	editor_interface = ei
	api = api_script.new()
	if api and api.has_method("set_editor_interface"):
		api.set_editor_interface(editor_interface)

func dry_run(cmd):
	var parent_path = cmd.get("parent", "/root")
	# Use the api helper if available
	if api and api.has_method("_get_parent_node"):
		var p = api._get_parent_node(parent_path)
		if p == null:
			push_warning("Dry-run: Parent not found: " + parent_path)
			return false
		var name = cmd.get("name", "NewNode")
		# If p is a Node, use has_node with relative path; otherwise check by name
		if p.has_node(name):
			push_warning("Dry-run: Node already exists: " + name)
			return false
		print("[Action:create_node] dry_run OK for", cmd)
		return true
	# fallback: assume ok
	print("[Action:create_node] dry_run fallback OK for", cmd)
	return true

func execute(cmd):
	print("[Action:create_node] execute called with:", cmd)
	var type = cmd.get("type", "Node")
	var name = cmd.get("name", "NewNode")
	var parent = cmd.get("parent", "/root")
	# Ensure api is initialized
	if api == null:
		api = api_script.new()
		if api and api.has_method("set_editor_interface"):
			api.set_editor_interface(editor_interface)
	api.create_node(type, name, parent)
