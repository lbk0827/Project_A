extends Control

const MAP_SCENE_PATH := "res://scenes/map/map_screen.tscn"

@onready var menu_panel: PanelContainer = $SafeArea/MenuPanel
@onready var start_button: Button = $SafeArea/MenuPanel/MenuRoot/StartButton
@onready var continue_button: Button = $SafeArea/MenuPanel/MenuRoot/ContinueButton
@onready var settings_button: Button = $SafeArea/MenuPanel/MenuRoot/SettingsButton
@onready var quit_button: Button = $SafeArea/MenuPanel/MenuRoot/QuitButton
@onready var settings_panel: PanelContainer = $SafeArea/SettingsPanel
@onready var settings_close_button: Button = $SafeArea/SettingsPanel/SettingsRoot/SettingsCloseButton

func _ready():
	_apply_panel_style(menu_panel, Color(0.06, 0.08, 0.11, 0.76), Color(0.94, 0.78, 0.42, 0.82))
	_apply_panel_style(settings_panel, Color(0.06, 0.08, 0.11, 0.9), Color(0.64, 0.84, 0.92, 0.72))
	_apply_button_style(start_button, Color(0.87, 0.66, 0.28, 1.0), Color(0.98, 0.82, 0.43, 1.0), Color(0.16, 0.1, 0.04, 1.0))
	_apply_button_style(continue_button, Color(0.12, 0.18, 0.24, 0.96), Color(0.18, 0.28, 0.36, 1.0), Color(0.92, 0.96, 0.98, 1.0))
	_apply_button_style(settings_button, Color(0.12, 0.18, 0.24, 0.96), Color(0.18, 0.28, 0.36, 1.0), Color(0.92, 0.96, 0.98, 1.0))
	_apply_button_style(quit_button, Color(0.18, 0.12, 0.14, 0.96), Color(0.32, 0.16, 0.18, 1.0), Color(0.96, 0.9, 0.88, 1.0))
	_apply_button_style(settings_close_button, Color(0.12, 0.18, 0.24, 0.96), Color(0.18, 0.28, 0.36, 1.0), Color(0.92, 0.96, 0.98, 1.0))
	_update_continue_state()

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

func _update_continue_state():
	var run_state := _run_state()
	var can_continue := false
	if run_state != null:
		can_continue = run_state.current_node_id != run_state.START_NODE_ID or not run_state.completed_nodes.is_empty() or run_state.run_cleared
	continue_button.disabled = not can_continue
	continue_button.tooltip_text = "진행 중인 런이 있을 때 사용할 수 있습니다." if not can_continue else ""

func _on_start_button_pressed():
	var run_state := _run_state()
	if run_state != null:
		run_state.reset_run()
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_continue_button_pressed():
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_settings_button_pressed():
	settings_panel.visible = true
	settings_close_button.grab_focus()

func _on_settings_close_button_pressed():
	settings_panel.visible = false
	settings_button.grab_focus()

func _on_quit_button_pressed():
	get_tree().quit()

func _apply_panel_style(panel: PanelContainer, fill_color: Color, border_color: Color):
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 24
	style.content_margin_top = 22
	style.content_margin_right = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)

func _apply_button_style(button: Button, normal_color: Color, hover_color: Color, font_color: Color):
	var normal := _make_button_style(normal_color)
	var hover := _make_button_style(hover_color)
	var pressed := _make_button_style(hover_color.darkened(0.12))
	var disabled := _make_button_style(Color(0.11, 0.12, 0.14, 0.72))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(0.64, 0.68, 0.72, 0.78))
	button.add_theme_font_size_override("font_size", 22)

func _make_button_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	return style
