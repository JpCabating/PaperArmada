extends RefCounted

const Roster := preload("res://scripts/enemy_roster.gd")
const UNITS := preload("res://Scribble-Planes/Tilesheet/Space-Units.png")
const PLAYER := preload("res://Scribble-Planes/Tilesheet/space_player_cutout.png")


static func player_frames() -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	for x in [429, 651, 869, 1091, 1305]:
		frames.append(_sprite(PLAYER, Rect2(x, 85, 196, 242)))
	return frames


static func build_units() -> Array[Dictionary]:
	var bolts := [
		_sprite(UNITS, Rect2(305, 535, 69, 37)),
		_sprite(UNITS, Rect2(305, 632, 81, 42)),
		_sprite(UNITS, Rect2(301, 684, 86, 41)),
	]
	return [
		_unit(Roster.Role.FIGHTER, Rect2(18, 46, 71, 67), 60.0, 22.0, 128.0, 2, 1, bolts[0]),
		_unit(Roster.Role.SCOUT, Rect2(95, 43, 66, 71), 50.0, 19.0, 272.0, 1, 0, bolts[0]),
		_unit(Roster.Role.FIGHTER, Rect2(168, 42, 76, 82), 61.0, 22.0, 151.0, 2, 1, bolts[0]),
		_unit(Roster.Role.FIGHTER, Rect2(250, 41, 87, 77), 64.0, 24.0, 149.0, 2, 2, bolts[1]),
		_unit(Roster.Role.JET, Rect2(344, 44, 92, 72), 57.0, 21.0, 285.0, 1, 0, bolts[0]),
		_unit(Roster.Role.FIGHTER, Rect2(445, 41, 94, 75), 65.0, 24.0, 157.0, 3, 1, bolts[1]),
		_unit(Roster.Role.FIGHTER, Rect2(640, 39, 98, 85), 70.0, 25.0, 145.0, 3, 2, bolts[2]),
		_unit(Roster.Role.SCOUT, Rect2(791, 167, 158, 94), 65.0, 22.0, 279.0, 2, 0, bolts[0]),
		_unit(Roster.Role.FIGHTER, Rect2(1078, 152, 129, 113), 72.0, 25.0, 146.0, 3, 2, bolts[2]),
		_unit(Roster.Role.FIGHTER, Rect2(1237, 160, 151, 102), 74.0, 24.0, 169.0, 3, 2, bolts[1]),
	]


static func formation() -> Dictionary:
	return _unit(Roster.Role.FIGHTER, Rect2(9, 168, 120, 91), 54.0, 21.0, 125.0, 2, 1,
		_sprite(UNITS, Rect2(304, 535, 69, 37)))


static func build_bosses() -> Array[Dictionary]:
	return [
		_boss("Leviathan", Rect2(20, 309, 365, 172), Rect2(397, 533, 71, 42), 184.0, 58.0, 110.0, 30, 3, 1.62),
		_boss("Mothership", Rect2(387, 296, 371, 188), Rect2(391, 629, 81, 49), 196.0, 66.0, 118.0, 41, 4, 1.43),
		_boss("Dreadnought", Rect2(765, 296, 390, 188), Rect2(397, 682, 154, 45), 211.0, 71.0, 154.0, 53, 5, 1.22),
	]


static func effects() -> Array[AtlasTexture]:
	return [
		_sprite(UNITS, Rect2(1123, 593, 42, 29)),
		_sprite(UNITS, Rect2(1194, 588, 47, 41)),
		_sprite(UNITS, Rect2(1272, 585, 54, 45)),
		_sprite(UNITS, Rect2(1352, 580, 68, 52)),
	]


static func _boss(title: String, region: Rect2, shot_region: Rect2, width: float,
		radius: float, speed: float, hull: int, volley: int, interval: float) -> Dictionary:
	var unit := _unit(Roster.Role.BOMBER, region, width, radius, speed, hull, volley,
		_sprite(UNITS, shot_region))
	unit.boss_name = title
	unit.boss_interval = interval
	unit.stats.distance = 225.0
	return unit


static func _unit(role: Roster.Role, region: Rect2, width: float, radius: float,
		speed: float, hull: int, volley: int, bolt: AtlasTexture) -> Dictionary:
	return {
		"role": role,
		"body": _sprite(UNITS, region),
		"space_shot": bolt,
		"stats": {
			"width": width, "radius": radius, "speed": speed, "hull": hull,
			"distance": 95.0 if volley == 0 else 147.0, "volley": volley, "weapon": 0,
		},
	}


static func _sprite(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	texture.filter_clip = true
	return texture
