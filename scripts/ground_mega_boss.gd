extends RefCounted

const LIZARD := preload("res://Game Assests/Tilesheet/lizard_resprite_cutout.png")
const SHARK := preload("res://Game Assests/Tilesheet/shark_mega_cutout.png")
const FIRE_TIME := 1.25
const FIRE_END := 1.83
const PERIOD := 3.35
const LIZARD_BEAM_LOCK := 0.72
const LIZARD_BEAM_POSE := 4

var shark: bool
var slot: int
var age := 0.0
var clock := 0.0
var pattern: int
var emitted := 0
var travel_time := 0.0
var beam_start := Vector2.ZERO
var beam_end := Vector2.ZERO
var idle: Array[AtlasTexture]
var charge: Array[AtlasTexture]
var fire: Array[AtlasTexture]
var barrage: Array[AtlasTexture]
var sweep: Array[AtlasTexture]
var death: Array[AtlasTexture]
var projectiles: Array[AtlasTexture]
var rockets: Array[AtlasTexture]
var walk: Array[AtlasTexture]
var stomp: Array[AtlasTexture]
var shockwave: Array[AtlasTexture]
var debris: Array[AtlasTexture]
var cracks: Array[AtlasTexture]
var armor_fragments: Array[AtlasTexture]
var beam_flash: AtlasTexture
var plasma_bolt: AtlasTexture
var blast: Array[AtlasTexture]


func faces_left() -> bool:
	return shark or (pattern != 0 and sin(travel_time * 0.55) < 0.0)


func lizard_pose() -> Vector2i:
	if pattern == 0 and age >= 0.75 and clock < 2.2:
		var index := LIZARD_BEAM_POSE
		if clock < LIZARD_BEAM_LOCK:
			index = mini(int(clock / LIZARD_BEAM_LOCK * LIZARD_BEAM_POSE), LIZARD_BEAM_POSE - 1)
		elif clock >= FIRE_END:
			return Vector2i(5, 4 + mini(int((clock - FIRE_END) * 6.0), 1))
		else:
			return Vector2i(5, 3)
		return Vector2i(1, index)
	if age >= 0.75 and pattern != 0 and clock < 2.2:
		var frames := barrage if pattern == 1 else sweep
		return Vector2i(pattern + 1, mini(int(clock / 2.2 * frames.size()), frames.size() - 1))
	if age >= 0.75:
		return Vector2i(4, int(travel_time * 12.0) % walk.size())
	return Vector2i(0, int(age * 12.0) % idle.size())


func lizard_texture(pose: Vector2i) -> AtlasTexture:
	var banks := [idle, charge, barrage, sweep, walk, fire]
	return banks[pose.x][pose.y]


func lizard_scale(_pose: Vector2i, width: float) -> float:
	return width / 155.0


func lizard_foot_x(pose: Vector2i) -> float:
	const FEET := [
		[105, 102, 107, 106, 104, 107, 105, 104, 111],
		[103, 104, 102, 105, 104, 104, 105, 102, 106, 106],
		[103, 104, 102, 105, 104, 104, 105, 102, 106, 106],
		[102, 108, 106, 105, 103, 103, 103, 103, 103],
		[104, 104, 103, 105, 104, 105, 105, 107, 108, 108],
		[102, 105, 104, 106, 108, 108],
	]
	return FEET[pose.x][pose.y]


func lizard_muzzle(at: Vector2, width: float) -> Vector2:
	var pose := lizard_pose()
	if pose.x == 1 or pose.x == 5:
		const MOUTHS := [
			Vector2(133, 35), Vector2(136, 35), Vector2(136, 34), Vector2(134, 33),
			Vector2(133, 31),
		]
		var source: Vector2 = Vector2(121, 40) if pose.x == 5 else MOUTHS[pose.y]
		return at + Vector2(source.x - lizard_foot_x(pose), source.y - lizard_texture(pose).get_height()) * lizard_scale(pose, width) + Vector2(0, 105)
	return at + Vector2(-93 if faces_left() else 93, -85)


func _init(is_shark: bool, index: int) -> void:
	shark = is_shark
	slot = index
	pattern = index
	if shark:
		idle = _row(7, 124, [307, 476, 638, 792, 959, 1138, 1334, 1533])
		charge = _row(267, 377, [10, 182, 352, 524, 700, 872, 1038])
		fire = _row(135, 250, [307, 474, 638, 806, 986, 1163, 1344, 1533])
		barrage = _row(390, 501, [12, 184, 351, 518, 688, 849, 1022, 1197, 1367, 1534])
		sweep = _row(511, 622, [12, 190, 384, 566, 757, 949, 1149, 1344, 1534])
		death = _row(635, 743, [481, 674, 847, 1014, 1183, 1357, 1533])
		projectiles = _row(770, 805, [499, 532, 573, 616, 688])
		projectiles.append_array(_row(770, 805, [719, 756, 788, 823]))
		rockets = _row(764, 810, [22, 134, 241, 344, 461])
		blast = _row(818, 900, [929, 992, 1081, 1181, 1310])
	else:
		idle = _row(9, 115, [35, 202, 372, 542, 721, 899, 1076, 1259, 1447, 1640])
		walk = _row(118, 219, [31, 197, 362, 526, 695, 858, 1020, 1176, 1330, 1487, 1640])
		charge = _row(222, 321, [31, 194, 359, 520, 684, 840, 1003, 1179, 1343, 1494, 1640])
		fire = _row(328, 416, [33, 197, 356, 526, 694])
		fire.append_array(_row(328, 416, [1234, 1378, 1512]))
		barrage = charge
		sweep = _row(422, 509, [40, 211, 385, 562, 734, 916, 1099, 1281, 1468, 1650])
		death = _row(512, 614, [34, 210, 389, 565, 743, 929, 1123, 1310, 1494, 1650])
		projectiles = _row(712, 762, [42, 73, 106, 145, 192, 261])
		plasma_bolt = _row(708, 766, [263, 359])[0]
		beam_flash = _row(710, 767, [459, 755])[0]
		blast = _row(702, 773, [768, 827, 901, 982, 1079])
		debris = _row(702, 771, [1094, 1192, 1270, 1363])
		armor_fragments = _row(627, 690, [690, 769, 847, 924, 1011])
		stomp = _row(773, 831, [67, 139, 221, 315, 405, 502, 610, 720])
		shockwave = _row(778, 829, [911, 1007, 1119, 1246])
		cracks = _row(777, 831, [1274, 1381, 1469, 1550, 1640])


func _row(top: int, bottom: int, columns: Array) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	for index in range(columns.size() - 1):
		var texture := AtlasTexture.new()
		texture.atlas = SHARK if shark else LIZARD
		texture.region = Rect2(columns[index], top, columns[index + 1] - columns[index], bottom - top)
		texture.filter_clip = true
		frames.append(texture)
	return frames
