# res://singletons/ApiClient.gd
extends Node

signal request_failed(detail: String)

const BASE_URL := "http://127.0.0.1:8000"

func get_player_status(p_id: String) -> Dictionary:
	return await _http_get("/player/status?player_id=" + p_id.uri_encode())

func start_interaction(p_id: String, npc_id: String) -> Dictionary:
	return await _http_post("/interaction/start", {"player_id": p_id, "npc_id": npc_id})

func send_message(p_id: String, npc_id: String, message: String) -> Dictionary:
	return await _http_post("/interaction/message", {"player_id": p_id, "npc_id": npc_id, "message": message})

func end_interaction(p_id: String, npc_id: String) -> Dictionary:
	return await _http_post("/interaction/end", {"player_id": p_id, "npc_id": npc_id})

func get_report(p_id: String) -> Dictionary:
	return await _http_post("/interaction/report", {"player_id": p_id})

func _http_get(path: String) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	var err = http.request(BASE_URL + path)
	if err != OK:
		http.queue_free()
		return {"error": true}
	var res = await http.request_completed
	http.queue_free()
	
	var body_bytes: PackedByteArray = res[3]
	var parsed = JSON.parse_string(body_bytes.get_string_from_utf8())
	if parsed is Dictionary:
		return parsed
	return {"error": true}

func _http_post(path: String, body: Dictionary) -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)
	var json_str = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	var err = http.request(BASE_URL + path, headers, HTTPClient.METHOD_POST, json_str)
	if err != OK:
		http.queue_free()
		return {"error": true}
	var res = await http.request_completed
	http.queue_free()
	
	var code: int = res[1]
	var body_bytes: PackedByteArray = res[3]
	var parsed = JSON.parse_string(body_bytes.get_string_from_utf8())
	if parsed is Dictionary:
		if code >= 400:
			var detail = parsed.get("detail", "HTTP Error %d" % code)
			request_failed.emit(detail)
			return {"error": true, "code": code, "detail": detail}
		return parsed
	return {"error": true}
