extends RefCounted

const Roster := preload("res://scripts/enemy_roster.gd")
const SHEET := preload("res://Game Assests/Tilesheet/City-Units.png")
const MECH := preload("res://Game Assests/Tilesheet/city_mech_cutout.png")
const ANIMATIONS := preload("res://Game Assests/Tilesheet/city_animations_cutout.png")
const ANIMATION_CELL := Vector2(200, 170)


static func build_units() -> Array[Dictionary]:
	var shell := _sprite(SHEET, Rect2(139, 758, 66, 35))
	var rocket := _sprite(SHEET, Rect2(795, 751, 116, 48))
	var units: Array[Dictionary] = [
		_unit(Roster.Role.FIGHTER, 1, Rect2(26, 13, 151, 133), 63.0, 22.0, 130.0, 2, 1, shell),
		_unit(Roster.Role.TANK, 1, Rect2(14, 158, 159, 120), 64.0, 23.0, 69.0, 3, 1, shell),
		_unit(Roster.Role.FIGHTER, 1, Rect2(198, 15, 139, 124), 64.0, 21.0, 142.0, 2, 1, shell),
		_unit(Roster.Role.FIGHTER, 2, Rect2(536, 7, 128, 131), 63.0, 22.0, 109.0, 3, 1, shell),
		_unit(Roster.Role.TANK, 2, Rect2(374, 151, 171, 120), 71.0, 26.0, 61.0, 4, 2, rocket),
		_unit(Roster.Role.FIGHTER, 2, Rect2(1099, 9, 150, 116), 64.0, 22.0, 181.0, 1, 1, shell),
		_unit(Roster.Role.TANK, 3, Rect2(192, 162, 161, 110), 71.0, 27.0, 80.0, 4, 1, shell),
		_unit(Roster.Role.FIGHTER, 3, Rect2(877, 12, 171, 126), 76.0, 25.0, 117.0, 4, 2, rocket),
		_unit(Roster.Role.TANK, 3, Rect2(908, 151, 157, 118), 69.0, 26.0, 78.0, 4, 2, shell),
		_unit(Roster.Role.FIGHTER, 4, Rect2(747, 307, 125, 93), 61.0, 20.0, 165.0, 2, 2, shell),
		_unit(Roster.Role.TANK, 4, Rect2(1147, 301, 103, 103), 58.0, 23.0, 94.0, 4, 2, shell),
		_unit(Roster.Role.JET, 4, Rect2(1291, 20, 230, 91), 73.0, 24.0, 197.0, 3, 2, rocket),
		_unit(Roster.Role.TANK, 5, Rect2(1404, 295, 116, 110), 54.0, 22.0, 84.0, 4, 1, shell),
		_unit(Roster.Role.FIGHTER, 5, Rect2(710, 8, 132, 143), 67.0, 24.0, 125.0, 4, 2, rocket),
	]
	_flight_cycle(units[3], 0)
	_flight_cycle(units[5], 1)
	_flight_cycle(units[7], 2, true)
	_flight_cycle(units[9], 1)
	_flight_cycle(units[13], 0)
	_walk_cycle(units[10], _animated_row(6, 7))
	_walk_cycle(units[12], _animated_row(7, 7))
	var rifle := _unit(Roster.Role.TANK, 2, Rect2(32, 297, 110, 105), 49.0, 19.0, 81.0, 2, 1, shell)
	var guard := _unit(Roster.Role.TANK, 3, Rect2(383, 297, 89, 104), 52.0, 20.0, 75.0, 4, 1, shell)
	var crawler := _unit(Roster.Role.TANK, 4, Rect2(1013, 299, 112, 107), 58.0, 22.0, 99.0, 3, 2, shell)
	_walk_cycle(rifle, _animated_row(3, 7))
	_walk_cycle(guard, _animated_row(4, 7))
	_walk_cycle(crawler, _animated_row(5, 7))
	units.append_array([rifle, guard, crawler])
	return units


static func build_bosses() -> Array[Dictionary]:
	var rocket := _sprite(SHEET, Rect2(795, 751, 116, 48))
	var heavy_shell := _sprite(SHEET, Rect2(1060, 750, 128, 49))
	var gunship := _unit(Roster.Role.BOMBER, 5, Rect2(32, 421, 527, 299), 191.0, 62.0, 116.0, 34, 3, rocket)
	gunship.boss_name = "City Gunship"
	gunship.boss_interval = 1.65
	var walker := _unit(Roster.Role.TANK, 5, Rect2(575, 420, 475, 317), 140.0, 54.0, 66.0, 42, 4, rocket)
	walker.boss_name = "Siege Mech"
	walker.boss_interval = 1.43
	walker.walk_frames = _walk_frames()
	walker.body = walker.walk_frames[0]
	var guardian := _unit(Roster.Role.TANK, 5, Rect2(1060, 420, 435, 316), 158.0, 61.0, 75.0, 51, 5, heavy_shell)
	guardian.boss_name = "Shield Titan"
	guardian.boss_interval = 1.23
	_walk_cycle(guardian, _animated_row(8, 8))
	guardian.left_frames = _animated_row(9, 8)
	guardian.idle_frames = _animated_row(10, 6)
	guardian.attack_frames = _animated_row(11, 5, 2)
	return [gunship, walker, guardian]


static func _animated_row(row: int, count: int, start := 0) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	for index in range(start, start + count):
		frames.append(_sprite(ANIMATIONS, Rect2(Vector2(index, row) * ANIMATION_CELL, ANIMATION_CELL)))
	return frames


static func _flight_cycle(unit: Dictionary, row: int, side_view := false) -> void:
	unit.flight_frames = _animated_row(row, 6)
	unit.side_view = side_view
	unit.body = unit.flight_frames[0]


static func _walk_cycle(unit: Dictionary, frames: Array[AtlasTexture]) -> void:
	unit.walk_frames = frames
	unit.body = frames[0]


static func _walk_frames() -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	for section in [Vector2i(315, 178), Vector2i(502, 161), Vector2i(673, 159),
			Vector2i(845, 151), Vector2i(1013, 164), Vector2i(1179, 163), Vector2i(1359, 174)]:
		frames.append(_sprite(MECH, Rect2(section.x, 19, section.y, 175)))
	return frames


static func _unit(role: Roster.Role, wave: int, region: Rect2, width: float, radius: float,
		speed: float, hull: int, volley: int, bolt: AtlasTexture) -> Dictionary:
	return {
		"role": role,
		"wave": wave,
		"body": _sprite(SHEET, region),
		"city_shot": bolt,
		"stats": {
			"width": width, "radius": radius, "speed": speed, "hull": hull,
			"distance": 0.0 if role == Roster.Role.TANK else 168.0,
			"volley": volley, "weapon": 0,
		},
	}


static func _sprite(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	texture.filter_clip = true
	return texture
