# res://scenes/ui/JournalUI.gd
extends CanvasLayer

@onready var close_button: Button = $BookContainer/CloseButton
@onready var prev_button: Button = $BookContainer/PrevButton
@onready var next_button: Button = $BookContainer/NextButton
@onready var page_indicator: Label = $BookContainer/PageIndicator

@onready var book_spread: Control = $BookContainer/BookSpread
@onready var left_page_text: RichTextLabel = $BookContainer/BookSpread/LeftPage/Margin/LeftText
@onready var right_page_text: RichTextLabel = $BookContainer/BookSpread/RightPage/Margin/RightText

var _journal_entries: Array = []
var _current_pair_index: int = 0
var _is_animating: bool = false

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	_setup_button_hover(close_button)
	_setup_button_hover(prev_button)
	_setup_button_hover(next_button)

func _setup_button_hover(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			if AudioManager and AudioManager.has_method("play_hover"):
				AudioManager.play_hover()
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)
	)

func toggle() -> void:
	visible = not visible
	if visible:
		_fetch_journal_data()

func _fetch_journal_data() -> void:
	var res = await ApiClient.get_player_status(PlayerStore.player_id)
	if res.has("journal_entries"):
		_journal_entries = res.get("journal_entries", [])
		_current_pair_index = 0
		_render_spread()

func _render_spread() -> void:
	var total_entries = _journal_entries.size()
	
	if total_entries == 0:
		left_page_text.text = "[center][color=#3D2B1F][i]\n\n\nNo people encountered yet.\n\nExplore the neighborhood to meet locals and discover their stories.[/i][/color][/center]"
		right_page_text.text = "[center][color=#3D2B1F][i]\n\n\nYour notebook is ready.\n\nKey information & observations will automatically appear here.[/i][/color][/center]"
		page_indicator.text = "Page 1 of 1"
		prev_button.disabled = true
		next_button.disabled = true
		prev_button.modulate.a = 0.35
		next_button.modulate.a = 0.35
		return

	var max_pairs = int(ceil(float(total_entries) / 2.0))
	if _current_pair_index < 0:
		_current_pair_index = 0
	if _current_pair_index >= max_pairs:
		_current_pair_index = max_pairs - 1

	var left_idx = _current_pair_index * 2
	var right_idx = left_idx + 1

	left_page_text.text = _format_npc_page(_journal_entries[left_idx], left_idx + 1)

	if right_idx < total_entries:
		right_page_text.text = _format_npc_page(_journal_entries[right_idx], right_idx + 1)
	else:
		right_page_text.text = "[center][color=#7C624E]\n\n\n\n~ Page Intentionally Left Blank ~[/color][/center]"

	page_indicator.text = "Pages %d-%d of %d" % [left_idx + 1, min(right_idx + 1, total_entries), total_entries]
	prev_button.disabled = (_current_pair_index == 0)
	next_button.disabled = (_current_pair_index >= max_pairs - 1)
	prev_button.modulate.a = 0.35 if prev_button.disabled else 1.0
	next_button.modulate.a = 0.35 if next_button.disabled else 1.0

func _format_npc_page(entry: Dictionary, page_num: int) -> String:
	var txt = ""
	txt += "[b][font_size=18][color=#1E150C]" + str(entry.get("name", "Unknown")).to_upper() + "[/color][/font_size][/b]\n"
	txt += "[color=#5C4432]Role:[/color] [color=#1E150C]" + str(entry.get("role", "Stranger")) + "[/color]\n"
	txt += "[color=#5C4432]Location:[/color] [color=#1E150C]" + str(entry.get("usual_location", "Main Street")) + "[/color]\n"
	txt += "[color=#5C4432]Relationship:[/color] [b][color=#1E150C]" + str(entry.get("relationship_tier", "Noticed")) + "[/color][/b]\n"
	txt += "[color=#7C624E]Known Through: " + str(entry.get("known_through", "Encounter")) + "[/color]\n"
	txt += "[hr]\n"

	var connections: Array = entry.get("connections", [])
	if connections.size() > 0:
		txt += "[b][color=#3D2B1F]Connections:[/color][/b]\n"
		for conn in connections:
			txt += " [color=#5C4432]•[/color] [color=#1E150C]" + str(conn) + "[/color]\n"
		txt += "\n"

	var notes = entry.get("personality_notes", "")
	if notes != "":
		txt += "[b][color=#3D2B1F]Observations:[/color][/b]\n[color=#2C1F15]" + str(notes) + "[/color]\n\n"

	var facts: Array = entry.get("discovered_facts", [])
	if facts.size() > 0:
		txt += "[b][color=#3D2B1F]Discovered Facts:[/color][/b]\n"
		for fact in facts:
			txt += " [color=#5C4432]•[/color] [color=#1E150C]" + str(fact) + "[/color]\n"

	txt += "\n[right][color=#8C725E]p. " + str(page_num) + "[/color][/right]"
	return txt

func _animate_page_flip(forward: bool) -> void:
	if _is_animating:
		return
	_is_animating = true

	if AudioManager:
		AudioManager.play_click()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(book_spread, "modulate:a", 0.2, 0.15)
	tween.tween_property(book_spread, "scale", Vector2(0.96, 0.98), 0.15)
	await tween.finished

	if forward:
		_current_pair_index += 1
	else:
		_current_pair_index -= 1

	_render_spread()

	var tween_in = create_tween().set_parallel(true)
	tween_in.tween_property(book_spread, "modulate:a", 1.0, 0.15)
	tween_in.tween_property(book_spread, "scale", Vector2.ONE, 0.15)
	await tween_in.finished
	_is_animating = false

func _on_prev_pressed() -> void:
	if _current_pair_index > 0:
		_animate_page_flip(false)

func _on_next_pressed() -> void:
	var total_entries = _journal_entries.size()
	var max_pairs = int(ceil(float(total_entries) / 2.0))
	if _current_pair_index < max_pairs - 1:
		_animate_page_flip(true)

func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
