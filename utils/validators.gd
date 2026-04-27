@tool
extends Node

# Very small validator — extend as needed
func validate_commands(commands):
	if commands == null:
		return {"ok": false, "error": "No commands provided"}
	if typeof(commands) != TYPE_ARRAY:
		return {"ok": false, "error": "Commands must be a JSON array"}
	for c in commands:
		if typeof(c) != TYPE_DICTIONARY:
			return {"ok": false, "error": "Each command must be an object"}
		if not c.has("action"):
			return {"ok": false, "error": "Command missing action field: " + str(c)}
		# allow create_node for now
		if c["action"] == "create_node":
			if not (c.has("type") and c.has("name") and c.has("parent")):
				return {"ok": false, "error": "create_node requires type,name,parent"}
		# add more validations as needed
	return {"ok": true}
