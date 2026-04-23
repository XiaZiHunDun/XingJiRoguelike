# autoload/logger.gd
# 统一日志系统 - 开发阶段调试用

extends Node

enum Level {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	NONE = 99
}

# 日志级别，低于此级别的不会输出
var log_level: int = Level.DEBUG

# 是否输出到文件
var output_to_file: bool = true

# 日志文件路径
var log_file_path: String = "user://game.log"

# 模块名称
var module: String = ""

func _init(module_name: String = "Global"):
	module = module_name

# 调试级别日志
func debug(msg: String, extra: Dictionary = {}) -> void:
	_log(Level.DEBUG, msg, extra)

# 信息级别日志
func info(msg: String, extra: Dictionary = {}) -> void:
	_log(Level.INFO, msg, extra)

# 警告级别日志
func warning(msg: String, extra: Dictionary = {}) -> void:
	_log(Level.WARNING, msg, extra)

# 错误级别日志
func error(msg: String, extra: Dictionary = {}) -> void:
	_log(Level.ERROR, msg, extra)

func _log(level: int, msg: String, extra: Dictionary) -> void:
	if level < log_level:
		return

	var timestamp = Time.get_datetime_string_from_system(true)
	var level_name = _get_level_name(level)
	var extra_str = _format_extra(extra)

	var log_line = "[%s] [%s] [%s] %s%s" % [timestamp, level_name, module, msg, extra_str]

	# 输出到控制台
	match level:
		Level.DEBUG:
			print_debug(log_line)
		Level.INFO:
			print(log_line)
		Level.WARNING:
			push_warning(log_line)
		Level.ERROR:
			push_error(log_line)

	# 输出到文件
	if output_to_file:
		_write_to_file(log_line)

func _get_level_name(level: int) -> String:
	match level:
		Level.DEBUG: return "D"
		Level.INFO: return "I"
		Level.WARNING: return "W"
		Level.ERROR: return "E"
		_: return "?"

func _format_extra(extra: Dictionary) -> String:
	if extra.is_empty():
		return ""
	var parts = []
	for key in extra.keys():
		parts.append("%s=%s" % [key, str(extra[key])])
	return " | " + ", ".join(parts)

func _write_to_file(line: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(line)
	file.close()

# 清空日志文件
static func clear_log() -> void:
	var path = "user://game.log"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.close()

# 读取日志文件内容
static func get_log_content() -> String:
	var path = "user://game.log"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	file.close()
	return content
