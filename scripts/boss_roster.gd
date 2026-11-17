extends RefCounted

const Roster := preload("res://scripts/enemy_roster.gd")
const SHEET := preload("res://Scribble-Planes/Tilesheet/Bosses-units.png")


static func build() -> Array[Dictionary]:
	return [
		{
			"boss_name": "Boss Tank",
			"role": Roster.Role.TANK,
			"body": _sprite(Rect2(1297, 3, 430, 447)),
			"boss_shot": _sprite(Rect2(37, 691, 62, 140)),
			"boss_interval": 1.9,
			"stats": {"width": 142.0, "radius": 54.0, "speed": 56.0, "hull": 24,
				"distance": 0.0, "volley": 2, "weapon": 0},
		},
		{
			"boss_name": "Boss Plane",
			"role": Roster.Role.BOMBER,
			"body": _sprite(Rect2(0, 3, 727, 455)),
			"boss_shot": _sprite(Rect2(225, 641, 137, 245)),
			"boss_interval": 1.55,
			"stats": {"width": 207.0, "radius": 68.0, "speed": 105.0, "hull": 33,
				"distance": 230.0, "volley": 3, "weapon": 2},
		},
		{
			"boss_name": "Boss Jet",
			"role": Roster.Role.JET,
			"body": _sprite(Rect2(730, 3, 555, 428)),
			"boss_shot": _sprite(Rect2(1581, 696, 86, 170)),
			"boss_interval": 1.15,
			"stats": {"width": 185.0, "radius": 62.0, "speed": 190.0, "hull": 44,
				"distance": 205.0, "volley": 5, "weapon": 0},
		},
	]


static func _sprite(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = SHEET
	texture.region = region
	texture.filter_clip = true
	return texture
