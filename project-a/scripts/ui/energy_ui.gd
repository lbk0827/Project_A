extends Control

@onready var energy_label: Label = %TXT_Energy
@onready var hand_count_label: Label = %TXT_HandCount

func set_energy(current_energy: int):
	energy_label.text = str(max(current_energy, 0))

func set_hand_count(current_count: int, max_count: int):
	hand_count_label.text = "%d/%d" % [max(current_count, 0), max(max_count, 0)]
