@tool
extends Node

var executor

func _init():
	var Executor = preload("res://core/action_executor.gd")
	executor = Executor.new()
	add_child(executor)

func set_editor_interface(ei):
	if executor and executor.has_method("set_editor_interface"):
		executor.set_editor_interface(ei)

func execute(command):
	if executor:
		executor.run(command)
	else:
		push_warning("No executor available to run command: " + str(command))
