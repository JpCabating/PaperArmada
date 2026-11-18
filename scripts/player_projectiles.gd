extends RefCounted

const SHEET := preload("res://Game Assests/Tilesheet/Bullets Tile.png")

enum Kind { STANDARD, TRIPLE, RAPID, PLASMA, LASER, MISSILE, HOMING,
	EXPLOSIVE, PIERCING, SPREAD, WAVE, ORB }

class Weapon:
	var title: String
	var interval: float
	var speed: float
	var width: float
	var damage: int
	var hits: int
	var blast_radius: float
	var turn_rate: float
	var spin_speed: float
	var frames: Array[AtlasTexture] = []
	var angles: Array[float]


static func build() -> Array[Weapon]:
	return [
		_weapon("Standard", 0.14, 710.0, 24.0, 1, 1, 0.0, 0.0,
			[Rect2(316, 198, 88, 35), Rect2(440, 196, 91, 38), Rect2(555, 196, 98, 38), Rect2(674, 195, 112, 41)], [0.0]),
		_weapon("Triple", 0.2, 730.0, 25.0, 1, 1, 0.0, 0.0,
			[Rect2(316, 30, 98, 35), Rect2(467, 28, 96, 37), Rect2(601, 25, 110, 41)], [0.0, 0.0, 0.0]),
		_weapon("Rapid", 0.075, 880.0, 26.0, 1, 1, 0.0, 0.0,
			[Rect2(316, 198, 88, 35), Rect2(440, 196, 91, 38), Rect2(555, 196, 98, 38), Rect2(674, 195, 112, 41)], [0.0]),
		_weapon("Plasma", 0.24, 575.0, 37.0, 3, 1, 0.0, 0.0,
			[Rect2(313, 266, 90, 47), Rect2(432, 263, 103, 53), Rect2(560, 262, 104, 56), Rect2(694, 260, 104, 60)], [0.0]),
		_weapon("Laser", 0.2, 1250.0, 52.0, 2, 2, 0.0, 0.0,
			[Rect2(302, 338, 105, 65), Rect2(424, 335, 120, 70), Rect2(550, 335, 158, 70), Rect2(709, 332, 246, 76)], [0.0]),
		_weapon("Missile", 0.35, 510.0, 43.0, 4, 1, 63.0, 0.0,
			[Rect2(308, 425, 118, 55), Rect2(457, 423, 126, 58), Rect2(599, 419, 153, 65), Rect2(772, 415, 158, 74)], [0.0]),
		_weapon("Homing", 0.32, 530.0, 38.0, 3, 1, 0.0, 3.2,
			[Rect2(307, 499, 113, 49), Rect2(462, 504, 107, 41), Rect2(601, 502, 131, 43), Rect2(770, 502, 145, 47)], [0.0]),
		_weapon("Explosive", 0.4, 475.0, 33.0, 3, 1, 106.0, 0.0,
			[Rect2(329, 571, 73, 62), Rect2(467, 571, 75, 62), Rect2(595, 570, 90, 65), Rect2(735, 568, 87, 68), Rect2(858, 568, 70, 72)], [0.0]),
		_weapon("Piercing", 0.2, 925.0, 36.0, 2, 4, 0.0, 0.0,
			[Rect2(314, 659, 94, 43), Rect2(440, 657, 130, 48), Rect2(590, 652, 149, 55), Rect2(747, 651, 186, 56)], [0.0]),
		_weapon("Spread", 0.24, 665.0, 26.0, 1, 1, 0.0, 0.0,
			[Rect2(333, 740, 82, 28), Rect2(478, 739, 92, 31), Rect2(633, 740, 103, 30), Rect2(805, 739, 127, 32)], [-0.32, -0.16, 0.0, 0.16, 0.32]),
		_weapon("Wave", 0.23, 625.0, 33.0, 2, 2, 0.0, 0.0,
			[Rect2(325, 815, 47, 49), Rect2(435, 814, 64, 51), Rect2(555, 808, 87, 65), Rect2(688, 804, 108, 73)], [0.0]),
		_weapon("Energy Orb", 0.31, 420.0, 41.0, 4, 3, 0.0, 0.0,
			[Rect2(334, 892, 79, 76), Rect2(476, 885, 97, 92), Rect2(619, 878, 119, 105), Rect2(786, 874, 152, 111)], [0.0], TAU * 4.0),
	]


static func _weapon(title: String, interval: float, speed: float, width: float, damage: int,
		hits: int, blast_radius: float, turn_rate: float, regions: Array[Rect2],
		angles: Array[float], spin_speed := 0.0) -> Weapon:
	var weapon := Weapon.new()
	weapon.title = title
	weapon.interval = interval
	weapon.speed = speed
	weapon.width = width
	weapon.damage = damage
	weapon.hits = hits
	weapon.blast_radius = blast_radius
	weapon.turn_rate = turn_rate
	weapon.spin_speed = spin_speed
	weapon.angles = angles
	for region in regions:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = region
		frame.filter_clip = true
		weapon.frames.append(frame)
	return weapon
