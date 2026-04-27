@tool
extends Node

signal plan_ready(plan)

var llm
var router
var validator
var state
var editor_interface

const MAX_RETRIES := 3
const TEMPERATURES := [0.2, 0.1, 0.0]

func set_editor_interface(ei):
	editor_interface = ei
	# Propagate to subsystems if they already exist
	if state and state.has_method("set_editor_interface"):
		state.set_editor_interface(editor_interface)
	if router and router.has_method("set_editor_interface"):
		router.set_editor_interface(editor_interface)

func _ready():
	# Instantiate subsystems but DON'T assume editor_interface is set yet
	var LLMClient = preload("res://ai/llm_client.gd")
	llm = LLMClient.new()
	add_child(llm)

	var CommandRouter = preload("res://core/command_router.gd")
	router = CommandRouter.new()
	add_child(router)

	var Validator = preload("res://utils/validators.gd")
	validator = Validator.new()
	add_child(validator)

	var StateManager = preload("res://core/state_manager.gd")
	state = StateManager.new()
	add_child(state)
	# Do not call state.set_editor_interface here. Wait for set_editor_interface(ei)

func handle_user_prompt(prompt: String):
	print("PROMPT RECEIVED:", prompt)
	var context = state.collect_context()
	print("SCENE CONTEXT:", context)

	var attempt = 0
	var last_error = ""
	var plan_text = ""
	var plan_parsed = null

	while attempt < MAX_RETRIES:
		var temperature = TEMPERATURES[min(attempt, TEMPERATURES.size() - 1)]
		plan_text = await llm.generate_plan(prompt, context, last_error, temperature)
		print("[Controller] plan_text:", plan_text)

		if typeof(plan_text) != TYPE_STRING or plan_text == "":
			plan_parsed = null
		else:
			plan_parsed = _safe_parse(plan_text)
		print("[Controller] plan_parsed:", plan_parsed)

		var result = validator.validate_commands(plan_parsed)
		print("[Controller] validator result:", result)

		if result.get("ok", false):
			print("✅ VALID PLAN")
			emit_signal("plan_ready", plan_parsed)
			return

		last_error = result.get("error", "Unknown error")
		print("❌ RETRY:", last_error)

		attempt += 1

	push_error("Agent failed after retries")

func confirm_and_execute_plan(plan):
	_execute(plan)

func _safe_parse(text):
	if typeof(text) != TYPE_STRING or text == null:
		return null
	var start = text.find("[")
	var end = text.rfind("]")
	if start != -1 and end != -1:
		var substr = text.substr(start, end - start + 1)
		var j = JSON.new()
		var err = j.parse(substr)
		if err != OK:
			printerr("[Controller] _safe_parse JSON parse error:", err, " substr:", substr)
			return null
		return j.data
	return null

func _execute(commands):
	for cmd in commands:
		if router:
			router.execute(cmd)
		else:
			push_warning("No router available to execute command: " + str(cmd))
