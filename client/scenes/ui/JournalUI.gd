# res://scenes/ui/JournalUI.gd
extends CanvasLayer

@onready var close_button: Button = $PanelContainer/Margin/VBoxContainer/Header/CloseButton
@onready var level_num_label: Label = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/LeftCard/LevelHeader/LevelNumLabel
@onready var overall_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/LeftCard/OverallProgressBar
@onready var clarity_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/ClarityBar
@onready var empathy_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/EmpathyBar
@onready var politeness_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/PolitenessBar
@onready var expression_bar: ProgressBar = $PanelContainer/Margin/VBoxContainer/TabContainer/Profile/HBoxSplit/RightBars/ExpressionBar

@onready var npc_button_vbox: VBoxContainer = $"PanelContainer/Margin/VBoxContainer/TabContainer/People Notebook/LeftList/ScrollContainer/NpcButtonVBox"
@onready var notebook_text: RichTextLabel = $"PanelContainer/Margin/VBoxContainer/TabContainer/People Notebook/RightPage/NotebookText"

@onready var report_text: RichTextLabel = $"PanelContainer/Margin/VBoxContainer/TabContainer/Growth Report/ReportText"
@onready var refresh_button: Button = $"PanelContainer/Margin/VBoxContainer/TabContainer/Growth Report/RefreshButton"

var _journal_entries: Array = []
var _selected_npc_index: int = -1

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_report_pressed)
	PlayerStore.player_data_updated.connect(_update_profile)

func toggle() -> void:
	visible = not visible
	if visible:
		_update_profile()
		_fetch_journal_data()

func _update_profile() -> void:
	level_num_label.text = "Lv. " + str(PlayerStore.level)
	overall_bar.value = PlayerStore.xp_progress * 100.0
	
	var vec = PlayerStore.skill_vector
	clarity_bar.value = vec.get("clarity", 0.5) * 100.0
	empathy_bar.value = vec.get("empathy", 0.5) * 100.0
	politeness_bar.value = vec.get("politeness", 0.5) * 100.0
	expression_bar.value = vec.get("expression", 0.5) * 100.0

func _fetch_journal_data() -> void:
	var res = await ApiClient.get_player_status(PlayerStore.player_id)
	if res.has("journal_entries"):
		_journal_entries = res.get("journal_entries", [])
		_render_people_notebook()

func _render_people_notebook() -> void:
	for child in npc_button_vbox.get_children():
		child.queue_free()
		
	if _journal_entries.size() == 0:
		notebook_text.text = "[i]No people encountered yet. Explore the neighborhood to meet locals.[/i]"
		return
		
	for i in range(_journal_entries.size()):
		var entry: Dictionary = _journal_entries[i]
		var btn = Button.new()
		btn.text = entry.get("name", "Unknown")
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(func(): _select_npc(i))
		npc_button_vbox.add_child(btn)
		
	if _selected_npc_index < 0 or _selected_npc_index >= _journal_entries.size():
		_select_npc(0)
	else:
		_select_npc(_selected_npc_index)

func _select_npc(idx: int) -> void:
	_selected_npc_index = idx
	if idx < 0 or idx >= _journal_entries.size():
		return
		
	var entry: Dictionary = _journal_entries[idx]
	var txt = ""
	txt += "[b][font_size=20]" + str(entry.get("name", "Unknown")).to_upper() + "[/font_size][/b]\n"
	txt += "[color=#555555]Role:[/color] " + str(entry.get("role", "Stranger")) + "\n"
	txt += "[color=#555555]Usually Seen:[/color] " + str(entry.get("usual_location", "Main Street")) + "\n"
	txt += "[color=#555555]Relationship Status:[/color] " + str(entry.get("relationship_tier", "Noticed")) + "\n\n"
	
	txt += "[b]Known Through:[/b]\n• " + str(entry.get("known_through", "In-person encounter")) + "\n\n"
	
	var connections: Array = entry.get("connections", [])
	txt += "[b]Connections:[/b]\n"
	if connections.size() > 0:
		for conn in connections:
			txt += str(conn) + "\n"
	else:
		txt += "[i]None discovered yet.[/i]\n"
	txt += "\n"
	
	var notes = entry.get("personality_notes", "")
	if notes != "":
		txt += "[b]About & Observations:[/b]\n" + str(notes) + "\n\n"
		
	var facts: Array = entry.get("discovered_facts", [])
	if facts.size() > 0:
		txt += "[b]Discovered Facts:[/b]\n"
		for fact in facts:
			txt += "• " + str(fact) + "\n"
			
	notebook_text.text = txt

func _on_refresh_report_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	report_text.text = "[i]Analyzing conversation history and generating report...[/i]"
	refresh_button.disabled = true
	
	var res = await ApiClient.get_report(PlayerStore.player_id)
	refresh_button.disabled = false
	
	if res.has("error"):
		report_text.text = "[color=red]Failed to generate report: " + str(res.get("detail", "Server error")) + "[/color]"
		return
		
	var summary = res.get("summary", "")
	var rec = res.get("recommendation", "")
	report_text.text = "[b]Growth Analysis:[/b]\n" + summary + "\n\n[b]Recommendation:[/b]\n" + rec

func _on_close_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	visible = false
