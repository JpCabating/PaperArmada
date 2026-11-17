extends CanvasLayer

@onready var arena = get_parent()
@onready var pause_button: Button = $Pause
@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Resume


func _ready() -> void:
	pause_button.pressed.connect(_set_paused.bind(true))
	resume_button.pressed.connect(_set_paused.bind(false))
	$Overlay/Leave.pressed.connect(_leave_level)


func _process(_delta: float) -> void:
	pause_button.visible = _can_pause() and not overlay.visible


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and _can_pause():
		get_viewport().set_input_as_handled()
		_set_paused(not overlay.visible)


func _can_pause() -> bool:
	return arena.phase == arena.Phase.INCOMING or arena.phase == arena.Phase.COMBAT


func _set_paused(paused: bool) -> void:
	if paused and not _can_pause():
		return
	get_tree().paused = paused
	overlay.visible = paused
	pause_button.visible = not paused and _can_pause()
	if paused:
		resume_button.grab_focus()


func _leave_level() -> void:
	_set_paused(false)
	arena._return_to_main_menu()
