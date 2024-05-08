extends Node
#Monitor built-in logs

signal error_msg_received(msg:String)
signal warning_msg_received(msg:String)
signal info_msg_received(msg:String)

const UPDATE_INTERVAL := 0.1
const SHADER_FILE_START := "--Main Shader--"
const SHADER_ERROR_MSG_PREFIX := "SHADER ERROR: "
const ERROR_PREFIXES := [
	"SCRIPT ERROR: ",
	"SHADER ERROR: ",
	"ERROR: ",
	"USER SCRIPT ERROR: ",
	"USER SHADER ERROR: ",
	"USER ERROR: ",
]
const WARNING_PREFIXES := [
	"WARNING: ",
	"USER WARNING: ",
]

var read_timer:Timer
var godot_log:FileAccess

func _ready():
	var file_logging_enabled = ProjectSettings.get("debug/file_logging/enable_file_logging") or ProjectSettings.get("debug/file_logging/enable_file_logging.pc")
	if !file_logging_enabled:
		push_warning("You have to enable file logging in order to use engine log monitor!")
		return
	
	var log_path = ProjectSettings.get("debug/file_logging/log_path")
	godot_log = FileAccess.open(log_path, FileAccess.READ)
	var err := godot_log.get_error()
	if err != OK:
		print("Error opening log file: %s" % error_string(err))
	
	if read_timer == null:
		read_timer = Timer.new()
		add_child(read_timer)
		read_timer.timeout.connect(_read_data)
		read_timer.start(UPDATE_INTERVAL)

var _source_location_regex := RegEx.create_from_string("^(\\s*)at:\\s")
var _file_pos: int = 0
func _read_data():
	var file_len := godot_log.get_length()
	#print("   left: %s(%s/%s)" % [file_len-_file_pos, _file_pos, file_len])
	godot_log.seek(_file_pos)
	var buffer := godot_log.get_buffer(file_len - _file_pos).get_string_from_utf8()
	_file_pos = file_len
	if buffer.is_empty():
		return
	
	var lines := buffer.split("\n")
	if lines[lines.size()-1].is_empty():
		lines.remove_at(lines.size()-1)
	#print(lines)
	var i := -1
	while (i+1) < lines.size():
		i += 1
		#var new_line: String = godot_log.get_line()
		var new_line: String = lines[i]
		#info_msg_received.emit(new_line)
		#continue
		#if new_line.begins_with(IGNORE_PREFIX):
		#	continue
		if new_line == SHADER_FILE_START:
			while (i+1) < lines.size():
				i += 1
				var next_line := lines[i]
				if next_line.begins_with(SHADER_ERROR_MSG_PREFIX) or next_line.begins_with("USER " + SHADER_ERROR_MSG_PREFIX):
					break
		
		var sig = null
		var prefix := ""
		for p in ERROR_PREFIXES:
			if new_line.begins_with(p):
				prefix = p
				sig = error_msg_received
				break
		if sig == null:
			for p in WARNING_PREFIXES:
				if new_line.begins_with(p):
					prefix = p
					sig = warning_msg_received
					break
		if sig == null:
			info_msg_received.emit(new_line)
			continue
		
		new_line = new_line.trim_prefix(prefix)
		
		while (i+1) < lines.size():
			i += 1
			var next_line := lines[i]
			var source_location_match := _source_location_regex.search(next_line)
			if not _source_location_regex.is_valid():
				break
			if source_location_match != null:
				new_line += "\n" + source_location_match.get_string(1) + next_line
				break
			new_line += "\n" + next_line
		sig.emit(new_line)
