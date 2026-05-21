extends Control

@onready var count_label: Label = %TXT_Count

func set_deck_count(count: int):
	count_label.text = str(max(count, 0))
