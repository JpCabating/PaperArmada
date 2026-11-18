extends Control

const SORTIE := "res://scenes/air_wars.tscn"
const DEFENDER := "res://scenes/defender.tscn"
const CITY := "res://scenes/city.tscn"
const SPACE := "res://scenes/space.tscn"
const TITLE_FONT := preload("res://scenes/ui_ink_font.tres")
const TEXT_FONT := preload("res://scenes/ui_text_font.tres")
const PLANE := preload("res://Game Assests/PNG/Default/unit_plane_a.png")
const BOAT := preload("res://Game Assests/PNG/Default/unit_ship.png")
const TANK := preload("res://Game Assests/PNG/Default/unit_tank.png")
const TURRET := preload("res://Game Assests/PNG/Default/unit_tank_turret.png")
const INK := Color("#243b47")
const PAPER := Color("#f5f1df")
const MUTED := Color("#455c63")
const GOLD := Color("#ecb759")

enum Page { HOME, MODES, MAPS, CREDITS }

var page := Page.HOME
var keyboard_focus := false
var boss_rush := false

@onready var buttons: VBoxContainer = $MenuButtons
@onready var play_button: Button = $MenuButtons/Play
@onready var credits_button: Button = $MenuButtons/Credits
@onready var back_button: Button = $Back
@onready var mode_buttons: VBoxContainer = $ModeButtons
@onready var map_buttons: VBoxContainer = $MapButtons
@onready var map_units: Node2D = $MapFrame/Map/Units


func _ready() -> void:
	for button: Button in buttons.get_children():
		_style_button(button, button == play_button)
	_style_button(back_button, false)
	for button: Button in mode_buttons.get_children():
		_style_button(button, false)
	for button: Button in map_buttons.get_children():
		_style_button(button, false)
	play_button.pressed.connect(_show_page.bind(Page.MODES))
	credits_button.pressed.connect(_show_page.bind(Page.CREDITS))
	$ModeButtons/Endless.pressed.connect(_choose_maps.bind(false))
	$ModeButtons/Defender.pressed.connect(func() -> void: get_tree().change_scene_to_file(DEFENDER))
	$ModeButtons/BossRush.pressed.connect(_choose_maps.bind(true))
	$MapButtons/Coastal.pressed.connect(_launch_map.bind(SORTIE, "res://scenes/rush_coastal.tscn"))
	$MapButtons/City.pressed.connect(_launch_map.bind(CITY, "res://scenes/rush_city.tscn"))
	$MapButtons/Space.pressed.connect(_launch_map.bind(SPACE, "res://scenes/rush_space.tscn"))
	$MenuButtons/Exit.pressed.connect(func() -> void: get_tree().quit())
	back_button.pressed.connect(_go_back)
	map_units.draw.connect(_draw_map_units)
	play_button.grab_focus()
	_update_map_focus()


func _choose_maps(rush: bool) -> void:
	boss_rush = rush
	_show_page(Page.MAPS)


func _launch_map(endless_scene: String, rush_scene: String) -> void:
	get_tree().change_scene_to_file(rush_scene if boss_rush else endless_scene)


func _input(event: InputEvent) -> void:
	var was_keyboard := keyboard_focus
	if event is InputEventKey and event.pressed:
		keyboard_focus = true
	elif event is InputEventMouse:
		keyboard_focus = false
	else:
		return
	if page == Page.MAPS and was_keyboard != keyboard_focus:
		_update_map_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if page != Page.HOME and event.is_action_pressed("ui_cancel", false):
		_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	_show_page(Page.MODES if page == Page.MAPS else Page.HOME)


func _show_page(next_page: Page) -> void:
	var previous := page
	page = next_page
	buttons.visible = page == Page.HOME
	mode_buttons.visible = page == Page.MODES
	map_buttons.visible = page == Page.MAPS
	back_button.visible = page != Page.HOME
	match page:
		Page.HOME:
			var opener := credits_button if previous == Page.CREDITS else play_button
			opener.grab_focus()
		Page.MODES: $ModeButtons/Endless.grab_focus()
		Page.MAPS:
			$MapButtons/Coastal.grab_focus()
			_update_map_focus()
		Page.CREDITS: back_button.grab_focus()
	queue_redraw()


func _update_map_focus() -> void:
	var focus: StyleBox = mode_buttons.get_node("Endless").get_theme_stylebox("focus") if keyboard_focus else StyleBoxEmpty.new()
	for button: Button in map_buttons.get_children():
		button.add_theme_stylebox_override("focus", focus)


func _style_button(button: Button, primary: bool) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", TITLE_FONT)
	button.add_theme_font_size_override("font_size", 23)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	var fill := GOLD if primary else Color("#e5e9dc")
	button.add_theme_stylebox_override("normal", _button_box(fill))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.22)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12)))
	var focus := _button_box(Color.TRANSPARENT)
	focus.draw_center = false
	focus.border_color = Color("#437c91")
	focus.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus)


func _button_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = INK
	box.set_border_width_all(2)
	box.set_corner_radius_all(7)
	return box


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#adc5c3"))
	for y in range(20, 720, 24):
		for x in range(20, 1280, 24):
			draw_circle(Vector2(x, y), 1.0, Color("#47657538"))
	var sheet := PackedVector2Array([
		Vector2(49, 78), Vector2(493, 74), Vector2(501, 643),
		Vector2(60, 652), Vector2(50, 639),
	])
	var shadow := Transform2D(0.0, Vector2(8, 10))
	draw_colored_polygon(shadow * sheet, Color("#35576554"))
	draw_colored_polygon(sheet, PAPER)
	sheet.append(sheet[0])
	draw_polyline(sheet, INK, 2.0, true)
	draw_rect(Rect2(546, 183, 674, 387), Color("#35576554"))
	draw_rect(Rect2(535, 170, 683, 392), PAPER)
	draw_rect(Rect2(535, 170, 683, 392), INK, false, 2.0)
	if page == Page.MODES:
		draw_string(TITLE_FONT, Vector2(96, 178), "Play", HORIZONTAL_ALIGNMENT_LEFT, -1, 43, INK)
		draw_string(TEXT_FONT, Vector2(97, 288), "Survive waves on a map of your choice.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
		draw_string(TEXT_FONT, Vector2(97, 383), "Protect the outpost from the east.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
		draw_string(TEXT_FONT, Vector2(97, 478), "Fight four boss rounds on Hard.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
	elif page == Page.MAPS:
		draw_string(TITLE_FONT, Vector2(96, 178), "Boss Rush" if boss_rush else "Endless", HORIZONTAL_ALIGNMENT_LEFT, -1, 43, INK)
		draw_string(TEXT_FONT, Vector2(97, 288), "Battle over islands and open water.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
		draw_string(TEXT_FONT, Vector2(97, 383), "Fly over streets and river crossings.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
		draw_string(TEXT_FONT, Vector2(97, 478), "Face alien squadrons and three bosses.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, MUTED)
	elif page == Page.CREDITS:
		draw_string(TITLE_FONT, Vector2(96, 205), "Credits", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, INK)
		draw_string(TEXT_FONT, Vector2(96, 263), "Art & Assets", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, MUTED)
		draw_string(TITLE_FONT, Vector2(96, 295), "Kenney", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
		draw_string(TEXT_FONT, Vector2(96, 343), "Game Developed by", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, MUTED)
		draw_string(TITLE_FONT, Vector2(96, 375), "Jaypie", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
		draw_string(TEXT_FONT, Vector2(96, 444), "Made with Godot Engine", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	else:
		draw_string(TITLE_FONT, Vector2(87, 205), "Paper", HORIZONTAL_ALIGNMENT_LEFT, -1, 68, INK)
		draw_string(TITLE_FONT, Vector2(93, 282), "Armada", HORIZONTAL_ALIGNMENT_LEFT, -1, 75, INK)
		draw_polyline(PackedVector2Array([Vector2(99, 296), Vector2(189, 293), Vector2(292, 297)]), GOLD, 5.0, true)
		draw_string(TEXT_FONT, Vector2(97, 337), "Coastal defense", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, MUTED)


func _draw_map_units() -> void:
	_draw_unit(TANK, Vector2(245, 438), 94.0, PI / 2.0, Color("#e1c1ae"))
	_draw_unit(TURRET, Vector2(243, 434), 45.0, 1.11, Color("#e1c1ae"))
	_draw_unit(BOAT, Vector2(978, 406), 100.0, -0.88, Color("#d4aaa0"))
	_draw_unit(PLANE, Vector2(659, 337), 160.0, 0.62, Color("#d6edfb"))
	for offset: Vector2 in [Vector2(55, -78), Vector2(78, -110), Vector2(101, -142)]:
		var start := Vector2(659, 337) + offset
		map_units.draw_line(start, start + Vector2(12, -17), GOLD, 7.0, true)


func _draw_unit(texture: Texture2D, at: Vector2, width: float, rotation_angle: float, tint: Color) -> void:
	var dimensions := texture.get_size() * (width / texture.get_width())
	var rect := Rect2(-dimensions / 2.0, dimensions)
	map_units.draw_set_transform(at + Vector2(6, 10), rotation_angle)
	map_units.draw_texture_rect(texture, rect, false, Color("#587e8f87"))
	map_units.draw_set_transform(at, rotation_angle)
	map_units.draw_texture_rect(texture, rect, false, tint)
	map_units.draw_set_transform(Vector2.ZERO)
