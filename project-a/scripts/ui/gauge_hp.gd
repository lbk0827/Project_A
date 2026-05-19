extends Control

@onready var hp_bar: TextureProgressBar = _find_hp_bar()
@onready var hp_label: Label = %TXT_Hp

func _find_hp_bar() -> TextureProgressBar:
	var unique_bar := get_node_or_null("%HpBar")
	if unique_bar is TextureProgressBar:
		return unique_bar
	return get_node_or_null("VisualRoot/HpBar") as TextureProgressBar

func set_player_hp(current_hp: int, max_hp: int):
	var safe_max: int = max(max_hp, 1)
	var safe_current: int = clamp(current_hp, 0, safe_max)
	if hp_bar != null:
		hp_bar.max_value = safe_max
		hp_bar.value = safe_current
	hp_label.text = "%d / %d" % [safe_current, safe_max]
