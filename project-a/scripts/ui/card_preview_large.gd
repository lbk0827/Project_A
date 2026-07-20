extends Control

var art: TextureRect
var type_strip: ColorRect
var cost_label: Label
var name_label: Label
var keyword_label: Label
var type_label: Label
var body_label: RichTextLabel
var inspired_glow: Panel

func _ready():
	_bind_nodes()

func set_card(card: CardData, effective_cost: int = -1, active_stance := ""):
	_bind_nodes()
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_type_style(card.card_type)
	var art_path := _card_art_path(card)
	art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	cost_label.text = str(card.cost if effective_cost < 0 else effective_cost)
	name_label.text = card.display_name
	keyword_label.text = _type_header_text(card.card_type)
	type_label.text = _keyword_text(card)
	body_label.text = _body_text(card, active_stance)
	_fit_all_labels()

func set_cost_text(text: String):
	_bind_nodes()
	cost_label.text = text

func set_inspired_state(is_inspired: bool, effective_cost: int):
	_bind_nodes()
	cost_label.text = str(effective_cost)
	if is_inspired:
		cost_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.85))
	else:
		cost_label.remove_theme_color_override("font_color")
	_ensure_inspired_glow()
	inspired_glow.visible = is_inspired

func _bind_nodes():
	if art != null:
		return
	art = %ArtRect
	type_strip = %TypeStrip
	cost_label = %CostLabel
	name_label = %NameLabel
	keyword_label = %KeywordLabel
	type_label = %TypeLabel
	body_label = %BodyLabel

func _fit_all_labels():
	_fit_label(name_label, 18, 10)
	_fit_label(keyword_label, 14, 9)
	_fit_label(type_label, 14, 9)
	_fit_label(body_label, 15, 10)

func _fit_label(label: Control, max_size: int, min_size: int):
	if label == null:
		return
	var label_text := String(label.get("text"))
	if label_text.is_empty():
		return
	var font := label.get_theme_font(&"font")
	if font == null:
		return
	var avail := label.size
	if avail.x <= 1.0 or avail.y <= 1.0:
		_set_label_font_size(label, max_size)
		return
	var measured_text := _plain_text(label_text)
	for font_size in range(max_size, min_size - 1, -1):
		if font.get_multiline_string_size(measured_text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, font_size).y <= avail.y:
			_set_label_font_size(label, font_size)
			return
	_set_label_font_size(label, min_size)

func _set_label_font_size(label: Control, font_size: int):
	if label is RichTextLabel:
		label.add_theme_font_size_override("normal_font_size", font_size)
	else:
		label.add_theme_font_size_override("font_size", font_size)

func _apply_type_style(card_type: StringName):
	var accent := Color(0.55, 0.95, 1.0, 1.0)
	match card_type:
		&"attack":
			accent = Color(1.0, 0.32, 0.24, 1.0)
		&"enhance":
			accent = Color(0.58, 1.0, 0.72, 1.0)
		&"rp":
			accent = Color(0.7, 0.42, 1.0, 1.0)
		_:
			accent = Color(0.48, 0.86, 1.0, 1.0)
	type_strip.color = accent
	type_label.add_theme_color_override("font_color", accent.lightened(0.18))

func _card_art_path(card: CardData) -> String:
	var character_id := card.character.strip_edges()
	if not character_id.is_empty():
		var character_path := "res://assets/card/cardart_full/%s_%s.png" % [character_id, card.id]
		if ResourceLoader.exists(character_path):
			return character_path
	return "res://assets/card/cardart_full/%s.png" % card.id

func _type_text(card_type: StringName) -> String:
	match card_type:
		&"attack":
			return "공격"
		&"enhance":
			return "강화"
		&"rp":
			return "분노 스킬"
		_:
			return "기술"

func _type_header_text(card_type: StringName) -> String:
	var type_text := _type_text(card_type)
	if card_type == &"rp":
		return type_text
	return "[%s]" % type_text

func _keyword_text(card: CardData) -> String:
	var labels: Array[String] = []
	if not card.keywords.is_empty():
		for keyword in card.keywords:
			_append_keyword_label(labels, String(keyword))
	if not card.inspiration.is_empty():
		_append_keyword_label(labels, "영감")
	return " / ".join(labels)

func _append_keyword_label(labels: Array[String], keyword: String):
	var clean_keyword := keyword.strip_edges()
	if clean_keyword.is_empty():
		return
	var label := "[%s]" % clean_keyword
	if not labels.has(label):
		labels.append(label)

func _body_text(card: CardData, active_stance := "") -> String:
	var text := card.text.strip_edges()
	var hidden_tags: Array[String] = []
	hidden_tags.append(_type_text(card.card_type))
	for keyword in card.keywords:
		hidden_tags.append(String(keyword))
	if not card.inspiration.is_empty():
		hidden_tags.append("영감")
	for tag in hidden_tags:
		text = _remove_leading_tag(text, tag)
	return _highlight_stance_lines(text, active_stance)

func _highlight_stance_lines(text: String, active_stance: String) -> String:
	var lines := text.split("\n")
	for i in range(lines.size()):
		var line := String(lines[i])
		if line.begins_with("[월영]"):
			lines[i] = _format_stance_line(line, active_stance == "월영", "#86dfff")
		elif line.begins_with("[참월]"):
			lines[i] = _format_stance_line(line, active_stance == "참월", "#ffb26b")
	return "\n".join(lines)

func _format_stance_line(line: String, is_active: bool, active_color: String) -> String:
	if is_active:
		return "[color=%s]%s[/color]" % [active_color, line]
	return "[color=#7f8794]%s[/color]" % line

func _plain_text(text: String) -> String:
	return text.replace("[color=#86dfff]", "").replace("[color=#ffb26b]", "").replace("[color=#7f8794]", "").replace("[/color]", "")

func _remove_leading_tag(text: String, tag: String) -> String:
	var marker := "[%s]" % tag
	while text.begins_with(marker):
		text = text.substr(marker.length()).strip_edges()
	return text

func _ensure_inspired_glow():
	if inspired_glow != null:
		return
	inspired_glow = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.85, 0.4, 0.0)
	style.border_color = Color(1.0, 0.85, 0.4, 0.95)
	style.set_border_width_all(5)
	style.set_corner_radius_all(10)
	inspired_glow.add_theme_stylebox_override("panel", style)
	inspired_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	inspired_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspired_glow.visible = false
	add_child(inspired_glow)
