extends RefCounted
## İnsan modeli (oyuncu ve halk için). Şimdilik basit şekillerden kuruluyor;
## ileride Sprite Atölye / Blender'dan gelen 3D modelle değiştirilecek.
## Modelin önü +Z yönüne bakar.


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


static func _kutu(ebeveyn: Node3D, boyut: Vector3, konum: Vector3, m: Material, ad := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = boyut
	mi.mesh = b
	mi.material_override = m
	mi.position = konum
	if ad != "":
		mi.name = ad
	ebeveyn.add_child(mi)
	return mi


static func _kure(ebeveyn: Node3D, yaricap: float, konum: Vector3, m: Material, olcek := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = yaricap
	s.height = yaricap * 2.0
	s.radial_segments = 16
	s.rings = 8
	mi.mesh = s
	mi.material_override = m
	mi.position = konum
	mi.scale = olcek
	ebeveyn.add_child(mi)
	return mi


static func olustur(ten: Color, sac: Color, sac_model: int, gomlek: Color, pantolon: Color, sakal: bool) -> Node3D:
	var kok := Node3D.new()
	kok.name = "Model"
	var mt := _mat(ten)
	var ms := _mat(sac)
	var mg := _mat(gomlek)
	var mp := _mat(pantolon)
	var ayakkabi := _mat(Color(0.1, 0.08, 0.07))
	var siyah := _mat(Color(0.05, 0.05, 0.05))
	# bacaklar (kalçadan döner)
	for i in 2:
		var pivot := Node3D.new()
		pivot.name = "BacakSol" if i == 0 else "BacakSag"
		pivot.position = Vector3(-0.12 if i == 0 else 0.12, 0.92, 0.0)
		kok.add_child(pivot)
		_kutu(pivot, Vector3(0.17, 0.82, 0.2), Vector3(0, -0.41, 0), mp)
		_kutu(pivot, Vector3(0.18, 0.1, 0.3), Vector3(0, -0.87, 0.04), ayakkabi)
	# gövde
	_kutu(kok, Vector3(0.48, 0.62, 0.28), Vector3(0, 1.22, 0), mg, "Govde")
	# kollar (omuzdan döner)
	for i in 2:
		var pivot := Node3D.new()
		pivot.name = "KolSol" if i == 0 else "KolSag"
		pivot.position = Vector3(-0.31 if i == 0 else 0.31, 1.5, 0.0)
		kok.add_child(pivot)
		_kutu(pivot, Vector3(0.13, 0.58, 0.15), Vector3(0, -0.28, 0), mg)
		_kure(pivot, 0.07, Vector3(0, -0.62, 0), mt)
	# boyun, baş, yüz
	_kutu(kok, Vector3(0.12, 0.08, 0.12), Vector3(0, 1.57, 0), mt)
	_kure(kok, 0.17, Vector3(0, 1.76, 0), mt)
	_kutu(kok, Vector3(0.04, 0.04, 0.02), Vector3(-0.06, 1.79, 0.16), siyah)
	_kutu(kok, Vector3(0.04, 0.04, 0.02), Vector3(0.06, 1.79, 0.16), siyah)
	_kutu(kok, Vector3(0.04, 0.06, 0.05), Vector3(0, 1.74, 0.17), mt)
	match sac_model:
		0:
			_kure(kok, 0.18, Vector3(0, 1.86, -0.03), ms, Vector3(1.0, 0.65, 1.0))
		1:
			_kure(kok, 0.18, Vector3(0, 1.85, -0.03), ms, Vector3(1.05, 0.7, 1.05))
			_kutu(kok, Vector3(0.34, 0.34, 0.1), Vector3(0, 1.66, -0.14), ms)
		_:
			pass
	if sakal:
		_kutu(kok, Vector3(0.26, 0.11, 0.1), Vector3(0, 1.64, 0.1), ms)
	return kok


## Yürüme salınımı. miktar 0 = durur.
static func yuru(model: Node3D, faz: float, miktar: float) -> void:
	var s := sin(faz) * miktar
	for ad in ["BacakSol", "KolSag"]:
		var n := model.get_node_or_null(ad) as Node3D
		if n:
			n.rotation.x = s * (0.7 if ad.begins_with("Bacak") else 0.5)
	for ad in ["BacakSag", "KolSol"]:
		var n := model.get_node_or_null(ad) as Node3D
		if n:
			n.rotation.x = -s * (0.7 if ad.begins_with("Bacak") else 0.5)
