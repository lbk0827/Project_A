extends CanvasLayer

@onready var ui_root: Control = %UIRoot
@onready var gauge_hp: Control = %GaugeHp
@onready var deck_hand: Control = %DeckHand
@onready var deck_tomb: Control = %DeckTomb
@onready var hand_container: HBoxContainer = %HandContainer
@onready var targeting_dot: Panel = %TargetingDot
@onready var end_turn_button: Button = %EndTurnButton
@onready var restart_button: Button = %RestartButton

func set_player_hp(current_hp: int, max_hp: int):
	if gauge_hp.has_method("set_player_hp"):
		gauge_hp.call("set_player_hp", current_hp, max_hp)

func set_deck_count(count: int):
	if deck_hand.has_method("set_deck_count"):
		deck_hand.call("set_deck_count", count)

func set_tomb_count(count: int):
	if deck_tomb.has_method("set_tomb_count"):
		deck_tomb.call("set_tomb_count", count)
