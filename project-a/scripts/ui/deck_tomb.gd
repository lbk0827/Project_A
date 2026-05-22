extends Control

@onready var count_label: Label = %TXT_Count

func set_tomb_count(count: int):
	count_label.text = str(max(count, 0))
