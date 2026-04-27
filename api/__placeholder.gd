@tool
extends Node

var editor_interface = null

func set_editor_interface(ei):
	editor_interface = ei
	api = api_script.new()
	if api and api.has_method("set_editor_interface"):
		api.set_editor_interface(editor_interface)
