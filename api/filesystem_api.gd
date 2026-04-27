@tool
extends Node

# Simple filesystem listing helper
func list_dir(path: String):
	var da = DirAccess.open(path)
	if not da:
		return {}
	var dirs = []
	var files = []
	da.list_dir_begin()
	var entry = da.get_next()
	while entry != "":
		if da.current_is_dir():
			dirs.append(entry)
		else:
			files.append(entry)
		entry = da.get_next()
	da.list_dir_end()
	return {"dirs": dirs, "files": files}
