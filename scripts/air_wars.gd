extends Node2D

const CENTER := Vector2(640, 360)
const ARENA := Rect2(0, 0, 1280, 720)
const FLIGHT_BOUNDS := Rect2(30, 101, 1220, 565)
const MAX_HULL := 5
const OUTPOST_POSITION := Vector2(218, 367)
const OUTPOST_RADIUS := 65.0
const OUTPOST_MAX_HULL := 16
const DEFENDER_START := Vector2(437, 380)
const OUTPOST := preload("res://scenes/defender_hq.tres")
const PlayerProjectiles := preload("res://scripts/player_projectiles.gd")
const MAX_PICKUPS := 4
const PICKUP_LIFETIME := 15.0
const WEAPON_DURATION := 12.0
const SHIELD_HITS := 5
const INK := Color("#25333d")
const MUTED := Color("#50616b")
const PAPER := Color("#f7f7f1")
const PLAYER_TRACER_CORE := Color("#fff5b8")
const ORANGE := Color("#bd4931")
const BLUE := Color("#5c91ac")
const PLAYER := preload("res://Game Assests/PNG/Default/unit_plane_a.png")
const Roster := preload("res://scripts/enemy_roster.gd")
const Bosses := preload("res://scripts/boss_roster.gd")
const SpaceRoster := preload("res://scripts/space_roster.gd")
const CityRoster := preload("res://scripts/city_roster.gd")
const AlienMegaBoss := preload("res://scripts/alien_mega_boss.gd")
const GroundMegaBoss := preload("res://scripts/ground_mega_boss.gd")
const RUSH_ROUNDS := 4
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]
const DIFFICULTY_CARDS := [Rect2(420, 228, 140, 74), Rect2(570, 228, 140, 74), Rect2(720, 228, 140, 74)]
const TAKEOFF_BUTTON := Rect2(550, 322, 180, 40)
const MAIN_MENU_BUTTON := Rect2(550, 373, 180, 31)
const MAIN_MENU := "res://scenes/main_menu.tscn"
const UI_FONT := preload("res://scenes/ui_text_font.tres")
const TITLE_FONT := preload("res://scenes/ui_ink_font.tres")
const MUZZLE := preload("res://Game Assests/PNG/Default/effect_muzzle.png")
const SPARK := preload("res://Game Assests/PNG/Default/effect_spark.png")
const SELECTION := preload("res://Game Assests/PNG/Default/selection.png")
const PICKUP_ART := preload("res://Game Assests/PNG/Default/power_up.png")
const ROUND_ART := [
	preload("res://Game Assests/PNG/Default/projectile_round_colored.png"),
	preload("res://Game Assests/PNG/Default/projectile_round.png"),
]
const ROCKET_ART := [
	preload("res://Game Assests/PNG/Default/projectile_rocket_a.png"),
	preload("res://Game Assests/PNG/Default/projectile_rocket_b.png"),
	preload("res://Game Assests/PNG/Default/projectile_rocket_c.png"),
	preload("res://Game Assests/PNG/Default/projectile_rocket_d.png"),
]
const TRAIL_ART := [
	preload("res://Game Assests/PNG/Default/effect_smoke_trail_0.png"),
	preload("res://Game Assests/PNG/Default/effect_smoke_trail_1.png"),
]
const SMOKE := [
	preload("res://Game Assests/PNG/Default/explosion_smoke_0.png"),
	preload("res://Game Assests/PNG/Default/explosion_smoke_1.png"),
	preload("res://Game Assests/PNG/Default/explosion_smoke_2.png"),
	preload("res://Game Assests/PNG/Default/explosion_smoke_3.png"),
]
const FIRE := [
	preload("res://Game Assests/PNG/Default/explosion_fire_0.png"),
	preload("res://Game Assests/PNG/Default/explosion_fire_1.png"),
	preload("res://Game Assests/PNG/Default/explosion_fire_2.png"),
	preload("res://Game Assests/PNG/Default/explosion_fire_3.png"),
]

enum Phase { BRIEFING, INCOMING, COMBAT, GAME_OVER, VICTORY }
enum Mode { ENDLESS, DEFENDER, BOSS_RUSH }
enum Difficulty { EASY, NORMAL, HARD }
enum Supply { REPAIR, SHIELD, WEAPON }

class Enemy:
	var position: Vector2
	var heading: float
	var body_heading: float
	var role: Roster.Role
	var body: Texture2D
	var attachment: Texture2D
	var width: float
	var radius: float
	var speed: float
	var preferred_distance: float
	var volley: int
	var weapon: int
	var hull: int
	var max_hull: int
	var shot_timer: float
	var breaking_away := false
	var breakaway_heading := 0.0
	var route: PackedVector2Array
	var destination := 1
	var turret_site: Marker2D
	var boss_name := ""
	var boss_shot: Texture2D
	var boss_interval := 0.0
	var space_shot: Texture2D
	var city_shot: Texture2D
	var walk_frames: Array[AtlasTexture] = []
	var walk_distance := 0.0
	var walking := false
	var flight_frames: Array[AtlasTexture] = []
	var left_frames: Array[AtlasTexture] = []
	var idle_frames: Array[AtlasTexture] = []
	var attack_frames: Array[AtlasTexture] = []
	var side_view := false
	var animation_time := 0.0
	var attack_time := 0.0
	var in_formation := false
	var formation_offset := Vector2.ZERO
	var mega: AlienMegaBoss
	var ground_mega: GroundMegaBoss

class Shot:
	var energy := Color.TRANSPARENT
	var pulse_frames: Array[AtlasTexture] = []
	var impact_frames: Array[AtlasTexture] = []
	var position: Vector2
	var velocity: Vector2
	var hostile: bool
	var art: Texture2D
	var rocket := false
	var age := 0.0
	var weapon: PlayerProjectiles.Weapon
	var remaining_hits := 0
	var hit_targets: Array[Enemy] = []
	var launch_heading := 0.0

class Burst:
	var frames: Array[AtlasTexture] = []
	var duration := 0.4
	var position: Vector2
	var age := 0.0
	var size: float
	var impact := false

class Pickup:
	var position: Vector2
	var supply: Supply
	var weapon_kind := PlayerProjectiles.Kind.STANDARD
	var lifetime := PICKUP_LIFETIME

var phase := Phase.BRIEFING
var difficulty := Difficulty.NORMAL
@export var mode := Mode.ENDLESS
@export var space_arena := false
@export var city_arena := false

var player_position := CENTER
var outpost_hull := OUTPOST_MAX_HULL
var outpost_hit_timer := 0.0
var player_heading := 0.0
var hull := MAX_HULL
var wave := 1
var score := 0
static var best_scores := [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
var remaining_spawns := 0
var spawn_timer := 0.0
var wave_timer := 0.0
var fire_timer := 0.0
var invulnerable := 0.0
var muzzle_timer := 0.0
var elapsed := 0.0
var shield_hits := 0
var rush_supply_timer := 0.0
var weapon_time := 0.0
var weapon_mode := PlayerProjectiles.Kind.STANDARD
var bosses := Bosses.build()
var solo_boss_order: Array[Dictionary] = []
var wave_bosses: Array[Dictionary] = []
var space_bosses: Array[Dictionary] = []
var space_units: Array[Dictionary] = []
var city_units: Array[Dictionary] = []
var ship_frames: Array[AtlasTexture] = []
var space_effects: Array[AtlasTexture] = []
var thrusting := false
var formation_size := 0
var formation_time := 0.0
var formation_anchor := Vector2.ZERO
var score_group := 0
var player_projectiles := PlayerProjectiles.build()
var wave_roster: Array[Dictionary] = []
var roster_index := 0
var ground_lane_index := 0
var water_lane_index := 0
var enemies: Array[Enemy] = []
var shots: Array[Shot] = []
var bursts: Array[Burst] = []
var pickups: Array[Pickup] = []

@onready var ground_lanes := $Coast/GroundLanes
@onready var water_lanes := $Coast/WaterLanes
@onready var turret_sites := $Coast/TurretSites


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if phase not in [Phase.BRIEFING, Phase.GAME_OVER, Phase.VICTORY]:
		return
	if mode == Mode.BOSS_RUSH and event.physical_keycode not in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		return
	match event.physical_keycode:
		KEY_1: difficulty = Difficulty.EASY
		KEY_2: difficulty = Difficulty.NORMAL
		KEY_3: difficulty = Difficulty.HARD
		KEY_LEFT, KEY_A: difficulty = clampi(difficulty - 1, Difficulty.EASY, Difficulty.HARD) as Difficulty
		KEY_RIGHT, KEY_D: difficulty = clampi(difficulty + 1, Difficulty.EASY, Difficulty.HARD) as Difficulty
		KEY_ENTER, KEY_KP_ENTER: _start_run()
		KEY_ESCAPE:
			_return_to_main_menu()
			return
		_: return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if phase not in [Phase.BRIEFING, Phase.GAME_OVER, Phase.VICTORY]:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse := get_local_mouse_position()
		for index in range(DIFFICULTY_CARDS.size()):
			if mode != Mode.BOSS_RUSH and DIFFICULTY_CARDS[index].has_point(mouse):
				difficulty = index as Difficulty
				get_viewport().set_input_as_handled()
				return
		if TAKEOFF_BUTTON.has_point(mouse):
			_start_run()
			get_viewport().set_input_as_handled()
		elif MAIN_MENU_BUTTON.has_point(mouse):
			_return_to_main_menu()


func _return_to_main_menu() -> void:
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file(MAIN_MENU)


func _ready() -> void:
	add_child(preload("res://scenes/pause_menu.tscn").instantiate())
	if city_arena:
		city_units = CityRoster.build_units()
		bosses = CityRoster.build_bosses()
	score_group = 2 if space_arena else mode
	if mode == Mode.BOSS_RUSH:
		difficulty = Difficulty.HARD
		score_group = 5 if space_arena else (4 if city_arena else 3)
	if space_arena:
		space_units = SpaceRoster.build_units()
		space_bosses = SpaceRoster.build_bosses()
		ship_frames = SpaceRoster.player_frames()
		space_effects = SpaceRoster.effects()
	if mode == Mode.DEFENDER:
		player_position = DEFENDER_START


func _start_run() -> void:
	thrusting = false
	player_position = DEFENDER_START if mode == Mode.DEFENDER else CENTER
	outpost_hull = OUTPOST_MAX_HULL
	outpost_hit_timer = 0.0
	player_heading = 0.0
	hull = MAX_HULL
	wave = 1
	solo_boss_order.clear()
	score = 0
	fire_timer = 0.0
	invulnerable = 0.0
	muzzle_timer = 0.0
	enemies.clear()
	shots.clear()
	bursts.clear()
	pickups.clear()
	if mode == Mode.BOSS_RUSH:
		rush_supply_timer = randf_range(10.0, 15.0)
	shield_hits = 0
	weapon_time = 0.0
	weapon_mode = PlayerProjectiles.Kind.STANDARD
	ground_lane_index = 0
	water_lane_index = 0
	_prepare_wave(1.8)


func _prepare_wave(countdown: float) -> void:
	phase = Phase.INCOMING
	wave_timer = countdown
	shots.clear()
	remaining_spawns = 0
	wave_bosses.clear()
	if mode == Mode.BOSS_RUSH and wave < RUSH_ROUNDS:
		var roster := space_bosses if space_arena else bosses
		wave_bosses.append(roster[wave - 1])
		return
	if _is_mega_boss_wave():
		_prepare_mega_bosses()
		return
	if wave % 5 != 0:
		return
	if _is_boss_trio_wave():
		wave_bosses.assign(space_bosses if space_arena else bosses)
	elif space_arena:
		wave_bosses.append(space_bosses[(floori(wave / 5.0) - 1) % space_bosses.size()])
	elif mode == Mode.ENDLESS:
		if wave % 20 == 5 or solo_boss_order.is_empty():
			solo_boss_order.assign(bosses)
			solo_boss_order.shuffle()
		wave_bosses.append(solo_boss_order[floori((wave % 20) / 5.0) - 1])
	else:
		wave_bosses.append(bosses[difficulty])


func _prepare_mega_bosses() -> void:
	var encounter_wave := 20 if mode == Mode.BOSS_RUSH else wave
	if space_arena:
		var combined_hull := 0
		for boss in space_bosses:
			combined_hull += int(boss.stats.hull) + encounter_wave * 2
		wave_bosses.append({
			"boss_name": "Alien Mega Boss", "role": Roster.Role.BOMBER,
			"mega": true, "stats": {"radius": 100.0, "hull": combined_hull + 72},
		})
	elif city_arena:
		wave_bosses.append({"boss_name": "Lizard Mega Boss", "ground_mega": true, "slot": 0,
			"stats": {"radius": 105.0, "width": 390.0, "hull": 190 + encounter_wave * 8}})
	else:
		for slot in range(3):
			wave_bosses.append({"boss_name": "Mega Shark %s" % ["I", "II", "III"][slot],
				"ground_mega": true, "slot": slot,
				"stats": {"radius": 55.0, "width": 170.0, "hull": 64 + encounter_wave * 3}})


func _physics_process(delta: float) -> void:
	elapsed += delta
	for index in range(bursts.size() - 1, -1, -1):
		bursts[index].age += delta
		if bursts[index].age >= bursts[index].duration:
			bursts.remove_at(index)
	if phase == Phase.INCOMING or phase == Phase.COMBAT:
		if mode == Mode.BOSS_RUSH:
			_update_rush_supplies(delta)
		if phase == Phase.COMBAT:
			_tick_supplies(delta)
			outpost_hit_timer = maxf(0.0, outpost_hit_timer - delta)
		_update_player(delta)
		if phase == Phase.INCOMING:
			wave_timer -= delta
			if wave_timer <= 0.0:
				_begin_combat()
		else:
			_update_combat(delta)
	queue_redraw()


func _update_player(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
		- float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		- float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	thrusting = not direction.is_zero_approx()
	player_position += direction.normalized() * 310.0 * delta
	player_position = player_position.clamp(FLIGHT_BOUNDS.position, FLIGHT_BOUNDS.end)
	var aim := get_global_mouse_position() - player_position
	if aim.length_squared() >= 16.0:
		player_heading = aim.angle() + PI / 2.0
	fire_timer -= delta
	invulnerable = maxf(invulnerable - delta, 0.0)
	muzzle_timer = maxf(muzzle_timer - delta, 0.0)
	if phase == Phase.COMBAT and fire_timer <= 0.0:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_SPACE):
			_fire_player()
	_collect_pickups()


func _fire_player() -> void:
	var weapon := player_projectiles[weapon_mode]
	var forward := Vector2.UP.rotated(player_heading)
	var muzzle := player_position + forward * 27.0
	for index in range(weapon.angles.size()):
		var origin := muzzle
		if weapon_mode == PlayerProjectiles.Kind.TRIPLE:
			origin += forward.orthogonal() * (index - 1) * 12.0
		_launch_shot(origin, forward.rotated(weapon.angles[index]) * weapon.speed, false)
	fire_timer = weapon.interval
	muzzle_timer = 0.065


func _tick_supplies(delta: float) -> void:
	weapon_time = maxf(0.0, weapon_time - delta)
	if weapon_time == 0.0:
		weapon_mode = PlayerProjectiles.Kind.STANDARD
	for index in range(pickups.size() - 1, -1, -1):
		pickups[index].lifetime -= delta
		if pickups[index].lifetime <= 0.0:
			pickups.remove_at(index)


func _update_rush_supplies(delta: float) -> void:
	rush_supply_timer -= delta
	if rush_supply_timer > 0.0:
		return
	rush_supply_timer += randf_range(10.0, 15.0)
	var available: Array[Supply] = [Supply.WEAPON]
	if hull < MAX_HULL:
		available.append(Supply.REPAIR)
	if shield_hits < SHIELD_HITS:
		available.append(Supply.SHIELD)
	var position := Vector2(randf_range(395.0, 885.0), randf_range(275.0, 610.0))
	_drop_supply(position, available.pick_random(), true)


func _collect_pickups() -> void:
	for index in range(pickups.size() - 1, -1, -1):
		var pickup := pickups[index]
		if player_position.distance_squared_to(pickup.position) >= 900.0:
			continue
		match pickup.supply:
			Supply.REPAIR:
				if hull == MAX_HULL:
					continue
				hull += 1
			Supply.SHIELD:
				if shield_hits == SHIELD_HITS:
					continue
				shield_hits = SHIELD_HITS
			Supply.WEAPON:
				weapon_mode = pickup.weapon_kind
				weapon_time = WEAPON_DURATION
		pickups.remove_at(index)


func _update_combat(delta: float) -> void:
	if space_arena:
		formation_time += delta
		formation_anchor = _formation_position(formation_time)
	spawn_timer -= delta
	if remaining_spawns > 0 and spawn_timer <= 0.0:
		if formation_size > 0 and remaining_spawns == _wave_size(wave, difficulty):
			_spawn_formation()
			remaining_spawns -= formation_size
		elif not wave_bosses.is_empty() and remaining_spawns == wave_bosses.size():
			for boss in wave_bosses:
				_spawn_enemy(boss)
			remaining_spawns = 0
		else:
			_spawn_enemy()
			remaining_spawns -= 1
		var wave_interval := 0.14 + 0.925 * pow(0.88, wave - 1)
		spawn_timer = wave_interval * [1.25, 1.0, 0.85][difficulty]
	_update_enemies(delta)
	if phase == Phase.GAME_OVER:
		return
	_update_shots(delta)
	if phase == Phase.COMBAT and remaining_spawns == 0 and enemies.is_empty():
		score += wave * 100
		best_scores[score_group][difficulty] = maxi(best_scores[score_group][difficulty], score)
		if mode == Mode.DEFENDER:
			outpost_hull = mini(OUTPOST_MAX_HULL, outpost_hull + 2)
		if mode == Mode.BOSS_RUSH and wave == RUSH_ROUNDS:
			phase = Phase.VICTORY
			shots.clear()
			return
		wave += 1
		_prepare_wave(3.0)


func _wave_size(wave_number: int, mode: Difficulty) -> int:
	match mode:
		Difficulty.EASY: return mini(4 + wave_number, 18)
		Difficulty.HARD: return mini(7 + wave_number * 3, 36)
		_: return mini(4 + wave_number * 2, 26)


func _begin_combat() -> void:
	phase = Phase.COMBAT
	if mode == Mode.BOSS_RUSH or _is_mega_boss_wave():
		formation_size = 0
		remaining_spawns = 0
		for boss in wave_bosses:
			_spawn_enemy(boss)
		return
	remaining_spawns = _wave_size(wave, difficulty)
	spawn_timer = 0.0
	wave_roster.clear()
	if space_arena:
		formation_size = mini(remaining_spawns - 2, 4 + mini(floori(wave / 3.0), 4))
		formation_time = 0.0
		formation_anchor = _formation_position(0.0)
		wave_roster.assign(space_units)
		roster_index = (wave - 1) % wave_roster.size()
		return
	var unlock_wave := maxi(1, wave + difficulty - Difficulty.NORMAL)
	var units: Array = city_units if city_arena else Roster.UNITS
	for unit in units:
		if mode == Mode.DEFENDER and unit.role in [Roster.Role.TANK, Roster.Role.TURRET]:
			continue
		if unit.wave <= unlock_wave and (unit.role != Roster.Role.AIRSHIP or wave >= 8):
			wave_roster.append(unit)
	roster_index = (wave - 1) * 3 % wave_roster.size()


func _next_unit() -> Dictionary:
	var unit := wave_roster[roster_index]
	roster_index = (roster_index + 1) % wave_roster.size()
	return unit


func _is_boss_trio_wave() -> bool:
	return mode == Mode.ENDLESS and wave % 20 == 0


func _is_mega_boss_wave() -> bool:
	return (mode == Mode.BOSS_RUSH and wave == RUSH_ROUNDS) or (
		difficulty == Difficulty.HARD and _is_boss_trio_wave())


func _spawn_enemy(override_unit: Dictionary = {}) -> Enemy:
	var unit := _next_unit() if override_unit.is_empty() else override_unit
	var enemy := Enemy.new()
	var rush := mode == Mode.BOSS_RUSH
	if unit.get("ground_mega", false):
		enemy.ground_mega = GroundMegaBoss.new(not city_arena, unit.slot)
		enemy.position = _ground_mega_position(enemy.ground_mega)
		enemy.boss_name = unit.boss_name
		enemy.radius = unit.stats.radius
		enemy.width = unit.stats.width
		enemy.hull = ceili(unit.stats.hull * (1.35 if rush else 1.0))
		enemy.max_hull = enemy.hull
		enemies.append(enemy)
		return enemy
	if unit.get("mega", false):
		enemy.mega = AlienMegaBoss.new()
		enemy.position = AlienMegaBoss.POSITION
		enemy.role = unit.role
		enemy.boss_name = unit.boss_name
		enemy.radius = unit.stats.radius
		enemy.hull = ceili(unit.stats.hull * (1.35 if rush else 1.0))
		enemy.max_hull = enemy.hull
		enemies.append(enemy)
		return enemy
	if unit.role == Roster.Role.TURRET:
		var free_sites: Array[Marker2D] = []
		for site: Marker2D in turret_sites.get_children():
			if not enemies.any(func(active: Enemy) -> bool: return active.turret_site == site):
				free_sites.append(site)
		if free_sites.is_empty():
			unit = Roster.UNITS[0]
		else:
			enemy.turret_site = free_sites.pick_random()
			enemy.position = enemy.turret_site.global_position
	enemy.role = unit.role
	enemy.body = unit.body
	enemy.attachment = unit.get("top")
	enemy.boss_name = unit.get("boss_name", "")
	enemy.boss_shot = unit.get("boss_shot")
	enemy.boss_interval = unit.get("boss_interval", 0.0)
	enemy.space_shot = unit.get("space_shot")
	enemy.city_shot = unit.get("city_shot")
	if unit.has("walk_frames"):
		enemy.walk_frames.assign(unit.walk_frames)
	if unit.has("flight_frames"):
		enemy.flight_frames.assign(unit.flight_frames)
		enemy.side_view = unit.side_view
	if unit.has("left_frames"):
		enemy.left_frames.assign(unit.left_frames)
		enemy.idle_frames.assign(unit.idle_frames)
		enemy.attack_frames.assign(unit.attack_frames)
	var stats: Dictionary = unit.get("stats", Roster.STATS[enemy.role])
	enemy.width = stats.width
	enemy.radius = stats.radius
	enemy.speed = stats.speed
	enemy.preferred_distance = stats.distance
	enemy.volley = stats.volley
	enemy.weapon = stats.weapon
	enemy.hull = stats.hull
	if not enemy.boss_name.is_empty():
		enemy.hull += wave * 2
		if rush:
			enemy.hull = ceili((stats.hull + 40) * 1.35)
			enemy.boss_interval *= 0.7
			enemy.volley += 2
			enemy.speed *= 1.2
	elif enemy.hull > 1:
		enemy.hull += mini(floori(wave / 5.0), 3)
	enemy.max_hull = enemy.hull
	enemy.shot_timer = randf_range(0.85, 1.65)

	match enemy.role:
		Roster.Role.TANK:
			if mode == Mode.DEFENDER:
				_set_patrol(enemy, ground_lanes.get_child(0) as Line2D)
				enemy.route.reverse()
				enemy.position = enemy.route[0]
				enemy.body_heading = -PI / 2.0
			else:
				_set_patrol(enemy, ground_lanes.get_child(ground_lane_index) as Line2D)
				ground_lane_index = (ground_lane_index + 1) % ground_lanes.get_child_count()
		Roster.Role.PATROL:
			_set_patrol(enemy, water_lanes.get_child(water_lane_index) as Line2D)
			water_lane_index = (water_lane_index + 1) % water_lanes.get_child_count()
			if mode == Mode.DEFENDER:
				enemy.route.reverse()
				enemy.position = Vector2(1338.0, enemy.route[0].y)
				enemy.body_heading = -PI / 2.0
		Roster.Role.TURRET:
			enemy.body_heading = 0.0
		_:
			enemy.position = _air_spawn_position()
			enemy.speed += minf(wave * 4.0, 42.0)
	var target := OUTPOST_POSITION if mode == Mode.DEFENDER else player_position
	enemy.heading = enemy.position.direction_to(target).angle() + PI / 2.0
	if enemy.route.is_empty() and enemy.role != Roster.Role.TURRET:
		enemy.body_heading = enemy.heading
	enemies.append(enemy)
	return enemy


func _formation_position(time: float) -> Vector2:
	if time < 1.45:
		return Vector2(350.0, lerpf(-60.0, 177.0, time / 1.45))
	var sweep_time := time - 1.45
	var sweep := floori(sweep_time / 3.7)
	var progress := fposmod(sweep_time, 3.7)
	var across := minf(progress / 3.35, 1.0)
	var x := lerpf(350.0, 930.0, across if sweep % 2 == 0 else 1.0 - across)
	var drop := clampf((progress - 3.35) / 0.35, 0.0, 1.0)
	var y := 177.0 + pingpong(float(sweep) + drop, 7.0) * 29.0
	return Vector2(x, y)


func _spawn_formation() -> void:
	var unit := SpaceRoster.formation()
	var columns := mini(formation_size, 4)
	for slot in range(formation_size):
		var row := floori(float(slot) / columns)
		var row_size := mini(columns, formation_size - row * columns)
		var enemy := _spawn_enemy(unit)
		enemy.in_formation = true
		enemy.formation_offset = Vector2((slot % columns - (row_size - 1) * 0.5) * 70.0, row * 54.0)
		enemy.position = formation_anchor + enemy.formation_offset
		enemy.body_heading = PI
		enemy.heading = PI
		enemy.shot_timer = 1.8 + float(slot) * 0.23


func _set_patrol(enemy: Enemy, lane: Line2D) -> void:
	for point in lane.points:
		enemy.route.append(lane.to_global(point))
	enemy.position = enemy.route[0].lerp(enemy.route[1], randf_range(0.08, 0.88))
	enemy.body_heading = enemy.route[0].direction_to(enemy.route[1]).angle() + PI / 2.0


func _air_spawn_position() -> Vector2:
	if mode == Mode.DEFENDER:
		return Vector2(1338.0, randf_range(126.0, 650.0))
	match randi_range(0, 3):
		0: return Vector2(randf_range(80.0, 1200.0), -58.0)
		1: return Vector2(1338.0, randf_range(110.0, 650.0))
		2: return Vector2(randf_range(80.0, 1200.0), 778.0)
		_: return Vector2(-58.0, randf_range(110.0, 650.0))


func _update_enemies(delta: float) -> void:
	var defending := mode == Mode.DEFENDER
	var target := OUTPOST_POSITION if defending else player_position
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if enemy.ground_mega:
			_update_ground_mega(enemy, delta)
			if phase == Phase.GAME_OVER:
				return
			continue
		if enemy.mega:
			_update_mega_boss(enemy, delta)
			if phase == Phase.GAME_OVER:
				return
			continue
		enemy.animation_time += delta
		enemy.attack_time = maxf(0.0, enemy.attack_time - delta)
		if enemy.in_formation:
			enemy.position = formation_anchor + enemy.formation_offset
			if enemy.position.distance_to(player_position) < enemy.radius + 16.0:
				_damage_player()
				if phase == Phase.GAME_OVER:
					return
			enemy.shot_timer -= delta
			if enemy.shot_timer <= 0.0 and FLIGHT_BOUNDS.has_point(enemy.position):
				_fire_enemy_volley(enemy)
			continue
		var to_target := target - enemy.position
		var distance := to_target.length()
		var forward := to_target.normalized()
		if not enemy.route.is_empty():
			enemy.walking = false
			var destination := enemy.route[enemy.destination]
			var travel := enemy.position.direction_to(destination)
			var travel_heading := travel.angle() + PI / 2.0
			enemy.body_heading = rotate_toward(enemy.body_heading, travel_heading, delta * 3.6)
			if absf(angle_difference(enemy.body_heading, travel_heading)) < 0.001:
				var next_position := enemy.position.move_toward(destination, enemy.speed * delta)
				enemy.walk_distance += next_position.distance_to(enemy.position)
				enemy.walking = not next_position.is_equal_approx(enemy.position)
				enemy.position = next_position
			if enemy.position.is_equal_approx(destination):
				enemy.destination = 1 - enemy.destination
		elif enemy.role != Roster.Role.TURRET:
			_move_aircraft(enemy, forward, distance, delta)
			if defending and enemy.boss_name.is_empty() and enemy.position.distance_to(OUTPOST_POSITION) < OUTPOST_RADIUS + enemy.radius:
				_damage_outpost(enemy.position, true)
				_add_burst(enemy.position, 62.0)
				enemies.remove_at(index)
				if phase == Phase.GAME_OVER:
					return
				continue
			if enemy.position.distance_squared_to(player_position) < pow(enemy.radius + 16.0, 2):
				_damage_player()
				if phase == Phase.GAME_OVER:
					return
		enemy.shot_timer -= delta
		var firing_range := 1100.0 if defending and not enemy.route.is_empty() else 525.0
		var airborne := enemy.route.is_empty() and enemy.role != Roster.Role.TURRET
		var target_heading := enemy.position.direction_to(target).angle() + PI / 2.0
		enemy.heading = enemy.body_heading if airborne else rotate_toward(enemy.heading, target_heading, delta * 6.0)
		var facing_target := not airborne or absf(angle_difference(enemy.heading, target_heading)) < 0.30
		if city_arena and (not enemy.route.is_empty() or enemy.side_view):
			var faces_left := _city_unit_faces_left(enemy)
			facing_target = facing_target and _faces_target_side(enemy.position, target, faces_left)
			facing_target = facing_target and _faces_target_side(Vector2.ZERO, Vector2.UP.rotated(enemy.heading), faces_left)
		if enemy.volley > 0 and enemy.shot_timer <= 0.0 and facing_target and distance < firing_range and FLIGHT_BOUNDS.has_point(enemy.position):
			_fire_enemy_volley(enemy)


func _city_unit_faces_left(enemy: Enemy) -> bool:
	return Vector2.UP.rotated(enemy.body_heading).x < 0.0


func _faces_target_side(origin: Vector2, target: Vector2, faces_left: bool) -> bool:
	return target.x < origin.x if faces_left else target.x > origin.x


func _move_aircraft(enemy: Enemy, forward: Vector2, distance: float, delta: float) -> void:
	var steering := forward
	var nose := Vector2.UP.rotated(enemy.body_heading)
	var makes_passes := mode == Mode.ENDLESS or not enemy.boss_name.is_empty()
	if makes_passes and not enemy.breaking_away and distance < enemy.preferred_distance * 0.72:
		enemy.breaking_away = true
		var turn_side := -1.0 if nose.cross(forward) > 0.0 else 1.0
		enemy.breakaway_heading = enemy.body_heading + turn_side * 1.1
	elif distance > enemy.preferred_distance + 145.0:
		enemy.breaking_away = false
	if enemy.breaking_away:
		steering = Vector2.UP.rotated(enemy.breakaway_heading)
	var separation := Vector2.ZERO
	for neighbor in enemies:
		if neighbor == enemy or neighbor.preferred_distance == 0.0:
			continue
		var gap := enemy.position - neighbor.position
		var spacing := enemy.radius + neighbor.radius + 12.0
		if gap.length_squared() < spacing * spacing and gap.dot(nose) < 0.0:
			separation += gap.normalized() * (1.0 - gap.length() / spacing)
	steering += separation.slide(nose) * 0.45
	var flight_area := ARENA.grow(76.0)
	if not flight_area.has_point(enemy.position + nose * 95.0):
		steering = enemy.position.direction_to(CENTER)
		enemy.breaking_away = false
	if not steering.is_zero_approx():
		var turn_rate := 2.6 if enemy.role == Roster.Role.JET else 3.3
		enemy.body_heading = rotate_toward(enemy.body_heading, steering.angle() + PI / 2.0, turn_rate * delta)
	enemy.position += Vector2.UP.rotated(enemy.body_heading) * enemy.speed * delta


func _fire_enemy_volley(enemy: Enemy) -> void:
	if not enemy.attack_frames.is_empty():
		enemy.attack_time = enemy.attack_frames.size() * 0.085
	var forward := Vector2.UP.rotated(enemy.heading)
	var muzzle := enemy.position + forward * (enemy.radius + 4.0)
	var speed := minf(208.0 + wave * 13.0, 340.0)
	var rocket := enemy.weapon > 0
	var art: Texture2D = ROUND_ART[1 if enemy.role == Roster.Role.SCOUT else 0]
	if rocket:
		art = ROCKET_ART[randi_range(0, ROCKET_ART.size() - 1)]
		speed *= 0.83 if enemy.weapon == 2 else 1.10
	if enemy.boss_shot:
		art = enemy.boss_shot
	if enemy.space_shot:
		art = enemy.space_shot
	if enemy.city_shot:
		art = enemy.city_shot
	var spread := 0.21
	if mode == Mode.DEFENDER and not enemy.route.is_empty():
		spread = 0.06
	for index in range(enemy.volley):
		var angle := (index - (enemy.volley - 1) / 2.0) * spread
		var direction := forward.rotated(angle)
		if city_arena and (not enemy.route.is_empty() or enemy.side_view) and not _faces_target_side(Vector2.ZERO, direction, _city_unit_faces_left(enemy)):
			continue
		_launch_shot(muzzle, direction * speed, true, art, rocket)
	enemy.shot_timer = maxf(1.0, 2.45 - wave * 0.075) + randf_range(0.0, 0.6)
	if enemy.boss_interval > 0.0:
		enemy.shot_timer = enemy.boss_interval


func _ground_mega_position(mega: GroundMegaBoss) -> Vector2:
	if not mega.shark:
		var angle := mega.travel_time * 0.55
		return Vector2(485.0 - 210.0 * cos(angle), 411.0 + 81.0 * sin(angle))
	var lane := water_lanes.get_child(mega.slot % water_lanes.get_child_count()) as Line2D
	var progress := 0.27 + mega.slot * 0.26 + sin(mega.age * 1.4 + mega.slot) * 0.095
	return lane.to_global(lane.points[0].lerp(lane.points[1], progress))


func _update_ground_mega(enemy: Enemy, delta: float) -> void:
	var mega := enemy.ground_mega
	mega.age += delta
	if mega.age < 0.75:
		return
	var tempo := 1.3 if mode == Mode.BOSS_RUSH else 1.0
	mega.clock += delta * tempo
	if mega.clock >= GroundMegaBoss.PERIOD:
		mega.clock -= GroundMegaBoss.PERIOD
		mega.pattern = (mega.pattern + 1) % 3
		mega.emitted = 0
	var clock := mega.clock
	if mega.pattern != 0 or clock < 0.72 or clock >= GroundMegaBoss.FIRE_END:
		mega.travel_time += delta
		enemy.position = _ground_mega_position(mega)
	var muzzle := enemy.position + Vector2(-47, -8) if mega.shark else mega.lizard_muzzle(enemy.position, enemy.width)
	var tint := Color("#ff923b") if mega.shark else Color("#4eeaff")
	match mega.pattern:
		0:
			var crossed_lock := not mega.shark and clock - delta * tempo < GroundMegaBoss.LIZARD_BEAM_LOCK
			if clock < 0.72 or crossed_lock:
				mega.beam_start = muzzle
				var aim := muzzle.direction_to(player_position)
				aim.x = minf(aim.x, -0.35) if mega.shark else maxf(aim.x, 0.35)
				var end_x := 0.0 if mega.shark else ARENA.end.x
				mega.beam_end = muzzle + aim * ((end_x - muzzle.x) / aim.x)
			if clock >= GroundMegaBoss.FIRE_TIME and clock < GroundMegaBoss.FIRE_END:
				if clock - delta * tempo < GroundMegaBoss.FIRE_TIME and not _faces_target_side(muzzle, player_position, mega.faces_left()):
					mega.beam_start = Vector2.ZERO
				if mega.beam_start != Vector2.ZERO and _shot_hits(mega.beam_start, mega.beam_end, player_position, 32.0):
					_damage_player()
		1, 2:
			var repeat_count := 4 if mega.pattern == 1 else 3
			if mega.emitted < repeat_count and clock >= 0.73 + mega.emitted * 0.28 and _faces_target_side(muzzle, player_position, mega.faces_left()):
				if not mega.shark and mega.pattern == 2 and mega.emitted == 0:
					var foot := enemy.position + Vector2(0, 105)
					_add_mega_effect(foot, 164.0, mega.stomp)
					_add_mega_effect(foot, 230.0, mega.shockwave)
				var aim := muzzle.direction_to(player_position)
				var count := 5 if mega.pattern == 1 else 9
				var spacing := 0.15 if mega.pattern == 1 else 0.24
				for index in range(count):
					var angle := (index - (count - 1) * 0.5) * spacing
					var direction := aim.rotated(angle)
					if not _faces_target_side(Vector2.ZERO, direction, mega.faces_left()):
						continue
					var shot := _launch_shot(muzzle, direction * 310.0 * tempo, true)
					shot.energy = tint
					shot.pulse_frames = mega.rockets if mega.shark and mega.pattern == 1 else mega.projectiles
					if not mega.shark and mega.pattern == 2:
						shot.art = mega.plasma_bolt
					shot.impact_frames = mega.blast
				mega.emitted += 1
	if player_position.distance_to(enemy.position) < enemy.radius + 12.0:
		_damage_player()


func _update_mega_boss(enemy: Enemy, delta: float) -> void:
	var mega := enemy.mega
	mega.age += delta
	if mega.age < 1.2:
		return
	mega.attack_clock += delta * (1.3 if mode == Mode.BOSS_RUSH else 1.0)
	if mega.attack_clock >= AlienMegaBoss.ATTACK_PERIOD:
		mega.attack_clock -= AlienMegaBoss.ATTACK_PERIOD
		mega.attack_index = (mega.attack_index + 1) % 3
		mega.emitted = 0
	var clock := mega.attack_clock
	if mega.attack_index != 0 or clock < AlienMegaBoss.BEAM_LOCK or clock >= AlienMegaBoss.BEAM_END:
		var target_y := clampf(player_position.y, 258.0, 482.0)
		if mega.attack_index != 0 or clock >= AlienMegaBoss.BEAM_END:
			target_y = AlienMegaBoss.POSITION.y + sin(mega.age * 1.6) * 105.0
		enemy.position.y = move_toward(enemy.position.y, target_y, delta * 230.0)
	match mega.attack_index:
		0:
			if clock >= AlienMegaBoss.BEAM_TIME and clock < AlienMegaBoss.BEAM_END:
				var muzzle := mega.muzzle(enemy.position)
				if _shot_hits(muzzle, Vector2(ARENA.end.x, muzzle.y), player_position, 28.0):
					_damage_player()
		1:
			if mega.emitted < 5 and clock >= 0.85 + mega.emitted * 0.18:
				for slot in range(mega.pods.size()):
					if mega.pods[slot] <= 0:
						continue
					var origin: Vector2 = enemy.position + AlienMegaBoss.POD_OFFSETS[slot]
					if not _faces_target_side(origin, player_position, false):
						continue
					var heading := origin.direction_to(player_position)
					for spread in [-0.28, 0.0, 0.28]:
						var direction := heading.rotated(spread)
						if direction.x <= 0.0:
							continue
						var shot := _launch_shot(origin, direction * 365.0, true, mega.bolts[mega.emitted])
						shot.energy = Color("#d670ff")
				mega.emitted += 1
		2:
			var origin := mega.muzzle(enemy.position)
			if mega.emitted < 7 and clock >= 0.7 + mega.emitted * 0.22 and _faces_target_side(origin, player_position, false):
				for lane in range(8):
					var target := Vector2(1280, 105.0 + lane * 79.0 + (mega.emitted % 2) * 24.0)
					var shot := _launch_shot(origin, origin.direction_to(target) * 420.0, true, mega.bolts[5 + mega.emitted])
					shot.energy = Color("#d670ff")
				mega.emitted += 1
	if player_position.distance_to(enemy.position) < enemy.radius + 16.0:
		_damage_player()


func _launch_shot(origin: Vector2, velocity: Vector2, hostile: bool, art: Texture2D = null, rocket := false) -> Shot:
	var shot := Shot.new()
	shot.position = origin
	shot.velocity = velocity
	shot.hostile = hostile
	shot.art = art
	shot.rocket = rocket
	if not hostile:
		shot.weapon = player_projectiles[weapon_mode]
		shot.remaining_hits = shot.weapon.hits
		shot.launch_heading = velocity.angle()
	shots.append(shot)
	return shot


func _update_shots(delta: float) -> void:
	for index in range(shots.size() - 1, -1, -1):
		var shot := shots[index]
		var previous := shot.position
		shot.age += delta
		if shot.weapon and shot.weapon.turn_rate > 0.0:
			_steer_homing_shot(shot, delta)
		elif shot.weapon == player_projectiles[PlayerProjectiles.Kind.WAVE]:
			var heading := shot.launch_heading + sin(shot.age * 15.0) * 0.35
			shot.velocity = Vector2.from_angle(heading) * shot.weapon.speed
		shot.position += shot.velocity * delta
		if not ARENA.grow(80.0).has_point(shot.position) or shot.age > 7.0:
			shots.remove_at(index)
			continue
		if shot.hostile:
			if _shot_hits(previous, shot.position, player_position, 16.0):
				shots.remove_at(index)
				if not shot.impact_frames.is_empty():
					_add_mega_effect(shot.position, 58.0, shot.impact_frames)
				_damage_player()
				if phase == Phase.GAME_OVER:
					return
			elif mode == Mode.DEFENDER and _shot_hits(previous, shot.position, OUTPOST_POSITION, OUTPOST_RADIUS):
				shots.remove_at(index)
				_damage_outpost(shot.position)
				if phase == Phase.GAME_OVER:
					return
		elif _resolve_player_shot(shot, previous):
			shots.remove_at(index)


func _steer_homing_shot(shot: Shot, delta: float) -> void:
	var target: Enemy
	var distance_squared := 420.0 * 420.0
	for enemy in enemies:
		var offset := enemy.position - shot.position
		if offset.dot(shot.velocity) > 0.0 and offset.length_squared() < distance_squared:
			target = enemy
			distance_squared = offset.length_squared()
	if target:
		var heading := rotate_toward(shot.velocity.angle(), (target.position - shot.position).angle(),
			shot.weapon.turn_rate * delta)
		shot.velocity = Vector2.from_angle(heading) * shot.weapon.speed


func _resolve_player_shot(shot: Shot, previous: Vector2) -> bool:
	while shot.remaining_hits > 0:
		var target_index := -1
		var best_distance := INF
		var impact := Vector2.ZERO
		for index in range(enemies.size()):
			var enemy := enemies[index]
			if enemy in shot.hit_targets or (enemy.ground_mega and enemy.ground_mega.age < 0.75):
				continue
			var hit_center := enemy.position
			var hit_radius := enemy.radius
			if enemy.mega:
				if enemy.mega.age < 1.2:
					continue
				for slot in range(enemy.mega.pods.size()):
					var pod: Vector2 = enemy.position + AlienMegaBoss.POD_OFFSETS[slot]
					if enemy.mega.pods[slot] > 0 and _shot_hits(previous, shot.position, pod, 45.0):
						hit_center = pod
						hit_radius = 45.0
						break
			if not _shot_hits(previous, shot.position, hit_center, hit_radius):
				continue
			var distance := previous.distance_squared_to(hit_center)
			if distance < best_distance:
				target_index = index
				best_distance = distance
				impact = Geometry2D.get_closest_point_to_segment(hit_center, previous, shot.position)
		if target_index == -1:
			return false
		var target := enemies[target_index]
		shot.hit_targets.append(target)
		shot.remaining_hits -= 1
		_damage_enemy(target_index, shot.weapon.damage, impact)
		if shot.weapon.blast_radius > 0.0:
			_explode_player_shot(impact, shot.weapon.blast_radius, target)
			return true
	return true


func _explode_player_shot(at: Vector2, radius: float, direct_target: Enemy) -> void:
	_add_burst(at, radius * 1.35)
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if enemy != direct_target and enemy.position.distance_to(at) <= radius:
			_damage_enemy(index, 2, enemy.position)


func _damage_enemy(index: int, damage: int, at: Vector2) -> void:
	var enemy := enemies[index]
	if enemy.ground_mega and enemy.ground_mega.age < 0.75:
		return
	if enemy.mega:
		if enemy.mega.age < 1.2:
			return
		for slot in range(enemy.mega.pods.size()):
			var pod: Vector2 = enemy.position + AlienMegaBoss.POD_OFFSETS[slot]
			if enemy.mega.pods[slot] > 0 and at.distance_to(pod) <= 45.01:
				enemy.mega.pods[slot] -= damage
				if enemy.mega.pods[slot] <= 0:
					_add_mega_effect(pod, 110.0, enemy.mega.pod_break)
					_add_mega_effect(pod + Vector2(68, 20), 85.0, enemy.mega.tentacle_break)
				else:
					_add_burst(at, 24.0, true)
				return
	var previous_hull := enemy.hull
	enemy.hull -= damage
	if enemy.hull <= 0:
		_destroy_enemy(index)
	else:
		if enemy.mega and previous_hull * 2 > enemy.max_hull and enemy.hull * 2 <= enemy.max_hull:
			_add_mega_effect(enemy.position + Vector2(65, 86), 110.0, enemy.mega.armor_break)
		_add_burst(at, 24.0, true)


func _shot_hits(from: Vector2, to: Vector2, target: Vector2, radius: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(target, from, to).distance_squared_to(target) <= radius * radius


func _damage_player() -> void:
	if invulnerable > 0.0:
		return
	invulnerable = 0.9
	if shield_hits > 0:
		shield_hits -= 1
		_add_burst(player_position, 38.0, true)
		return
	hull -= 1
	_add_burst(player_position, 44.0)
	if hull == 0:
		phase = Phase.GAME_OVER
		_add_burst(player_position, 112.0)


func _damage_outpost(hit_position: Vector2, breach := false) -> void:
	if not breach and outpost_hit_timer > 0.0:
		return
	outpost_hull -= 1
	outpost_hit_timer = 0.55
	_add_burst(hit_position, 34.0, true)
	if outpost_hull == 0:
		phase = Phase.GAME_OVER
		_add_burst(OUTPOST_POSITION, 126.0)


func _destroy_enemy(index: int) -> void:
	var enemy := enemies[index]
	var is_boss := not enemy.boss_name.is_empty()
	score += 500 if is_boss else 100
	best_scores[score_group][difficulty] = maxi(best_scores[score_group][difficulty], score)
	if enemy.ground_mega:
		_add_mega_effect(enemy.position, enemy.width, enemy.ground_mega.death)
		_add_mega_effect(enemy.position, enemy.width * 0.55, enemy.ground_mega.blast)
		if not enemy.ground_mega.shark:
			_add_mega_effect(enemy.position + Vector2(0, 105), 195.0, enemy.ground_mega.cracks)
			_add_mega_effect(enemy.position + Vector2(48, 20), 130.0, enemy.ground_mega.debris)
			_add_mega_effect(enemy.position + Vector2(-45, 25), 82.0, enemy.ground_mega.armor_fragments)
	elif enemy.mega:
		_add_mega_effect(enemy.position, 340.0, enemy.mega.death)
		_add_mega_effect(enemy.position + Vector2(95, 5), 94.0, enemy.mega.core_break)
		var fragments: Array[AtlasTexture] = []
		fragments.assign(enemy.mega.sparks.slice(10))
		_add_mega_effect(enemy.position + Vector2(13, -120), 100.0, fragments)
	else:
		_add_burst(enemy.position, 126.0 if is_boss else 78.0)
	if is_boss and mode != Mode.BOSS_RUSH:
		_drop_supply(enemy.position, Supply.REPAIR, true)
	elif not is_boss and mode != Mode.BOSS_RUSH and pickups.size() < MAX_PICKUPS:
		var chance := randf()
		if hull < MAX_HULL and chance < 0.20:
			_drop_supply(enemy.position, Supply.REPAIR)
		elif shield_hits < SHIELD_HITS and chance >= 0.20 and chance < 0.27:
			_drop_supply(enemy.position, Supply.SHIELD)
		elif chance >= 0.27 and chance < 0.45:
			_drop_supply(enemy.position, Supply.WEAPON)
	enemies.remove_at(index)


func _drop_supply(at: Vector2, supply: Supply, guaranteed := false) -> void:
	if pickups.size() >= MAX_PICKUPS:
		if not guaranteed:
			return
		pickups.pop_front()
	var pickup := Pickup.new()
	pickup.position = at.clamp(FLIGHT_BOUNDS.position + Vector2(12, 12), FLIGHT_BOUNDS.end - Vector2(12, 12))
	pickup.supply = supply
	if supply == Supply.WEAPON:
		var last_kind := player_projectiles.size() - 1
		var has_active_weapon := weapon_mode != PlayerProjectiles.Kind.STANDARD
		var rolled := randi_range(1, last_kind - int(has_active_weapon))
		if has_active_weapon and rolled >= weapon_mode:
			rolled += 1
		pickup.weapon_kind = rolled as PlayerProjectiles.Kind
	pickups.append(pickup)


func _add_burst(at: Vector2, size: float, impact := false) -> void:
	var burst := Burst.new()
	burst.position = at
	burst.size = size
	burst.impact = impact
	bursts.append(burst)


func _add_mega_effect(at: Vector2, size: float, frames: Array[AtlasTexture]) -> void:
	var burst := Burst.new()
	burst.position = at
	burst.size = size
	burst.frames = frames
	burst.duration = frames.size() * 0.14
	bursts.append(burst)


func _draw() -> void:
	if mode == Mode.DEFENDER:
		_draw_outpost()
	for pickup in pickups:
		if pickup.lifetime < 3.0 and int(elapsed * 8.0) % 2 == 0:
			continue
		draw_circle(pickup.position, 18.0 + sin(elapsed * 5.0) * 2.0, Color("#37675899"))
		_draw_sprite(PICKUP_ART, pickup.position, 30.0)
	for enemy in enemies:
		_draw_enemy(enemy)
	if hull > 0:
		if shield_hits > 0:
			draw_circle(player_position, 37.0, Color("#75cbf345"), true, -1.0, true)
			draw_arc(player_position, 37.0, 0.0, TAU, 48, Color("#416eaa"), 2.5, true)
		_draw_sprite(SELECTION, player_position, 84.0, 0.0, Color("#507e9e65"))
		if invulnerable <= 0.0 or int(invulnerable * 18.0) % 2 == 0:
			if space_arena:
				var frame := 1 + int(elapsed * 16.0) % (ship_frames.size() - 1) if thrusting else 0
				var anchor := player_position + Vector2.DOWN.rotated(player_heading) * 10.0
				_draw_sprite(ship_frames[frame], anchor, 79.0, player_heading, Color("#d6edfb"))
			else:
				_draw_aircraft(PLAYER, player_position, 74.0, player_heading, Color("#d6edfb"))
		if muzzle_timer > 0.0:
			var flash_position := player_position + Vector2.UP.rotated(player_heading) * 32.0
			_draw_sprite(MUZZLE, flash_position, 22.0, player_heading, PLAYER_TRACER_CORE)
	for shot in shots:
		if not shot.hostile:
			_draw_player_shot(shot)
			continue
		if shot.energy.a > 0.0:
			_draw_energy_shot(shot)
			continue
		if space_arena:
			if shot.art:
				_draw_sprite(shot.art, shot.position, 35.0, shot.velocity.angle())
			continue
		if city_arena and shot.art:
			_draw_sprite(shot.art, shot.position, 27.0, shot.velocity.angle())
			continue
		if shot.rocket:
			var behind := shot.velocity.normalized()
			var trail: Texture2D = TRAIL_ART[int(elapsed * 19.0) % TRAIL_ART.size()]
			_draw_sprite(trail, shot.position - behind * 15.0, 16.0, shot.velocity.angle() + PI / 2.0, Color("#eef1e3bb"))
		else:
			draw_circle(shot.position, 7.0, Color("#9f4030"))
		var width := 18.0 if shot.rocket else 13.0
		var tint := Color.WHITE if shot.art is AtlasTexture else Color("#ffc8a8")
		_draw_sprite(shot.art if shot.art else ROUND_ART[0], shot.position, width, shot.velocity.angle() + PI / 2.0, tint)
	for burst in bursts:
		if not burst.frames.is_empty():
			var effect_frame := mini(int(burst.age / 0.14), burst.frames.size() - 1)
			_draw_sprite(burst.frames[effect_frame], burst.position, burst.size)
			continue
		var tint := Color(1, 1, 1, 1 - burst.age / 0.4)
		var frame := mini(int(burst.age / 0.1), FIRE.size() - 1)
		if space_arena:
			var space_frame := mini(frame, space_effects.size() - 1)
			_draw_sprite(space_effects[space_frame], burst.position, burst.size * (0.52 + 0.16 * space_frame), 0.0, tint)
			continue
		if burst.impact:
			_draw_sprite(SPARK, burst.position, burst.size, burst.age * 2.0, tint)
			continue
		_draw_sprite(SMOKE[frame], burst.position + Vector2(5, -5), burst.size * 1.2, 0.0, Color("#7f8383b0") * tint)
		_draw_sprite(FIRE[frame], burst.position, burst.size, 0.0, tint)
	_draw_hud()


func _draw_outpost() -> void:
	var destroyed := outpost_hull == 0
	var tint := Color("#929292") if destroyed else Color.WHITE
	var boundary := ORANGE if outpost_hit_timer > 0.0 else BLUE
	draw_circle(OUTPOST_POSITION + Vector2(0, 8), OUTPOST_RADIUS + 3.0, Color("#68686858"), true, -1.0, true)
	draw_arc(OUTPOST_POSITION, OUTPOST_RADIUS + 7.0, 0.0, TAU, 48, boundary, 2.5, true)
	_draw_sprite(OUTPOST, OUTPOST_POSITION, 151.0, 0.0, tint)
	_label("OUTPOST", OUTPOST_POSITION + Vector2(0, 91), 14, INK, true)
	var ingress := Vector2(1223, 165)
	draw_line(ingress, ingress + Vector2(-31, 0), ORANGE, 3.0, true)
	draw_polyline(PackedVector2Array([ingress + Vector2(-21, -8), ingress + Vector2(-31, 0),
		ingress + Vector2(-21, 8)]), ORANGE, 3.0, true)
	_label("ENEMY APPROACH", Vector2(1218, 151), 13, INK, true)


func _draw_energy_shot(shot: Shot) -> void:
	var pulse := 0.5 + 0.5 * sin(shot.age * 25.0)
	var tint := shot.energy
	draw_circle(shot.position, 10.0 + pulse * 6.0, Color(tint, 0.22), true, -1.0, true)
	draw_circle(shot.position, 5.0 + pulse * 3.0, tint, true, -1.0, true)
	var art := shot.art
	if not shot.pulse_frames.is_empty():
		art = shot.pulse_frames[int(shot.age * 18.0) % shot.pulse_frames.size()]
	if shot.art and art != shot.art:
		_draw_sprite(shot.art, shot.position - shot.velocity.normalized() * 11.0, 40.0, shot.velocity.angle())
	if art:
		_draw_sprite(art, shot.position, 21.0 + pulse * 9.0, shot.velocity.angle())


func _draw_enemy(enemy: Enemy) -> void:
	if enemy.ground_mega:
		_draw_ground_mega(enemy)
		return
	if enemy.mega:
		_draw_mega_boss(enemy)
		return
	var tint := Color("#f1c2ad")
	if city_arena and not enemy.route.is_empty():
		_draw_city_ground_unit(enemy, tint)
	elif not enemy.flight_frames.is_empty():
		var frame := int(enemy.animation_time * 15.0) % enemy.flight_frames.size()
		var body := enemy.flight_frames[frame]
		if enemy.side_view:
			_draw_sprite(body, enemy.position, enemy.width, 0.0, tint,
				Vector2.UP.rotated(enemy.body_heading).x < 0.0)
		else:
			_draw_aircraft(body, enemy.position, enemy.width, enemy.body_heading, tint)
	elif space_arena:
		_draw_sprite(enemy.body, enemy.position, enemy.width, enemy.body_heading, tint)
	elif enemy.preferred_distance > 0.0:
		_draw_aircraft(enemy.body, enemy.position, enemy.width, enemy.body_heading, tint)
	else:
		_draw_sprite(enemy.body, enemy.position + Vector2(3, 4), enemy.width, enemy.body_heading, Color("#49665e80"))
		_draw_sprite(enemy.body, enemy.position, enemy.width, enemy.body_heading, tint)
	if enemy.role == Roster.Role.HELI:
		var rotor := enemy.attachment if int(elapsed * 23.0) % 2 == 0 else Roster.FAST_ROTOR
		_draw_sprite(rotor, enemy.position, enemy.width * 1.2, elapsed * 15.0, tint)
	elif enemy.attachment:
		_draw_sprite(enemy.attachment, enemy.position, enemy.width * 0.55, enemy.heading, tint)
	if enemy.boss_name.is_empty():
		var bar_origin := enemy.position + Vector2(-18.0, -enemy.radius - 17.0)
		draw_rect(Rect2(bar_origin, Vector2(36.0, 4.0)), Color("#613c38"))
		draw_rect(Rect2(bar_origin, Vector2(36.0 * enemy.hull / enemy.max_hull, 4.0)), ORANGE)


func _draw_ground_mega(enemy: Enemy) -> void:
	var mega := enemy.ground_mega
	var clock := mega.clock
	if not mega.shark:
		var pose := mega.lizard_pose()
		var body := mega.lizard_texture(pose)
		var sprite_scale := mega.lizard_scale(pose, enemy.width)
		var foot := enemy.position + Vector2(0, 105)
		var flip := mega.faces_left()
		var offset := (body.get_width() * 0.5 - mega.lizard_foot_x(pose)) * sprite_scale
		_draw_sprite(body, foot + Vector2(-offset if flip else offset, -body.get_height() * sprite_scale * 0.5),
			body.get_width() * sprite_scale, 0.0, Color.WHITE, flip)
		_draw_ground_mega_beam(mega)
		return
	var frames := mega.idle
	var frame := int(mega.age * 9.0) % frames.size()
	if mega.age < 0.75:
		frames = mega.sweep if mega.shark else mega.idle
		frame = mini(int(mega.age / 0.75 * frames.size()), frames.size() - 1)
	elif clock < 2.2:
		match mega.pattern:
			0:
				frames = mega.charge if clock < GroundMegaBoss.FIRE_TIME else mega.fire
				if clock >= GroundMegaBoss.FIRE_TIME:
					frame = mini(int((clock - GroundMegaBoss.FIRE_TIME) / (2.2 - GroundMegaBoss.FIRE_TIME) * frames.size()), frames.size() - 1)
				else:
					frame = mini(int(clock / GroundMegaBoss.FIRE_TIME * frames.size()), frames.size() - 1)
			1, 2:
				frames = mega.barrage if mega.pattern == 1 else mega.sweep
				frame = mini(int(clock / 2.2 * frames.size()), frames.size() - 1)
	var body := frames[frame]
	var sprite_scale := enemy.width / (170.0 if mega.shark else 155.0)
	var offset_x := (body.get_width() * sprite_scale - enemy.width) * (0.5 if not mega.shark else -0.5)
	var offset_y := 48.0 if mega.shark else 105.0
	var flip := mega.faces_left()
	_draw_sprite(body, enemy.position + Vector2(-absf(offset_x) if flip else offset_x, offset_y - body.get_height() * sprite_scale * 0.5),
		body.get_width() * sprite_scale, 0.0, Color.WHITE, flip)
	_draw_ground_mega_beam(mega)


func _draw_ground_mega_beam(mega: GroundMegaBoss) -> void:
	var clock := mega.clock
	if mega.pattern == 0 and clock < GroundMegaBoss.FIRE_END and mega.beam_start != Vector2.ZERO:
		var tint := Color("#ff923b") if mega.shark else Color("#4eeaff")
		if clock < GroundMegaBoss.FIRE_TIME:
			draw_line(mega.beam_start, mega.beam_end, Color(tint, 0.52), 3.0, true)
			draw_circle(mega.beam_start, 9.0 + sin(clock * 22.0) * 3.0, tint, true, -1.0, true)
		else:
			draw_line(mega.beam_start, mega.beam_end, Color(tint, 0.32), 64.0, true)
			draw_line(mega.beam_start, mega.beam_end, tint, 34.0, true)
			draw_line(mega.beam_start, mega.beam_end, Color("#fff8ea"), 16.0, true)
			if mega.beam_flash:
				var direction := mega.beam_start.direction_to(mega.beam_end)
				_draw_sprite(mega.beam_flash, mega.beam_start + direction * 83.0, 166.0, direction.angle())


func _draw_mega_boss(enemy: Enemy) -> void:
	var mega := enemy.mega
	var clock := mega.attack_clock
	var wall_x := AlienMegaBoss.WALL_X
	var hull_size := AlienMegaBoss.HULL_SIZE
	var ingress := smoothstep(0.0, 1.2, mega.age)
	wall_x -= (1.0 - ingress) * hull_size.x
	var lashes := mega.attack_index == 2 and clock < 2.5
	for side in [-1, 1]:
		var frame := int(mega.age * (12.0 if lashes else 5.0) + (side + 1) * 2.0) % mega.tentacles.size()
		var tentacle := mega.tentacles[frame]
		var width := tentacle.get_width() * (2.15 if lashes else 1.85)
		_draw_sprite(tentacle, Vector2(wall_x + width * 0.5, enemy.position.y + side * 212.0), width)
	draw_texture_rect(AlienMegaBoss.HULL,
		Rect2(Vector2(wall_x, enemy.position.y - hull_size.y * 0.5), hull_size), false)
	if mega.age < 1.2:
		return
	for slot in range(mega.pods.size()):
		var pod: Vector2 = enemy.position + AlienMegaBoss.POD_OFFSETS[slot]
		if mega.pods[slot] <= 0:
			draw_circle(pod, 18.0, Color("#24222dc0"), true, -1.0, true)
			continue
		if mega.attack_index == 1:
			var glow := 0.15 + 0.2 * absf(sin(clock * 17.0))
			draw_circle(pod, 19.0, Color(0.87, 0.49, 1.0, glow), true, -1.0, true)
		draw_rect(Rect2(pod + Vector2(-24, 34), Vector2(48, 4)), INK)
		draw_rect(Rect2(pod + Vector2(-24, 34), Vector2(48.0 * mega.pods[slot] / 36.0, 4)), Color("#db83ff"))
	if lashes:
		var spark := mega.sparks[int(clock * 10.0) % 5]
		_draw_sprite(spark, mega.muzzle(enemy.position), 55.0)
	if mega.attack_index == 0 and clock < AlienMegaBoss.BEAM_END:
		var muzzle := mega.muzzle(enemy.position)
		var end := Vector2(ARENA.end.x, muzzle.y)
		if clock < AlienMegaBoss.BEAM_TIME:
			draw_line(muzzle, end, Color("#db83ff76"), 3.0, true)
			_draw_sprite(mega.sparks[5 + int(clock * 8.0) % 5], muzzle, 48.0 + mega.charge_frame() * 5.0)
			_draw_sprite(mega.bolts[11], muzzle + Vector2(55, 0), 100.0)
		else:
			draw_line(muzzle, end, Color("#b242ed88"), 56.0, true)
			draw_line(muzzle, end, Color("#ffdcff"), 19.0, true)
			_draw_sprite(mega.bolts[12], (muzzle + end) / 2.0, end.x - muzzle.x)


func _draw_city_ground_unit(enemy: Enemy, tint: Color) -> void:
	var faces_left := _city_unit_faces_left(enemy)
	var body := enemy.body
	var frames := enemy.left_frames if faces_left and not enemy.left_frames.is_empty() else enemy.walk_frames
	if enemy.attack_time > 0.0:
		var frame := enemy.attack_frames.size() - ceili(enemy.attack_time / 0.085)
		body = enemy.attack_frames[clampi(frame, 0, enemy.attack_frames.size() - 1)]
	elif not enemy.walking and not enemy.idle_frames.is_empty():
		body = enemy.idle_frames[int(enemy.animation_time * 7.0) % enemy.idle_frames.size()]
	elif not frames.is_empty():
		body = frames[int(enemy.walk_distance / 7.0) % frames.size()]
		if frames == enemy.left_frames:
			faces_left = false
	var width := enemy.width * float(body.get_width()) / enemy.body.get_width()
	_draw_sprite(body, enemy.position, width, 0.0, tint, faces_left)


func _draw_player_shot(shot: Shot) -> void:
	var frame := mini(int(shot.age / 0.033), shot.weapon.frames.size() - 1)
	var sprite := shot.weapon.frames[frame]
	var width := shot.weapon.width * (0.78 + 0.22 * float(frame) / (shot.weapon.frames.size() - 1))
	if shot.weapon.spin_speed > 0.0:
		_draw_sprite(sprite, shot.position, width, fposmod(shot.age * shot.weapon.spin_speed, TAU))
		return
	var center := shot.position - shot.velocity.normalized() * (width * 0.5 - 2.0)
	_draw_sprite(sprite, center, width, shot.velocity.angle())


func _draw_aircraft(texture: Texture2D, at: Vector2, width: float, heading: float, tint: Color) -> void:
	_draw_sprite(texture, at + Vector2(5.0, 13.0), width, heading, Color("#7199b3a9"))
	_draw_sprite(texture, at, width, heading, tint)


func _draw_sprite(texture: Texture2D, at: Vector2, width: float, heading := 0.0, tint := Color.WHITE, flip_horizontal := false) -> void:
	var size := texture.get_size() * (width / texture.get_width())
	draw_set_transform(at, heading, Vector2(-1, 1) if flip_horizontal else Vector2.ONE)
	draw_texture_rect(texture, Rect2(-size / 2.0, size), false, tint)
	draw_set_transform(Vector2.ZERO)


func _panel(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("#7194a64d"))
	draw_rect(rect, PAPER)
	draw_rect(rect, INK, false, 2.0)


func _label(value: String, at: Vector2, size: int, tint := INK, centered := false) -> void:
	var font := UI_FONT
	if centered:
		at.x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)


func _draw_hud() -> void:
	_panel(Rect2(28, 24, 208, 70))
	draw_string(TITLE_FONT, Vector2(44, 53), "Paper Armada", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
	var mode_name := "Defender" if mode == Mode.DEFENDER else "Endless"
	if space_arena:
		mode_name = "Space"
	elif city_arena:
		mode_name = "City"
	_label("%s / %s" % [mode_name, DIFFICULTY_NAMES[difficulty]], Vector2(45, 76), 14, MUTED)
	_panel(Rect2(529, 24, 222, 70))
	_label("WAVE %02d" % wave, Vector2(640, 54), 26, INK, true)
	var status := "AWAITING TAKEOFF"
	if phase == Phase.INCOMING:
		status = "INCOMING IN %d" % ceili(wave_timer)
	elif phase == Phase.COMBAT:
		status = "%d HOSTILES LEFT" % (enemies.size() + remaining_spawns)
	elif phase == Phase.GAME_OVER:
		status = "SORTIE ENDED"
	_label(status, Vector2(640, 77), 13, MUTED, true)
	_panel(Rect2(1036, 24, 216, 70))
	_label("HULL", Vector2(1052, 51), 14, MUTED)
	for index in range(MAX_HULL):
		draw_rect(Rect2(1121 + index * 23, 39, 17, 13), BLUE if index < hull else Color("#d0d9d9"))
	_label("SCORE  %06d" % score, Vector2(1052, 76), 18)
	if mode == Mode.DEFENDER:
		_panel(Rect2(263, 24, 215, 70))
		_label("OUTPOST INTEGRITY", Vector2(278, 51), 14, MUTED)
		_label("%d / %d" % [outpost_hull, OUTPOST_MAX_HULL], Vector2(439, 52), 15, INK, true)
		draw_rect(Rect2(278, 64, 183, 13), Color("#d8ceca"))
		draw_rect(Rect2(278, 64, 183.0 * outpost_hull / OUTPOST_MAX_HULL, 13), BLUE if outpost_hull > 5 else ORANGE)
	draw_rect(Rect2(0, 684, 1280, 36), PAPER)
	draw_line(Vector2(0, 684), Vector2(1280, 684), INK, 2.0)
	_label("WASD / ARROWS   Fly     |     MOUSE   Aim     |     LEFT CLICK / SPACE   Fire", Vector2(28, 707), 15)
	if shield_hits > 0:
		_label("SHIELD %d/%d" % [shield_hits, SHIELD_HITS], Vector2(800, 707), 13, MUTED)
	var active_weapon := player_projectiles[weapon_mode]
	var armament := active_weapon.title.to_upper()
	if weapon_time > 0.0:
		armament += " %ds" % ceili(weapon_time)
	_label(armament, Vector2(917, 707), 13, MUTED)
	_draw_sprite(active_weapon.frames[0], Vector2(1060, 702), 28.0)
	_label("BEST  %06d" % best_scores[score_group][difficulty], Vector2(1132, 707), 15)
	match phase:
		Phase.BRIEFING, Phase.GAME_OVER, Phase.VICTORY:
			_draw_launch_menu()
		Phase.INCOMING:
			_panel(Rect2(459, 119, 362, 55))
			var callout := "WAVE %02d INBOUND" % wave
			if wave_bosses.size() == 3:
				callout = "MEGA SHARKS INBOUND" if _is_mega_boss_wave() else "THREE BOSSES INBOUND"
			elif wave_bosses.size() == 1:
				callout = "BOSS INBOUND"
				if space_arena or mode != Mode.ENDLESS or _is_mega_boss_wave():
					callout = "%s INBOUND" % wave_bosses[0].boss_name.to_upper()
			_label(callout, Vector2(640, 154), 20, INK, true)
		Phase.COMBAT:
			var boss_y := 104.0
			for enemy in enemies:
				if not enemy.boss_name.is_empty():
					_panel(Rect2(470, boss_y, 340, 47))
					_label(enemy.boss_name, Vector2(640, boss_y + 20), 16, INK, true)
					draw_rect(Rect2(486, boss_y + 29, 308, 8), Color("#d8ceca"))
					draw_rect(Rect2(486, boss_y + 29, 308.0 * enemy.hull / enemy.max_hull, 8), ORANGE)
					boss_y += 52.0


func _draw_launch_menu() -> void:
	var game_over := phase == Phase.GAME_OVER
	var victory := phase == Phase.VICTORY
	draw_rect(ARENA, Color("#263d4a61"))
	_panel(Rect2(394, 136, 492, 280))
	var heading := "Defend the outpost" if mode == Mode.DEFENDER else "Endless sortie"
	if space_arena:
		heading = "Space sortie"
	elif city_arena:
		heading = "City sortie"
	if mode == Mode.BOSS_RUSH:
		heading = "Boss Rush"
	if game_over:
		heading = "Outpost lost" if outpost_hull == 0 else "Plane down"
	if victory:
		heading = "Boss Rush cleared"
	var subtitle := "Wave %d  |  Score %d" % [wave, score] if (game_over or victory) else "Choose a difficulty"
	if mode == Mode.BOSS_RUSH and not game_over and not victory:
		subtitle = "Hard  |  Four fights  |  Pickups every 10–15 seconds"
	_label(heading, Vector2(640, 178), 31, INK, true)
	_label(subtitle, Vector2(640, 204), 16, MUTED, true)
	var mouse := get_local_mouse_position()
	for index in range(0 if mode == Mode.BOSS_RUSH else DIFFICULTY_CARDS.size()):
		var card: Rect2 = DIFFICULTY_CARDS[index]
		var selected := index == difficulty
		var fill := Color("#c4dce5") if selected else Color("#e7eae0")
		if card.has_point(mouse):
			fill = fill.lightened(0.15)
		draw_rect(card, fill)
		draw_rect(card, INK if selected else Color("#889b9c"), false, 2.0)
		_label("%d  %s" % [index + 1, DIFFICULTY_NAMES[index]], card.get_center() + Vector2(0, -2), 19, INK, true)
		var count := "%d in wave one" % _wave_size(1, index as Difficulty)
		_label(count, card.get_center() + Vector2(0, 20), 13, MUTED, true)
	draw_rect(TAKEOFF_BUTTON, Color("#42677a") if TAKEOFF_BUTTON.has_point(mouse) else INK)
	var action := "Enter  /  Fly again" if (game_over or victory) else "Enter  /  Take off"
	_label(action, TAKEOFF_BUTTON.get_center() + Vector2(0, 7), 17, PAPER, true)
	draw_rect(MAIN_MENU_BUTTON, Color("#d3e2e3") if MAIN_MENU_BUTTON.has_point(mouse) else Color("#e5e9dc"))
	draw_rect(MAIN_MENU_BUTTON, INK, false, 1.0)
	_label("Main menu  /  Esc", MAIN_MENU_BUTTON.get_center() + Vector2(0, 5), 15, INK, true)
