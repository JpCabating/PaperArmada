extends RefCounted

const SHEET := preload("res://Game Assests/Tilesheet/alien_mega_boss_cutout.png")
const WALL_X := -10.0
const HULL := preload("res://Game Assests/Tilesheet/alien_wall_hull.png")
const HULL_SIZE := Vector2(224, 630)
const POSITION := Vector2(126, 370)
const POD_OFFSETS := [Vector2(-55, -132), Vector2(-57, 128)]
const BEAM_LOCK := 0.85
const ATTACK_PERIOD := 3.6
const BEAM_TIME := 1.55
const BEAM_END := 2.1

var age := 0.0
var attack_clock := 0.0
var attack_index := 0
var emitted := 0
var pods := [36, 36]
var tentacles := _row(356, 422, [306, 411, 510, 614, 724, 856, 975, 994, 1095, 1244, 1394, 1530])
var armor_break := _row(545, 624, [306, 379, 447, 518, 580])
var pod_break := _row(545, 624, [609, 685, 751, 824])
var tentacle_break := _row(545, 624, [849, 948, 1047, 1119])
var core_break := _row(545, 625, [1149, 1247, 1348, 1437, 1521])
var death := _row(647, 798, [305, 465, 626, 794, 984, 1150, 1348, 1522])
var bolts := _row(820, 876, [261, 301, 343, 387, 440, 503, 596, 680, 760, 848, 934, 1028, 1169, 1517])
var sparks := _row(899, 985, [264, 296, 343, 397, 465, 557, 637, 715, 784, 911, 1043, 1098, 1154, 1233, 1336, 1399, 1450, 1516])


func charge_frame() -> int:
	if attack_clock < BEAM_TIME:
		return mini(int(attack_clock * 4.0), 5)
	return 6 if attack_clock < (BEAM_TIME + BEAM_END) * 0.5 else 7


func muzzle(at: Vector2) -> Vector2:
	return Vector2(WALL_X + 141.0, at.y - 8.0)


func _sprite(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = SHEET
	texture.region = region
	texture.filter_clip = true
	return texture


func _row(top: int, bottom: int, columns: Array) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	for index in range(columns.size() - 1):
		if columns[index + 1] - columns[index] > 20:
			frames.append(_sprite(Rect2(columns[index], top, columns[index + 1] - columns[index], bottom - top)))
	return frames
