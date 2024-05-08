extends Control

const ConsoleLogs = preload("../console_logs/console_logs.gd")
const REPL = preload("./repl.gd")

@onready var _console_logs:ConsoleLogs = $VBoxContainer/ConsoleLogs
@onready var _repl:REPL = $REPL

func _ready() -> void:
	_repl.output.connect(output)

## Output [code]any[/code] to the console
func output(any):
	var text = str(any)
	_console_logs.add_log(text)

func clear_output():
	_console_logs.clear()
