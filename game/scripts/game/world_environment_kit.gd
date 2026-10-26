## Original code-native environmental models. Unit artistic topology, scaled by JSON.
extends RefCounted
const Kit := preload("res://scripts/game/building_kit.gd")


static func model(kind: String, sides: int) -> ArrayMesh:
	var b := Kit.Builder.new()
	match kind:
		"tree", "pine", "cypress":
			b.frustum("trunk",Vector3.ZERO,.055,.04,.55,6)
			if kind=="cypress" or kind=="pine":
				for i in range(3):
					b.cone("leaf" if i%2==0 else "leaf_dark",Vector3(0,.18+i*.2,0),.48-i*.1,.5,7)
			else:
				for p in [Vector3(-.19,.55,0),Vector3(.17,.65,.08),Vector3(0,.85,-.06)]:
					_orb(b,"leaf" if p.x<0 else "leaf_dark",p,.34,sides)
		"mountain", "hill", "karst", "cliff", "snow_island", "ice":
			var rock := "ice" if kind in ["ice","snow_island"] else "stone"
			if kind not in ["mountain","hill"]:
				b.frustum(rock,Vector3(0,-.2,0),.62,.42,.85,7)
			if kind=="mountain":
				b.cone("mountain",Vector3(0,-.1,0),.6,1.1,7)
				b.cone("snow",Vector3(0,.80,0),.11,.2,7)
			elif kind=="hill":
				_dome(b,"mountain",Vector3.ZERO,.6,.85,sides)
			elif kind=="karst":
				b.frustum("stone",Vector3(0,.45,0),.42,.28,.5,7)
				b.frustum("leaf",Vector3(0,.92,0),.3,.28,.08,7)
			else:
				b.frustum("snow" if kind in ["ice","snow_island"] else "grass",Vector3(0,.60,0),.43,.44,.08,7)
		"hedge":
			b.box("leaf",Vector3(-.5,0,-.5),Vector3(.5,1,.5))
		"flowers":
			for x in [-.35,0.0,.35]:
				for z in [-.4,-.1,.2,.45]:
					b.blob("flower" if z<0 else "gold",Vector3(x,.4,z),.18)
		"column":
			b.frustum("trim",Vector3.ZERO,.5,.37,.12,sides)
			b.frustum("body",Vector3(0,.12,0),.24,.21,.75,sides)
			b.frustum("trim",Vector3(0,.87,0),.37,.5,.13,sides)
		"fountain":
			b.frustum("trim",Vector3.ZERO,.5,.5,.12,sides)
			b.frustum("water",Vector3(0,.125,0),.43,.43,.015,sides)
			b.frustum("trim",Vector3(0,.13,0),.08,.06,.4,sides)
			b.frustum("trim",Vector3(0,.45,0),.25,.1,.12,sides)
		"bridge", "cable_bridge":
			_bridge(b,kind=="cable_bridge")
		"wall", "fence":
			if kind=="wall":
				b.box("stone",Vector3(-.5,0,-.4),Vector3(.5,.8,.4))
				for i in range(9): b.box("trim",Vector3(-.5+i*.12,.8,-.45),Vector3(-.44+i*.12,1,.45))
			else:
				for i in range(21): b.box("metal",Vector3(-.5+i*.05,0,-.05),Vector3(-.495+i*.05,1,.05))
				for y in [.15,.65,.95]: b.box("metal",Vector3(-.5,y,-.05),Vector3(.5,y+.018,.05))
		"pier":
			b.box("trunk",Vector3(-.5,.6,-.5),Vector3(.5,.74,.5))
			for x in [-.44,.44]:
				for z in [-.4,0.0,.4]: b.frustum("trunk",Vector3(x,-.5,z),.05,.05,1.2,6)
			for j in range(11):b.box("path",Vector3(-.5,.74,-.5+j*.09),Vector3(.5,.78,-.46+j*.09))
		"tank", "stack", "refinery", "harbor_crane":
			_industry(b,kind,sides)
		"igloo":
			_dome(b,"snow",Vector3.ZERO,.5,.8,sides)
			for y in [.23,.45,.62]:b.frustum("ice",Vector3(0,y,0),sqrt(maxf(.01,1-pow(y/.8,2)))*.5,sqrt(maxf(.01,1-pow(y/.8,2)))*.5,.018,sides)
			b.arch("ice",0,.18,0,.32,.4,.57,8,0)
			b.arch("glass",0,.12,0,.28,.57,.58,8,0)
		"lighthouse":
			for i in range(5): b.frustum("red" if i%2 else "white",Vector3(0,i*.16,0),.28-i*.014,.266-i*.014,.16,sides)
			b.frustum("trim",Vector3(0,.8,0),.33,.33,.04,sides)
			b.frustum("gold",Vector3(0,.84,0),.20,.20,.10,sides)
			b.cone("red",Vector3(0,.94,0),.29,.14,sides)
		"watchtower":
			for x in [-.3,.3]:
				for z in [-.3,.3]: b.box("metal",Vector3(x,0,z),Vector3(x+.06,.7,z+.06))
			b.box("body",Vector3(-.5,.65,-.5),Vector3(.5,.9,.5))
			b.box("glass",Vector3(-.4,.73,.501),Vector3(.4,.86,.51))
			b.cone("roof",Vector3(0,.9,0),.76,.13,4,PI*.25)
		_:
			_building(b,kind,sides)
	return b.commit()


static func _dome(b,slot: String,at: Vector3,r: float,h: float,sides: int) -> void:
	for i in range(5):
		var a0 := float(i)/5.0*PI*.5
		var a1 := float(i+1)/5.0*PI*.5
		b.frustum(slot,at+Vector3(0,sin(a0)*h,0),cos(a0)*r,cos(a1)*r,(sin(a1)-sin(a0))*h,sides)


static func _orb(b,slot: String,at: Vector3,r: float,sides: int) -> void:
	for i in range(7):
		var a0 := -PI*.5+PI*float(i)/7.0
		var a1 := -PI*.5+PI*float(i+1)/7.0
		b.frustum(slot,at+Vector3(0,sin(a0)*r,0),maxf(.001,cos(a0)*r),maxf(.001,cos(a1)*r),(sin(a1)-sin(a0))*r,sides)


static func _building(b,kind: String,sides: int) -> void:
	var height := .78
	if kind=="cottage": height=.62
	b.box("body",Vector3(-.46,0,-.38),Vector3(.46,height,.38))
	for y in [.02,.25,.5,.76]:
		if y<=height:b.box("trim",Vector3(-.5,y,-.42),Vector3(.5,y+.025,.42))
	# Facades are original model geometry: deep windows, lintels and corner pilasters.
	var base_xf: Transform3D=b.xf
	for side in range(4):
		b.xf=base_xf*Transform3D(Basis(Vector3.UP,side*PI*.5),Vector3.ZERO)
		if kind=="office":
			b.box("glass",Vector3(-.43,.05,.385),Vector3(.43,.75,.40))
			for x in [-.4,-.2,0.0,.2,.4]:b.box("trim",Vector3(x,.04,.4),Vector3(x+.012,.77,.42))
			for y in [.18,.37,.56,.75]:b.box("trim",Vector3(-.46,y,.4),Vector3(.46,y+.012,.42))
		else:
			for x in [-.3,0.0,.3]:
				for y in [.14,.39,.64]:
					if y>height-.08:continue
					if kind in ["manor","palace"]:
						b.arch("trim",x,.09,y-.06,y+.04,.38,.41,6,0)
						b.arch("glass",x,.065,y-.05,y+.04,.411,.42,6,0)
					else:
						b.box("glass",Vector3(x-.08,y-.06,.385),Vector3(x+.08,y+.08,.40))
						if kind=="prison":
							for k in [-.05,0.0,.05]:b.box("metal",Vector3(x+k,y-.06,.40),Vector3(x+k+.008,y+.08,.42))
			for x in [-.46,.43]:b.box("trim",Vector3(x,0,.39),Vector3(x+.03,height,.43))
		if kind=="pagoda":
			for x in [-.44,0.0,.44]:b.box("red",Vector3(x,0,.41),Vector3(x+.035,.8,.45))
	b.xf=base_xf
	match kind:
		"palace":
			b.frustum("trim",Vector3(0,.78,0),.35,.35,.08,sides)
			_dome(b,"blue",Vector3(0,.86,0),.36,.25,sides)
			b.frustum("gold",Vector3(0,1.1,0),.02,0,.15,6)
			for side in [-1.0,1.0]:
				b.frustum("body",Vector3(side*.42,0,0),.12,.12,.95,sides)
				_dome(b,"blue",Vector3(side*.42,.95,0),.15,.12,sides)
		"fort":
			for x in [-.48,-.22,.04,.30]:b.box("trim",Vector3(x,.78,-.43),Vector3(x+.15,.94,.43))
			for x in [-.4,.4]:
				b.frustum("body",Vector3(x,0,0),.16,.16,.94,sides)
				b.cone("blue",Vector3(x,.94,0),.18,.28,sides)
		"pagoda":
			for y in [.26,.52,.78]:
				b.cone("roof",Vector3(0,y,0),.77,.17,4,PI*.25)
				b.frustum("gold",Vector3(0,y+.15,0),.035,.015,.05,6)
		"manor", "cottage":
			var roof := "blue" if kind=="manor" else "red"
			b.cone(roof,Vector3(0,height,0),.74,.25,4,PI*.25)
			for x in [-.4,.4]:
				b.box("trim",Vector3(x-.025,height,-.1),Vector3(x+.035,1.08,.02))
			if kind=="manor":
				for x in [-.42,.42]:
					b.frustum("body",Vector3(x,0,.1),.16,.16,.92,sides)
					b.cone("blue",Vector3(x,.92,.1),.2,.3,sides)
		_:
			b.box("roof",Vector3(-.48,height,-.4),Vector3(.48,height+.06,.4))
			b.box("metal",Vector3(-.18,height+.06,-.15),Vector3(.1,height+.14,.1))


static func _bridge(b,cable: bool) -> void:
	b.box("stone",Vector3(-.56,.55,-.4),Vector3(.56,.64,.4))
	for x in [-.5,-.16,.18,.5]:b.box("stone",Vector3(x-.04,-.2,-.35),Vector3(x+.04,.55,.35))
	for z in [-.4,.4]:
		b.box("trim",Vector3(-.56,.72,z),Vector3(.56,.75,z+.015))
		for i in range(17):b.box("trim",Vector3(-.54+i*.068,.64,z),Vector3(-.528+i*.068,.74,z+.015))
	if cable:
		for x in [-.32,.32]:
			b.box("white",Vector3(x-.016,.62,-.08),Vector3(x+.016,1.2,.08))
			for i in range(8):
				var end := Vector3(x+float(i-4)*.065,.64,0)
				var top := Vector3(x,1.15,0)
				_beam(b,"white",top,end,.004)
	else:
		for x in [-.33,0.0,.33]:
			for i in range(10):
				var a0 := PI*float(i)/10
				var a1 := PI*float(i+1)/10
				for z in [-.35,.35]:
					var p0 := Vector3(x+cos(a0)*.15,.22+sin(a0)*.27,z)
					var p1 := Vector3(x+cos(a1)*.15,.22+sin(a1)*.27,z)
					b.quad("stone",p0,p1,p1+Vector3(0,.08,0),p0+Vector3(0,.08,0),Vector3.BACK)


static func _beam(b,slot: String,a: Vector3,c: Vector3,r: float) -> void:
	var old: Transform3D=b.xf
	b.xf=old*Transform3D(Basis(Quaternion(Vector3.UP,(c-a).normalized())),a)
	b.frustum(slot,Vector3.ZERO,r,r,a.distance_to(c),6)
	b.xf=old


static func _industry(b,kind: String,sides: int) -> void:
	match kind:
		"tank":
			b.frustum("metal",Vector3.ZERO,.45,.45,.7,sides)
			_dome(b,"trim",Vector3(0,.7,0),.45,.16,sides)
			for y in [.1,.35,.65]:b.frustum("white",Vector3(0,y,0),.46,.46,.02,sides)
		"stack":
			for i in range(8):b.frustum("red" if i%2 else "white",Vector3(0,i*.125,0),.43-i*.025,.405-i*.025,.125,sides)
		"harbor_crane":
			for x in [-.35,.35]:b.box("gold",Vector3(x,0,-.05),Vector3(x+.055,.8,.05))
			b.box("gold",Vector3(-.55,.8,-.04),Vector3(.55,.86,.04))
			_beam(b,"metal",Vector3(-.35,.1,0),Vector3(.35,.8,0),.018)
			_beam(b,"metal",Vector3(.35,.1,0),Vector3(-.35,.8,0),.018)
			b.box("dark",Vector3(.35,.2,0),Vector3(.36,.8,.01))
		_:
			b.box("body",Vector3(-.5,0,-.5),Vector3(.5,.3,.5))
			for x in [-.35,0.0,.35]:
				b.frustum("metal",Vector3(x,.3,0),.1,.1,.65,sides)
				b.cone("trim",Vector3(x,.95,0),.1,.05,sides)
				b.box("red",Vector3(x-.035,.28,.11),Vector3(x+.035,.8,.16))
			for y in [.35,.65,.88]:
				b.box("gold",Vector3(-.55,y,-.25),Vector3(.55,y+.025,.25))
				for z in [-.25,.25]:b.box("metal",Vector3(-.55,y+.10,z),Vector3(.55,y+.115,z+.015))


static func append(b,mesh: ArrayMesh,transform: Transform3D) -> void:
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var slot := mesh.surface_get_name(surface)
		for i in range(0,vertices.size(),3):
			b.tri(slot,transform*vertices[i],transform*vertices[i+1],transform*vertices[i+2],transform.basis.inverse().transposed()*normals[i])
