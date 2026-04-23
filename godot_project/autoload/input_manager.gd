# autoload/input_manager.gd
# Gamepad/Keyboard input device manager

extends Node

enum InputDevice {
	KEYBOARD_MOUSE,
	GAMEPAD
}

var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE

func _process(delta: float) -> void:
	_detect_input_device()

func _detect_input_device() -> void:
	var connected_joypads = Input.get_connected_joypads()
	if connected_joypads.size() > 0:
		var axes = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		if abs(axes) > 0.2:
			current_device = InputDevice.GAMEPAD
		elif Input.is_action_just_pressed("ui_accept"):
			current_device = InputDevice.GAMEPAD
	else:
		current_device = InputDevice.KEYBOARD_MOUSE

func is_gamepad() -> bool:
	return current_device == InputDevice.GAMEPAD
