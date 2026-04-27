@tool
extends Node

const URL = "http://localhost:1234/v1/chat/completions"

func generate_plan(prompt, context, error, temperature):
	if not is_inside_tree():
		printerr("generate_plan called but the node is not inside the tree!")
		return ""

	var http = HTTPRequest.new()
	add_child(http)
	await http.ready

	var repair = "" if error == "" else "\nError: " + error

	var body = {
		"model": "google/gemma-4-e4b",
		"messages": [
			{"role": "system", "content": "Return ONLY JSON array"},
			{"role": "user", "content": prompt + repair}
		],
		"temperature": temperature
	}

	var err = http.request(URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		printerr("[LLM] HTTPRequest failed to start, error code: ", err)
		return ""

	var result = await http.request_completed
	# result is [result_code, response_code, headers, body]
	if result.size() < 4:
		printerr("[LLM] HTTPRequest did not return a valid result tuple: ", result)
		return ""

	var body_bytes = result[3]
	var body_text = ""
	# In Godot 4, buffer is PackedByteArray
	if body_bytes is PackedByteArray:
		body_text = body_bytes.get_string_from_utf8()
	elif typeof(body_bytes) == TYPE_STRING:
		body_text = body_bytes
	else:
		printerr("[LLM] Response body not in expected format: ", body_bytes)
		return ""

	print("[LLM] raw body_text:", body_text)

	# Try to parse JSON
	var json = JSON.new()
	var json_err = json.parse(body_text)
	if json_err != OK:
		printerr("[LLM] JSON parse error:", json_err, " body:", body_text)
		# Return the raw body_text as a fallback (controller will try to extract JSON array)
		return body_text

	var data = json.data
	print("[LLM] parsed data:", data)

	# If the API returns OpenAI-style choices, extract content
	if typeof(data) == TYPE_DICTIONARY and data.has("choices"):
		var choices = data["choices"]
		if choices.size() > 0 and typeof(choices[0]) == TYPE_DICTIONARY:
			# Try to extract message.content or text
			if choices[0].has("message") and typeof(choices[0]["message"]) == TYPE_DICTIONARY and choices[0]["message"].has("content"):
				var content = choices[0]["message"]["content"]
				print("[LLM] extracted content:", content)
				return content
			elif choices[0].has("text"):
				print("[LLM] extracted text:", choices[0]["text"])
				return choices[0]["text"]
	# If the response itself is a JSON array (the model returned it directly), return stringified array
	if typeof(data) == TYPE_ARRAY:
		var s = JSON.stringify(data)
		print("[LLM] returning JSON array string:", s)
		return s

	# Fallback: return the raw body_text
	print("[LLM] returning fallback body_text")
	return body_text
