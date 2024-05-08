class_name PankuConfig

const FILE_NAME = "panku_config.cfg"
const FILE_PATH = "user://" + FILE_NAME

static func set_config(config:Dictionary):
	var file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	var content = var_to_str(config)
	if FileAccess.get_open_error() != OK:
		push_error("Could not save config: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(content)

static func get_config() -> Dictionary:
	if FileAccess.file_exists(FILE_PATH):
		var file = FileAccess.open(FILE_PATH, FileAccess.READ)
		if FileAccess.get_open_error() != OK:
			push_error("Could not save config: %s" % error_string(FileAccess.get_open_error()))
		else:
			var content = file.get_as_text()
			var config:Dictionary = str_to_var(content)
			if config:
				return config
	return {}
