@tool
extends EditorPlugin

const SheetImporterDock := preload("res://addons/google_sheet_json_importer/google_sheet_json_importer_dock.gd")

var window: Window
var content: Control

func _enter_tree():
	add_tool_menu_item("DataTable", _open_data_table_window)

func _exit_tree():
	remove_tool_menu_item("DataTable")
	if window != null:
		window.queue_free()
		window = null
		content = null

func _open_data_table_window():
	if window == null:
		_create_data_table_window()
	window.popup_centered_ratio(0.72)
	window.grab_focus()

func _create_data_table_window():
	window = Window.new()
	window.title = "DataTable"
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	window.min_size = Vector2i(720, 560)
	window.close_requested.connect(func(): window.hide())
	EditorInterface.get_base_control().add_child(window)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	window.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	content = SheetImporterDock.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
