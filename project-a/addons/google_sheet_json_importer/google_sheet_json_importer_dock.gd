@tool
extends VBoxContainer

const DEFAULT_SHEET_URL := "https://docs.google.com/spreadsheets/d/1xOubUBJ7e-C3eXefiEDIli3xtWuxWZhEMtd1niD3qbk/edit?gid=0#gid=0"
const FIXED_HEADER_ROWS := 3
const MAX_REDIRECTS := 8
const TABLES := [
	{
		"name": "PlayerStatusTable",
		"url": DEFAULT_SHEET_URL,
		"output_path": "res://data/imported/PlayerStatusTable.json"
	}
]

var table_controls := {}
var active_table_name := ""
var redirect_count := 0
var status_label: RichTextLabel
var http_request: HTTPRequest

func _init():
	name = "DataTable"

func _ready():
	_build_ui()

func _build_ui():
	var title := Label.new()
	title.text = "DataTable"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	var help := Label.new()
	help.text = "Row 1: column name, Row 2: type, Row 3: description, Row 4+: data\nGoogle Sheet must be shared as Anyone with the link: Viewer, or use a published CSV URL."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)

	for table in TABLES:
		_add_table_section(table)

	status_label = RichTextLabel.new()
	status_label.custom_minimum_size = Vector2(0, 180)
	status_label.fit_content = true
	status_label.bbcode_enabled = true
	add_child(status_label)

	http_request = HTTPRequest.new()
	http_request.max_redirects = MAX_REDIRECTS
	http_request.request_completed.connect(_on_request_completed)
	add_child(http_request)

	_log("Ready.")

func _add_table_section(table: Dictionary):
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(panel)

	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	panel.add_child(section)

	var table_title := Label.new()
	table_title.text = table["name"]
	table_title.add_theme_font_size_override("font_size", 14)
	section.add_child(table_title)

	var url_label := Label.new()
	url_label.text = "URL"
	section.add_child(url_label)

	var url_input := LineEdit.new()
	url_input.text = table["url"]
	url_input.placeholder_text = "Shared Google Sheet URL or published CSV URL"
	section.add_child(url_input)

	var convert_button := Button.new()
	convert_button.text = "Convert"
	convert_button.pressed.connect(_on_convert_pressed.bind(table["name"]))
	section.add_child(convert_button)

	table_controls[table["name"]] = {
		"url_input": url_input,
		"convert_button": convert_button,
		"output_path": table["output_path"]
	}

func _on_convert_pressed(table_name: String):
	if not table_controls.has(table_name):
		_log_error("Unknown table: %s" % table_name)
		return

	var controls: Dictionary = table_controls[table_name]
	var spreadsheet_url: String = controls["url_input"].text.strip_edges()
	var output_path: String = controls["output_path"]
	if spreadsheet_url.is_empty():
		_log_error("%s URL is empty." % table_name)
		return
	if not output_path.begins_with("res://") or not output_path.ends_with(".json"):
		_log_error("Output path must be a res:// path ending with .json.")
		return

	var csv_url := _to_csv_export_url(spreadsheet_url)
	if csv_url.is_empty():
		_log_error("Could not parse Google Spreadsheet URL.")
		return

	active_table_name = table_name
	redirect_count = 0
	_set_table_buttons_disabled(true)
	_log("Converting %s...\n%s" % [table_name, csv_url])
	var error := http_request.request(csv_url)
	if error != OK:
		_finish_request()
		_log_error("HTTPRequest failed to start. Error: %s" % error)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var table_name := active_table_name
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_request()
		_log_error("Download failed. Result: %s, HTTP: %s" % [result, response_code])
		return
	if response_code >= 300 and response_code < 400:
		if _try_follow_redirect(headers):
			return
		_finish_request()
		_log_error("Google Sheet returned HTTP %s, but the redirect could not be followed." % response_code)
		return
	if response_code < 200 or response_code >= 300:
		_finish_request()
		if response_code == 401 or response_code == 403:
			_log_error("Google Sheet returned HTTP %s.\nSet Share > General access to Anyone with the link: Viewer, or paste a File > Share > Publish to web CSV URL." % response_code)
		else:
			_log_error("Google Sheet returned HTTP %s." % response_code)
		return

	var csv_text := body.get_string_from_utf8()
	var rows := _parse_csv_text(csv_text)
	var column_names := _extract_column_names(rows)
	var records := _convert_rows_to_records(rows)
	if records.is_empty():
		_finish_request()
		return

	var output_path: String = table_controls[table_name]["output_path"]
	var save_error := _save_json(output_path, records, column_names)
	if save_error != OK:
		_finish_request()
		_log_error("Failed to save JSON. Error: %s" % save_error)
		return

	EditorInterface.get_resource_filesystem().scan()
	_finish_request()
	_log_success("%s saved %d rows to %s" % [table_name, records.size(), output_path])

func _try_follow_redirect(headers: PackedStringArray) -> bool:
	if redirect_count >= MAX_REDIRECTS:
		_log_error("Too many redirects while downloading Google Sheet.")
		return false

	var redirect_url := _extract_header_value(headers, "location")
	if redirect_url.is_empty():
		return false

	redirect_count += 1
	_log("Following Google Sheet redirect %d/%d...\n%s" % [redirect_count, MAX_REDIRECTS, redirect_url])
	var error := http_request.request(redirect_url)
	if error != OK:
		_log_error("Redirect request failed to start. Error: %s" % error)
		return false
	return true

func _extract_header_value(headers: PackedStringArray, header_name: String) -> String:
	var target := "%s:" % header_name.to_lower()
	for header in headers:
		var lower_header := header.to_lower()
		if lower_header.begins_with(target):
			return header.substr(header.find(":") + 1).strip_edges()
	return ""

func _finish_request():
	active_table_name = ""
	redirect_count = 0
	_set_table_buttons_disabled(false)

func _set_table_buttons_disabled(disabled: bool):
	for controls in table_controls.values():
		controls["convert_button"].disabled = disabled

func _to_csv_export_url(spreadsheet_url: String) -> String:
	if _is_csv_url(spreadsheet_url):
		return spreadsheet_url
	if spreadsheet_url.contains("/spreadsheets/d/e/") and spreadsheet_url.contains("/pub"):
		return _ensure_query_parameter(spreadsheet_url, "output", "csv")

	var spreadsheet_id := _extract_between(spreadsheet_url, "/d/", "/")
	if spreadsheet_id.is_empty():
		return ""
	var gid := _extract_gid(spreadsheet_url)
	return "https://docs.google.com/spreadsheets/d/%s/export?format=csv&gid=%s" % [spreadsheet_id, gid]

func _is_csv_url(url: String) -> bool:
	var lower_url := url.to_lower()
	return lower_url.contains("format=csv") or lower_url.contains("output=csv")

func _ensure_query_parameter(url: String, key: String, value: String) -> String:
	if url.to_lower().contains("%s=" % key.to_lower()):
		return url
	var separator := "&" if url.contains("?") else "?"
	return "%s%s%s=%s" % [url, separator, key.uri_encode(), value.uri_encode()]

func _extract_between(text: String, prefix: String, suffix: String) -> String:
	var start := text.find(prefix)
	if start == -1:
		return ""
	start += prefix.length()
	var end := text.find(suffix, start)
	if end == -1:
		return text.substr(start)
	return text.substr(start, end - start)

func _extract_gid(spreadsheet_url: String) -> String:
	var gid_key := "gid="
	var start := spreadsheet_url.find(gid_key)
	if start == -1:
		return "0"
	start += gid_key.length()
	var end := start
	while end < spreadsheet_url.length():
		var c := spreadsheet_url[end]
		if c < "0" or c > "9":
			break
		end += 1
	if end == start:
		return "0"
	return spreadsheet_url.substr(start, end - start)

func _parse_csv_text(csv_text: String) -> Array[Array]:
	var rows: Array[Array] = []
	var row: Array[String] = []
	var cell := ""
	var in_quotes := false
	var i := 0

	while i < csv_text.length():
		var c := csv_text[i]
		if c == "\"":
			if in_quotes and i + 1 < csv_text.length() and csv_text[i + 1] == "\"":
				cell += "\""
				i += 1
			else:
				in_quotes = not in_quotes
		elif c == "," and not in_quotes:
			row.append(cell)
			cell = ""
		elif (c == "\n" or c == "\r") and not in_quotes:
			if c == "\r" and i + 1 < csv_text.length() and csv_text[i + 1] == "\n":
				i += 1
			row.append(cell)
			rows.append(row)
			row = []
			cell = ""
		else:
			cell += c
		i += 1

	if not cell.is_empty() or not row.is_empty():
		row.append(cell)
		rows.append(row)

	return rows

func _convert_rows_to_records(rows: Array[Array]) -> Array[Dictionary]:
	if rows.size() <= FIXED_HEADER_ROWS:
		_log_error("Sheet must include at least 4 rows.")
		return []

	var columns: Array = rows[0]
	var types: Array = rows[1]
	var records: Array[Dictionary] = []

	for row_index in range(FIXED_HEADER_ROWS, rows.size()):
		var row: Array = rows[row_index]
		if _is_empty_row(row):
			continue

		var record := {}
		for column_index in range(columns.size()):
			var column_name := str(columns[column_index]).strip_edges()
			if column_name.is_empty():
				continue
			var type_name := "string"
			if column_index < types.size():
				type_name = str(types[column_index]).strip_edges().to_lower()
			var raw_value := ""
			if column_index < row.size():
				raw_value = str(row[column_index]).strip_edges()
			record[column_name] = _convert_value(raw_value, type_name)
		records.append(record)

	return records

func _extract_column_names(rows: Array[Array]) -> Array[String]:
	var column_names: Array[String] = []
	if rows.is_empty():
		return column_names

	for column in rows[0]:
		var column_name := str(column).strip_edges()
		if column_name.is_empty():
			continue
		column_names.append(column_name)
	return column_names

func _is_empty_row(row: Array) -> bool:
	for value in row:
		if not str(value).strip_edges().is_empty():
			return false
	return true

func _convert_value(raw_value: String, type_name: String) -> Variant:
	match type_name:
		"int", "integer":
			return raw_value.to_int()
		"float", "double", "number":
			return raw_value.to_float()
		"bool", "boolean":
			return raw_value.to_lower() in ["true", "1", "yes", "y"]
		"json":
			var parsed := JSON.parse_string(raw_value)
			return parsed if parsed != null else raw_value
		"int[]":
			return _convert_array(raw_value, "int")
		"float[]":
			return _convert_array(raw_value, "float")
		"string[]":
			return _convert_array(raw_value, "string")
		_:
			return raw_value

func _convert_array(raw_value: String, item_type: String) -> Array:
	if raw_value.is_empty():
		return []
	var result: Array = []
	for item in raw_value.split(",", false):
		var trimmed := item.strip_edges()
		match item_type:
			"int":
				result.append(trimmed.to_int())
			"float":
				result.append(trimmed.to_float())
			_:
				result.append(trimmed)
	return result

func _save_json(output_path: String, records: Array[Dictionary], column_names: Array[String]) -> Error:
	var dir_path := output_path.get_base_dir()
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	if dir_error != OK:
		return dir_error

	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(_stringify_records(records, column_names))
	return OK

func _stringify_records(records: Array[Dictionary], column_names: Array[String]) -> String:
	var lines: Array[String] = ["["]
	for record_index in range(records.size()):
		var record := records[record_index]
		lines.append("\t{")
		for column_index in range(column_names.size()):
			var column_name := column_names[column_index]
			if not record.has(column_name):
				continue

			var suffix := "," if _has_next_column(record, column_names, column_index + 1) else ""
			lines.append("\t\t%s: %s%s" % [JSON.stringify(column_name), JSON.stringify(record[column_name]), suffix])
		lines.append("\t}%s" % ("," if record_index < records.size() - 1 else ""))
	lines.append("]")
	return "\n".join(lines)

func _has_next_column(record: Dictionary, column_names: Array[String], start_index: int) -> bool:
	for column_index in range(start_index, column_names.size()):
		if record.has(column_names[column_index]):
			return true
	return false

func _log(message: String):
	status_label.text = "[color=light_gray]%s[/color]" % message

func _log_success(message: String):
	status_label.text = "[color=light_green]%s[/color]" % message

func _log_error(message: String):
	status_label.text = "[color=salmon]%s[/color]" % message
