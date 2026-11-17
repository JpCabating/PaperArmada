extends RefCounted

enum Role { FIGHTER, SCOUT, HELI, JET, BOMBER, TANK, PATROL, TURRET, AIRSHIP }

const STATS := {
	Role.FIGHTER: {"width": 64.0, "radius": 23.0, "speed": 110.0, "hull": 2, "distance": 145.0, "volley": 1, "weapon": 0},
	Role.SCOUT: {"width": 47.0, "radius": 17.0, "speed": 180.0, "hull": 1, "distance": 113.0, "volley": 1, "weapon": 0},
	Role.HELI: {"width": 60.0, "radius": 22.0, "speed": 87.0, "hull": 3, "distance": 205.0, "volley": 2, "weapon": 0},
	Role.JET: {"width": 59.0, "radius": 21.0, "speed": 200.0, "hull": 2, "distance": 165.0, "volley": 2, "weapon": 1},
	Role.BOMBER: {"width": 83.0, "radius": 30.0, "speed": 66.0, "hull": 5, "distance": 238.0, "volley": 3, "weapon": 2},
	Role.TANK: {"width": 52.0, "radius": 21.0, "speed": 62.0, "hull": 4, "distance": 0.0, "volley": 1, "weapon": 3},
	Role.PATROL: {"width": 64.0, "radius": 25.0, "speed": 73.0, "hull": 4, "distance": 0.0, "volley": 2, "weapon": 3},
	Role.TURRET: {"width": 54.0, "radius": 22.0, "speed": 0.0, "hull": 5, "distance": 0.0, "volley": 2, "weapon": 3},
	Role.AIRSHIP: {"width": 99.0, "radius": 37.0, "speed": 59.0, "hull": 12, "distance": 255.0, "volley": 3, "weapon": 2},
}

# Roles define behavior. Entries unlock as the wave rises.
const UNITS := [
	{"role": Role.FIGHTER, "wave": 1, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_c.png")},
	{"role": Role.FIGHTER, "wave": 2, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_b.png")},
	{"role": Role.SCOUT, "wave": 2, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_drone.png")},
	{"role": Role.HELI, "wave": 2, "body": preload("res://Scribble-Planes/PNG/Default/unit_helicopter_a.png"), "top": preload("res://Scribble-Planes/PNG/Default/unit_helicopter_blades_a.png")},
	{"role": Role.TANK, "wave": 2, "body": preload("res://Scribble-Planes/PNG/Default/unit_small_tank_tracks.png")},
	{"role": Role.FIGHTER, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_d.png")},
	{"role": Role.TANK, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/unit_small_tank_wheels.png")},
	{"role": Role.PATROL, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/unit_ship.png"), "top": preload("res://Scribble-Planes/PNG/Default/turret_double.png")},
	{"role": Role.JET, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_e.png")},
	{"role": Role.HELI, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/unit_helicopter_b.png"), "top": preload("res://Scribble-Planes/PNG/Default/unit_helicopter_blades_b.png")},
	{"role": Role.TURRET, "wave": 3, "body": preload("res://Scribble-Planes/PNG/Default/turret_base_square.png"), "top": preload("res://Scribble-Planes/PNG/Default/turret.png")},
	{"role": Role.FIGHTER, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_f.png")},
	{"role": Role.BOMBER, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_bomber.png")},
	{"role": Role.TANK, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_tank.png"), "top": preload("res://Scribble-Planes/PNG/Default/unit_tank_turret.png")},
	{"role": Role.JET, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_g.png")},
	{"role": Role.FIGHTER, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_sea.png")},
	{"role": Role.PATROL, "wave": 4, "body": preload("res://Scribble-Planes/PNG/Default/unit_submarine.png")},
	{"role": Role.BOMBER, "wave": 5, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_double_a.png")},
	{"role": Role.JET, "wave": 5, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_h.png")},
	{"role": Role.TURRET, "wave": 5, "body": preload("res://Scribble-Planes/PNG/Default/turret_base.png"), "top": preload("res://Scribble-Planes/PNG/Default/turret_large.png")},
	{"role": Role.FIGHTER, "wave": 5, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_i.png")},
	{"role": Role.BOMBER, "wave": 6, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_double_b.png")},
	{"role": Role.JET, "wave": 6, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_j.png")},
	{"role": Role.JET, "wave": 6, "body": preload("res://Scribble-Planes/PNG/Default/unit_plane_k.png")},
	{"role": Role.TURRET, "wave": 6, "body": preload("res://Scribble-Planes/PNG/Default/turret_base_square.png"), "top": preload("res://Scribble-Planes/PNG/Default/turret_wide.png")},
	{"role": Role.AIRSHIP, "wave": 5, "body": preload("res://Scribble-Planes/PNG/Default/unit_airship_a.png")},
	{"role": Role.AIRSHIP, "wave": 10, "body": preload("res://Scribble-Planes/PNG/Default/unit_airship_b.png")},
]

const FAST_ROTOR := preload("res://Scribble-Planes/PNG/Default/unit_helicopter_blades_c.png")

