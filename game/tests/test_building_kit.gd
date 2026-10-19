## Detailed building parts (scripts/game/building_kit.gd, T-0308): material slots, sizes
## that keep the turned block at gameplay width, outward flat faces, and no coplanar
## overlapping top faces (they z-fight and flicker, see T-0307).
extends "res://tests/test_case.gd"

const Kit := preload("res://scripts/game/building_kit.gd")
const LowPoly := preload("res://scripts/game/low_poly.gd")
const YAW := deg_to_rad(38.0)


func _names(mesh: ArrayMesh) -> Array[String]:
	var out: Array[String] = []
	for i in range(mesh.get_surface_count()):
		out.append(mesh.surface_get_name(i))
	return out


## Sample points on every horizontal level and count how many up-facing triangles cover
## each point. More than one = two surfaces fighting over the same pixels.
func _coplanar_overlaps(meshes: Array) -> int:
	var levels := {}   # y (rounded) -> Array of [a, b, c] (xz)
	for mesh in meshes:
		for s in range((mesh as ArrayMesh).get_surface_count()):
			var arr: Array = mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in range(0, v.size(), 3):
				if n[i].y < 0.999:
					continue
				var key := snappedf(v[i].y, 0.0001)
				if not levels.has(key):
					levels[key] = []
				levels[key].append([Vector2(v[i].x, v[i].z), Vector2(v[i + 1].x, v[i + 1].z), Vector2(v[i + 2].x, v[i + 2].z)])
	var bad := 0
	for key in levels:
		var tris: Array = levels[key]
		for gx in range(-41, 42):
			for gz in range(-41, 42):
				var p := Vector2(gx * 0.0097 + 0.00131, gz * 0.0097 + 0.00173)   # off-grid: avoid shared edges
				var cover := 0
				for t in tris:
					if Geometry2D.point_is_inside_triangle(p, t[0], t[1], t[2]):
						cover += 1
				if cover > 1:
					bad += 1
	return bad


func test_surfaces() -> void:
	var st := _names(Kit.storey(0.6))
	for n in ["body", "body_dark", "trim", "glass", "accent", "pot", "plant"]:
		check(n in st, "storey has %s surface" % n)
	var base := _names(Kit.base_storey(0.6))
	for n in ["body2", "wall2", "trim", "glass", "accent"]:
		check(n in base, "base storey has %s surface" % n)
	check("emissive" in _names(Kit.roof(false)) and "emissive" in _names(Kit.roof(true)), "roofs have emissive lights")


func test_turned_width_matches_gameplay() -> void:
	# core footprint turned by the building yaw should span close to one gameplay unit on screen
	var core := 2.0 * Kit.C
	var on_screen := core * (cos(YAW) + sin(YAW))
	check(on_screen > 0.85 and on_screen < 1.0, "turned core spans %.2f units (gameplay width 1.0)" % on_screen)
	var aabb := Kit.storey(0.6).get_aabb()
	check(absf(aabb.size.y - 0.6) < 0.001 and aabb.position.y > -0.0001, "storey is exactly one block tall, origin at the bottom")
	check(absf(Kit.base_storey(0.6).get_aabb().size.y - 0.6) < 0.001, "base storey is one block tall too")


func test_no_coplanar_top_faces() -> void:
	check(_coplanar_overlaps([Kit.storey(0.6)]) == 0, "storey has no overlapping top faces")
	check(_coplanar_overlaps([Kit.base_storey(0.6)]) == 0, "base storey has no overlapping top faces")
	check(_coplanar_overlaps([Kit.roof(false)]) == 0, "roof has no overlapping top faces")
	check(_coplanar_overlaps([LowPoly.plaza(4.0)]) == 0, "plaza has no overlapping top faces")


func test_faces_point_outward() -> void:
	var m := Kit.storey(0.6)
	var arr := m.surface_get_arrays(0)    # body core
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ok := true
	for i in range(0, v.size(), 3):
		var centroid := (v[i] + v[i + 1] + v[i + 2]) / 3.0
		if n[i].dot(centroid - Vector3(0, 0.3, 0)) < -0.001:
			ok = false
	check(ok, "storey core faces point outward")
