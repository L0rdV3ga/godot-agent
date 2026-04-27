@tool
extends Node

var actions = {}
var editor_interface = null

func set_editor_interface(ei):
	editor_interface = ei
	# propagate to each loaded action (if they implement it)
	for name in actions.keys():
		var a = actions[name]
		if a and a.has_method("set_editor_interface"):
			a.set_editor_interface(editor_interface)

func _init():
	# Load all .gd actions from the actions folder (scripts), instantiate them, and keep references
	var dir = DirAccess.open("res://actions")
	if dir:
		dir.list_dir_begin()
		var entry = dir.get_next()
		while entry != "":
			if entry.ends_with(".gd"):
				var name = entry.get_basename()
				var script_res = load("res://actions/%s" % entry)
				if script_res:
					var inst = script_res.new()
					# if we already have an editor_interface (unlikely at init), give it to the action
					if inst and inst.has_method("set_editor_interface") and editor_interface:
						inst.set_editor_interface(editor_interface)
					actions[name] = inst
			entry = dir.get_next()
		dir.list_dir_end()

func run(cmd):
	print("[Executor] received command:", cmd)

	if not cmd or typeof(cmd) != TYPE_DICTIONARY:
		push_warning("Invalid command (not a dictionary): " + str(cmd))
		return

	if cmd.has("action") and actions.has(cmd["action"]):
		var action_inst = actions[cmd["action"]]
		print("[Executor] running action:", cmd["action"])
		# Dry run if implemented
		if action_inst and action_inst.has_method("dry_run"):
			var ok = action_inst.dry_run(cmd)
			print("[Executor] dry_run result for", cmd, "=>", ok)
			if not ok:
				push_warning("Dry run failed for action: " + str(cmd))
				return
		# Logging
		var Logger = preload("res://utils/logger.gd")
		var logger = Logger.new()
		logger.log_action(cmd["action"], cmd)
		# Execute
		if action_inst and action_inst.has_method("execute"):
			action_inst.execute(cmd)
			print("[Executor] finished action:", cmd["action"])
		else:
			push_warning("Action has no execute method: " + str(cmd))
	else:
		push_warning("Unknown action: " + str(cmd))
