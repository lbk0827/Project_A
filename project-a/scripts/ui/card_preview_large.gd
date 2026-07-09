extends Control

var art: TextureRect
var type_strip: ColorRect
var cost_label: Label
var name_label: Label
var keyword_label: Label
var type_label: Label
var body_label: Label
var inspired_glow: Panel

func _ready():
	_bind_nodes()

func set_card(card: CardData, effective_cost: int = -1):
	_bind_nodes()
	_apply_type_style(card.card_type)
	var art_path := _card_art_path(card)
	art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	cost_label.text = str(card.cost if effective_cost < 0 else effective_cost)
	name_label.text = card.display_name
	keyword_label.text = _keyword_text(card)
	type_label.text = "[%s]" % _type_text(card.card_type)
	body_label.text = card.text
	_fit_all_labels()

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
	_fit_label(name_label, 26, 14)
	_fit_label(keyword_label, 20, 13)
	_fit_label(type_label, 20, 13)
	_fit_label(body_label, 22, 14)

func _fit_label(label: Label, max_size: int, min_size: int):
	if label == null or label.text.is_empty():
		return
	var font := label.get_theme_font(&"font")
	if font == null:
		return
	var avail := label.size
	if avail.x <= 1.0 or avail.y <= 1.0:
		label.add_theme_font_size_override("font_size", max_size)
		return
	for font_size in range(max_size, min_size - 1, -1):
		if font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, font_size).y <= avail.y:
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", min_size)

func _apply_type_style(card_type: StringName):
	var accent := Color(0.55, 0.95, 1.0, 1.0)
	match card_type:
		&"attack":
			accent = Color(1.0, 0.32, 0.24, 1.0)
		&"enhance":
			accent = Color(0.58, 1.0, 0.72, 1.0)
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
			return "ATTACK"
		&"enhance":
			return "ENHANCE"
		_:
			return "SKILL"

func _keyword_text(card: CardData) -> String:
	var labels: Array[String] = []
	if not card.keywords.is_empty():
		for keyword in card.keywords:
			labels.append(String(keyword))
	if not card.inspiration.is_empty():
		labels.append("INSPIRE")
	if labels.is_empty():
		labels.append(_type_text(card.card_type))
	return " / ".join(labels)

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
