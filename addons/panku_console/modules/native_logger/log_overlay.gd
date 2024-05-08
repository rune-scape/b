@tool
extends PanelContainer

var _module:PankuModule

const GUTTER_SIZE = 10

var solid_mode := false:
	set(v):
		solid_mode = v
		var mfilter := MOUSE_FILTER_STOP if v else MOUSE_FILTER_IGNORE
		mouse_filter = mfilter
		$VBoxContainer.mouse_filter = mfilter
		%LogOverlayText.mouse_filter = mfilter
		%LogOverlayLatest.mouse_filter = mfilter
		%BottomMargin.mouse_filter = mfilter
		get_theme_stylebox(&"panel").texture = _bg_tex_opaque if v else _bg_tex
		modulate.a = 1.0 if v else opacity

var opacity:float:
	set(v):
		opacity = v
		if not solid_mode:
			modulate.a = opacity

#const MAX_LENGTH = 65536
var last_line = null
var last_bbcode = null
var duplicated_counter := 1
var instance_id_regex := RegEx.create_from_string("<[a-zA-Z_][a-zA-Z0-9_]*#([0-9]*)>")
#var content_prev := ""
#var content_cur := ""

var _bg_tex: Texture2D
var _bg_tex_opaque: Texture2D

func clear():
	if Engine.is_editor_hint():
		%LogOverlayText.text = """
	   normal
	   [b]bold[/b]
	   [i]italics[/i]
	   [b][i]bold italics[/i][/b]"""
	else:
		%LogOverlayText.text = "\n"
	%LogOverlayLatest.text = ""
	last_line = null
	last_bbcode = null
	duplicated_counter = 1

func _ready() -> void:
	var base_dir:String = get_script().resource_path.get_base_dir()
	_bg_tex = load(base_dir.path_join("log_overlay_bg.tres"))
	_bg_tex_opaque = load(base_dir.path_join("log_overlay_bg_opaque.tres"))
	
	clear()
	%LogOverlayText.meta_clicked.connect(_meta_clicked)
	%LogOverlayLatest.meta_clicked.connect(_meta_clicked)
	
	%LogOverlayText.finished.connect(_log_overlay_latest_changed)
	%LogOverlayLatest.finished.connect(_log_overlay_latest_changed)
	resized.connect(_log_overlay_latest_changed)
	theme_changed.connect(_log_overlay_latest_changed)
	_log_overlay_latest_changed()

func _log_overlay_latest_changed():
	_log_overlay_latest_changed_deferred.call_deferred()

func _log_overlay_latest_changed_deferred():
	%LogOverlayLatest.position = Vector2(0.0, %LogOverlayText.get_line_offset(%LogOverlayText.get_line_count()-1))
	%BottomMargin.custom_minimum_size.y = 32 + %LogOverlayLatest.size.y

func _meta_clicked(meta: String):
	var id: int = meta.to_int()
	if not is_instance_id_valid(id):
		push_error("trying to inspect previously freed object")
		return
	_module.core.inspect.call(instance_from_id(id))

#func escape_bbcode(bbcode_text:String):
#	# We only need to replace opening brackets to prevent tags from being parsed.
#	return bbcode_text.replace("[", "[lb]")

const info_color := "#fff"
var warn_color := Color("#ee9").to_html(false)
var err_color := Color("#e78").to_html(false)
var info_color_muted := Color(info_color).darkened(0.2).to_html(false)
var warn_color_muted := Color(warn_color).darkened(0.2).to_html(false)
var err_color_muted := Color(err_color).darkened(0.2).to_html(false)

func add_log(line:String, level:int):
	#if %LogOverlayText.text.length() > MAX_LENGTH:
	#	%LogOverlayText.text.clear()
	
	# nvm, allow using bbcode in prints
	#line = escape_bbcode(line)
	
	%LogOverlayLatest.text = ""
	%LogOverlayLatest.clear()
	
	var prefix := ""
	var prefix_len := 0
	var default_color: String = %LogOverlayText.get_theme_color(&"default_color").to_html()
	
	var bbcode_prefix := ""
	if line == last_line:
		duplicated_counter += 1
		prefix = ("(%s)" % duplicated_counter)
		prefix_len += prefix.length()
		bbcode_prefix = "[color=%s]%s[/color]" % [default_color, bbcode_prefix]
	else:
		duplicated_counter = 1
		last_line = line
		if last_bbcode != null:
			%LogOverlayText.append_text(last_bbcode)
	
	var format_color := info_color
	var format_color_muted := info_color_muted
	if level == 1:
		prefix += ">"
		prefix_len += 1
	elif level == 2:
		prefix += "[[i]warn[/i]]"
		prefix_len += 6
		#format_color = "#e1ed96"
		format_color = warn_color
		format_color_muted = warn_color_muted
	elif level == 3:
		prefix += "[[i]err[/i]]"
		prefix_len += 5
		#format_color = "#dd7085"
		format_color = err_color
		format_color_muted = err_color_muted
	
	if prefix_len < GUTTER_SIZE:
		prefix = " ".repeat(GUTTER_SIZE - prefix_len) + prefix
		prefix_len = GUTTER_SIZE
	
	var multiline_prefix: String = ("\n%s[color=%s][b]|[/b][/color] " % [" ".repeat(prefix_len-1), format_color])
	
	if instance_id_regex.is_valid():
		line = instance_id_regex.sub(line, "[url=$1]$0[/url]", true)
	
	var lines := line.split("\n")
	var bbcode := "[color=%s][b]%s[/b][/color] [color=%s]%s[/color]\n" % [format_color, prefix, format_color_muted, multiline_prefix.join(lines)]
	%LogOverlayLatest.append_text(bbcode)
	last_bbcode = bbcode
	_log_overlay_latest_changed()
