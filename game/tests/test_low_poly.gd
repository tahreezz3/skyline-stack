## Procedural low-poly meshes (scripts/game/low_poly.gd, T-0305): surface names match the
## artist spec, sizes match the rules, and every triangle faces outward with a flat normal.
extends "res://tests/test_case.gd"

const LowPoly := preload("res://scripts/game/low_poly.gd")


func _surface_names(mesh: ArrayMesh) -> Array[String]:
	var out: Array[String] = []
	for i in range(mesh.get_surface_count()):
		out.append(mesh.surface_get_name(i))
	return out


## Every triangle's stored normal agrees with its winding and points away from `centre`.
func _faces_outward(mesh: ArrayMesh, surface: int, centre: Vector3) -> bool:
	var arrays := mesh.surface_get_arrays(surface)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(0, v.size(), 3):
		var face_n := n[i]
		if not (n[i].is_equal_approx(n[i + 1]) and n[i].is_equal_approx(n[i + 2])):
			return false   # not flat-shaded
		var centroid := (v[i] + v[i + 1] + v[i + 2]) / 3.0
		if face_n.dot(centroid - centre) < -0.001:
			return false
		# Godot front faces are clockwise: the geometric normal of (a, b, c) must be opposite to the stored one
		var geo := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
		if LowPoly.EMIT_CLOCKWISE and geo.dot(face_n) > 0.0:
			return false
	return true


func test_storey_surfaces_and_size() -> void:
	var m := LowPoly.storey(0.6)
	check(_surface_names(m) == ["body", "trim", "glass"], "storey surfaces are body/trim/glass")
	var aabb := m.get_aabb()
	check(absf(aabb.size.x - 1.0) < 0.001 and absf(aabb.size.y - 0.6) < 0.001, "storey is 1.0 wide and block-height tall (%s)" % aabb.size)
	check(aabb.position.y >= -0.0001, "origin at the bottom")


func test_storey_body_faces_outward() -> void:
	var m := LowPoly.storey(0.6)
	check(_faces_outward(m, 0, Vector3(0, 0.3, 0)), "body triangles face outward, flat-shaded, clockwise")


func test_roofs() -> void:
	check(_surface_names(LowPoly.roof(false)) == ["trim", "body", "emissive"], "roof surfaces")
	check(_surface_names(LowPoly.roof(true)) == ["trim", "body", "emissive"], "trophy roof surfaces")
	check(LowPoly.roof(true).get_aabb().size.y > LowPoly.roof(false).get_aabb().size.y, "trophy roof is taller")


func test_environment_meshes_build() -> void:
	check(LowPoly.ridge(40.0, 10, 1.0, 3.0, 1).get_surface_count() == 1, "ridge builds")
	check(LowPoly.skyline(30.0, 2).get_surface_count() == 1, "skyline builds")
	check(LowPoly.cloud(3).get_surface_count() == 1, "cloud builds")
	check(LowPoly.plaza(20.0).get_surface_count() == 3, "plaza has ground, paving, plinth")
	check(LowPoly.tree().get_surface_count() == 2 and LowPoly.lamp().get_surface_count() == 2, "props build")


func test_ridge_is_deterministic() -> void:
	var a: PackedVector3Array = LowPoly.ridge(40.0, 10, 1.0, 3.0, 7).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var b: PackedVector3Array = LowPoly.ridge(40.0, 10, 1.0, 3.0, 7).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(a == b, "same seed gives the same mountains")
