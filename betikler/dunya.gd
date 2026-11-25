extends RefCounted
## İlk mahalleyi kurar: yollar, kaldırımlar, ev, bakkal, kahvehane, hastane, park, apartmanlar, lambalar.
## Koordinatlar: -Z kuzey (kameradan uzak), +Z güney (kameraya yakın). Bina kapıları +Z'ye bakar.
## Sprite Atölye'den gelen dokular (assets/uretilen/doku_*.png) varsa otomatik kullanılır.

const IC_MEKAN := preload("res://betikler/ic_mekan.gd")
const BOLGE := preload("res://betikler/bolge.gd")
const Karakter := preload("res://betikler/karakter.gd")

const YOLLAR := [-60.0, 0.0, 60.0]
const YOL_EN := 10.0
const SINIR := 97.0
## Halkın yürüdüğü kaldırım hatları (yol ± 6 m)
const HATLAR := [-66.0, -54.0, -6.0, 6.0, 54.0, 66.0]
## Yollar arasındaki kaldırım parçaları
const ARALIKLAR := [[-100.0, -67.0], [-53.0, -7.0], [7.0, 53.0], [67.0, 100.0]]

static var _onbellek := {}


static func malzeme(renk: Color, doku := "", olcek := 0.25) -> StandardMaterial3D:
	var anahtar := "%s|%s|%s" % [renk.to_html(), doku, olcek]
	if _onbellek.has(anahtar):
		return _onbellek[anahtar]
	var m := StandardMaterial3D.new()
	m.albedo_color = renk
	m.roughness = 0.9
	if doku != "":
		var yol := "res://assets/uretilen/%s.png" % doku
		if ResourceLoader.exists(yol):
			m.albedo_texture = load(yol)
			m.albedo_color = Color.WHITE.lerp(renk, 0.3)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE * olcek
	_onbellek[anahtar] = m
	return m


static func kutu(ebeveyn: Node3D, boyut: Vector3, konum: Vector3, mat: Material, carpisma := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = boyut
	mi.mesh = bm
	mi.material_override = mat
	mi.position = konum
	ebeveyn.add_child(mi)
	if carpisma:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = boyut
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func silindir(ebeveyn: Node3D, yaricap: float, boy: float, konum: Vector3, mat: Material, carpisma := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = yaricap
	cm.bottom_radius = yaricap
	cm.height = boy
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = mat
	mi.position = konum
	ebeveyn.add_child(mi)
	if carpisma:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = yaricap
		sh.height = boy
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


## Çok sayıda aynı kutuyu tek çizimde basar (pencereler, yol çizgileri): telefonda akıcılık için.
static func toplu(kok: Node3D, boyut: Vector3, mat: Material, konumlar: Array) -> void:
	if konumlar.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = boyut
	mm.mesh = bm
	mm.instance_count = konumlar.size()
	for i in konumlar.size():
		mm.set_instance_transform(i, Transform3D(Basis(), konumlar[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	kok.add_child(mmi)


static func bolge(ebeveyn: Node3D, konum: Vector3, boyut: Vector3, eylem: String, metin: String, sonuc: Dictionary, kisi := "", kisi_ad := "") -> void:
	var a = BOLGE.new()
	a.eylem = eylem
	a.metin = metin
	a.kisi = kisi
	a.kisi_ad = kisi_ad
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = boyut
	cs.shape = sh
	a.add_child(cs)
	a.position = konum
	ebeveyn.add_child(a)
	# yerde parlayan halka
	var isaret := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 0.02
	isaret.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.2, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	isaret.material_override = m
	isaret.position = Vector3(0, -konum.y + 0.09, 0)
	a.add_child(isaret)
	sonuc["bolgeler"].append(a)


static func sabit_kisi(ebeveyn: Node3D, konum: Vector3, gomlek: Color, rng: RandomNumberGenerator) -> void:
	var o: Array = [Color(1.0, 0.87, 0.74), Color(0.94, 0.76, 0.6), Color(0.8, 0.6, 0.43)]
	var model := Karakter.olustur(o[rng.randi() % o.size()], Color(0.1 + rng.randf() * 0.3, 0.08, 0.05), rng.randi() % 3, gomlek, Color(0.15, 0.15, 0.2), rng.randf() < 0.4)
	model.position = konum
	ebeveyn.add_child(model)


## İçine girilebilen bina. Döndürdüğü düğümün yerel koordinatlarına mobilya eklenir.
static func bina(kok: Node3D, merkez: Vector3, w: float, d: float, h: float, duvar: Color, cati_renk: Color, tabela: String, sonuc: Dictionary, zemin := Color(0.62, 0.5, 0.38)) -> Node3D:
	var n := Node3D.new()
	n.position = merkez
	kok.add_child(n)
	var t := 0.3
	var kapi := 2.2
	var kh := 2.6
	var dm := malzeme(duvar, "doku_siva", 0.3)
	var on: Array = []
	kutu(n, Vector3(w, h, t), Vector3(0, h / 2, -d / 2 + t / 2), dm)
	kutu(n, Vector3(t, h, d), Vector3(-w / 2 + t / 2, h / 2, 0), dm)
	kutu(n, Vector3(t, h, d), Vector3(w / 2 - t / 2, h / 2, 0), dm)
	var yan := (w - kapi) / 2.0
	on.append(kutu(n, Vector3(yan, h, t), Vector3(-w / 2 + yan / 2, h / 2, d / 2 - t / 2), dm))
	on.append(kutu(n, Vector3(yan, h, t), Vector3(w / 2 - yan / 2, h / 2, d / 2 - t / 2), dm))
	on.append(kutu(n, Vector3(kapi, h - kh, t), Vector3(0, kh + (h - kh) / 2, d / 2 - t / 2), dm))
	# ön camlar
	var cam := malzeme(Color(0.35, 0.5, 0.65))
	for s in [-1.0, 1.0]:
		on.append(kutu(n, Vector3(minf(yan - 1.0, 2.4), 1.2, 0.06), Vector3(s * (kapi / 2 + yan / 2), 1.5, d / 2 + 0.01), cam, false))
	kutu(n, Vector3(w - 2 * t, 0.06, d - 2 * t), Vector3(0, 0.03, 0), malzeme(zemin, "doku_parke", 0.5), false)
	var cati := kutu(n, Vector3(w + 0.6, 0.35, d + 0.6), Vector3(0, h + 0.175, 0), malzeme(cati_renk, "doku_cati", 0.4), false)
	if tabela != "":
		var l := Label3D.new()
		l.text = tabela
		l.font_size = 90
		l.pixel_size = 0.01
		l.outline_size = 16
		l.modulate = Color(1.0, 0.95, 0.8)
		l.position = Vector3(0, kh + (h - kh) / 2, d / 2 + 0.05)
		n.add_child(l)
		on.append(l)
	# iç ışık (gece yanar)
	var isik := OmniLight3D.new()
	isik.position = Vector3(0, h - 0.6, 0)
	isik.omni_range = maxf(w, d) * 0.8
	isik.light_energy = 1.2
	isik.light_color = Color(1.0, 0.88, 0.7)
	isik.visible = false
	n.add_child(isik)
	sonuc["lambalar"].append(isik)
	# iç mekan alanı
	var a = IC_MEKAN.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w - 2 * t, h, d - 2 * t)
	cs.shape = bs
	cs.position.y = h / 2
	a.add_child(cs)
	a.gizlenecekler = on + [cati]
	n.add_child(a)
	sonuc["ic_mekanlar"].append(a)
	return n


static func apartman(kok: Node3D, merkez: Vector3, w: float, d: float, h: float, renk: Color, sonuc: Dictionary) -> void:
	kutu(kok, Vector3(w, h, d), merkez + Vector3(0, h / 2, 0), malzeme(renk, "doku_siva", 0.3))
	kutu(kok, Vector3(w + 0.4, 0.4, d + 0.4), merkez + Vector3(0, h + 0.2, 0), malzeme(renk.darkened(0.35)), false)
	var kat := int(h / 3.0)
	var sutun := maxi(1, int((w - 1.0) / 2.5))
	for k in kat:
		for s in sutun:
			var x := -((sutun - 1) * 2.5) / 2.0 + s * 2.5
			if k == 0 and absf(x) < 1.3:
				continue
			sonuc["pencereler"].append(merkez + Vector3(x, 1.6 + k * 3.0, d / 2 + 0.03))
	sonuc["kapilar"].append(merkez + Vector3(0, 1.1, d / 2 + 0.03))


static func agac(kok: Node3D, konum: Vector3, rng: RandomNumberGenerator) -> void:
	silindir(kok, 0.18, 2.4, konum + Vector3(0, 1.2, 0), malzeme(Color(0.4, 0.27, 0.15)))
	var yesil := Color(0.2 + rng.randf() * 0.15, 0.45 + rng.randf() * 0.2, 0.18)
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	var r := rng.randf_range(1.3, 2.0)
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	mi.mesh = s
	mi.material_override = malzeme(yesil, "doku_yaprak", 0.5)
	mi.position = konum + Vector3(0, 2.4 + r * 0.7, 0)
	kok.add_child(mi)


static func araba(kok: Node3D, konum: Vector3, renk: Color, aci: float) -> void:
	var n := Node3D.new()
	n.position = konum
	n.rotation.y = aci
	kok.add_child(n)
	kutu(n, Vector3(1.8, 0.7, 4.2), Vector3(0, 0.6, 0), malzeme(renk))
	kutu(n, Vector3(1.6, 0.6, 2.2), Vector3(0, 1.25, -0.2), malzeme(Color(0.25, 0.32, 0.4)), false)
	for x in [-0.85, 0.85]:
		for z in [-1.35, 1.35]:
			kutu(n, Vector3(0.25, 0.6, 0.6), Vector3(x, 0.3, z), malzeme(Color(0.08, 0.08, 0.08)), false)


static func lamba(kok: Node3D, konum: Vector3, sonuc: Dictionary) -> void:
	silindir(kok, 0.08, 4.5, konum + Vector3(0, 2.25, 0), malzeme(Color(0.25, 0.25, 0.28)))
	var bas := malzeme(Color(1.0, 0.95, 0.75))
	kutu(kok, Vector3(0.5, 0.2, 0.5), konum + Vector3(0, 4.55, 0), bas, false)
	var isik := OmniLight3D.new()
	isik.position = konum + Vector3(0, 4.2, 0)
	isik.omni_range = 10.0
	isik.light_energy = 1.5
	isik.light_color = Color(1.0, 0.85, 0.6)
	isik.visible = false
	kok.add_child(isik)
	sonuc["lambalar"].append(isik)


static func yuruyus_yolu(kok: Node3D, x: float, z1: float, z2: float) -> void:
	kutu(kok, Vector3(2.4, 0.06, absf(z2 - z1)), Vector3(x, 0.03, (z1 + z2) / 2), malzeme(Color(0.7, 0.68, 0.64), "doku_kaldirim", 0.5), false)


static func kur(kok: Node3D) -> Dictionary:
	var sonuc := {"lambalar": [], "bolgeler": [], "ic_mekanlar": [], "pencereler": [], "kapilar": [], "baslangic": Vector3(30, 0, -9), "ev_yatak": Vector3(30, 0, -15)}
	var rng := RandomNumberGenerator.new()
	rng.seed = 61

	# --- zemin: 20 m'lik parçalar (gece lambaları her parçayı ayrı aydınlatabilsin diye)
	var cimen := malzeme(Color(0.36, 0.55, 0.28), "doku_cimen", 0.25)
	for ix in 10:
		for iz in 10:
			kutu(kok, Vector3(20, 0.2, 20), Vector3(-90 + ix * 20, -0.1, -90 + iz * 20), cimen, false)
	var zemin := StaticBody3D.new()
	var zcs := CollisionShape3D.new()
	var zsh := BoxShape3D.new()
	zsh.size = Vector3(200, 1, 200)
	zcs.shape = zsh
	zcs.position.y = -0.5
	zemin.add_child(zcs)
	kok.add_child(zemin)
	# görünmez sınır duvarları
	for i in 4:
		var yatay := i < 2
		var isaret := -1.0 if i % 2 == 0 else 1.0
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(200, 10, 1) if yatay else Vector3(1, 10, 200)
		cs.shape = sh
		cs.position = Vector3(0, 5, isaret * SINIR) if yatay else Vector3(isaret * SINIR, 5, 0)
		sb.add_child(cs)
		kok.add_child(sb)

	# --- yollar, kaldırımlar, şerit çizgileri, lambalar
	var asfalt := malzeme(Color(0.22, 0.22, 0.24), "doku_asfalt", 0.2)
	var kaldirim := malzeme(Color(0.72, 0.7, 0.66), "doku_kaldirim", 0.5)
	var cizgiler: Array = []
	for r in YOLLAR:
		for c in range(-90, 100, 20):
			kutu(kok, Vector3(YOL_EN, 0.04, 20), Vector3(r, 0.02, c), asfalt, false)
			kutu(kok, Vector3(20, 0.04, YOL_EN), Vector3(c, 0.021, r), asfalt, false)
		for ar in ARALIKLAR:
			var orta: float = (ar[0] + ar[1]) / 2.0
			var boy: float = ar[1] - ar[0]
			for s in [-6.0, 6.0]:
				kutu(kok, Vector3(2, 0.06, boy), Vector3(r + s, 0.03, orta), kaldirim, false)
				kutu(kok, Vector3(boy, 0.06, 2), Vector3(orta, 0.031, r + s), kaldirim, false)
			var z: float = ar[0] + 2.0
			while z < ar[1] - 2.0:
				cizgiler.append(Vector3(r, 0.05, z + 1.0))
				cizgiler.append(Vector3(z + 1.0, 0.051, r))
				z += 6.0
		for p in [-85.0, -70.0, -40.0, -20.0, 20.0, 40.0, 70.0, 85.0]:
			lamba(kok, Vector3(r + 6.6, 0, p), sonuc)
			lamba(kok, Vector3(p, 0, r + 6.6), sonuc)
	var beyaz := malzeme(Color(0.92, 0.92, 0.85))
	var dikey: Array = []
	var yatay_c: Array = []
	for i in cizgiler.size():
		if i % 2 == 0:
			dikey.append(cizgiler[i])
		else:
			yatay_c.append(cizgiler[i])
	toplu(kok, Vector3(0.18, 0.02, 2.0), beyaz, dikey)
	toplu(kok, Vector3(2.0, 0.02, 0.18), beyaz, yatay_c)

	# --- EV (kuzeydoğu blok)
	var ev := bina(kok, Vector3(30, 0, -16), 10.0, 8.0, 3.4, Color(0.93, 0.87, 0.75), Color(0.6, 0.25, 0.2), "", sonuc)
	kutu(ev, Vector3(1.8, 0.45, 2.4), Vector3(-3.2, 0.225, -2.4), malzeme(Color(0.45, 0.3, 0.18)))
	kutu(ev, Vector3(1.7, 0.15, 1.8), Vector3(-3.2, 0.52, -2.1), malzeme(Color(0.25, 0.4, 0.7)), false)
	kutu(ev, Vector3(1.2, 0.12, 0.45), Vector3(-3.2, 0.55, -3.3), malzeme(Color(0.95, 0.95, 0.95)), false)
	kutu(ev, Vector3(1.2, 0.75, 0.8), Vector3(2.5, 0.375, -2.9), malzeme(Color(0.55, 0.38, 0.22)))
	kutu(ev, Vector3(1.5, 2.0, 0.6), Vector3(4.2, 1.0, -3.3), malzeme(Color(0.5, 0.35, 0.2)))
	kutu(ev, Vector3(2.2, 0.8, 0.9), Vector3(2.8, 0.4, 1.5), malzeme(Color(0.3, 0.5, 0.35)))
	kutu(ev, Vector3(3.0, 0.02, 2.0), Vector3(0, 0.07, 0.3), malzeme(Color(0.7, 0.25, 0.2)), false)
	bolge(ev, Vector3(-3.2, 1, -1.2), Vector3(3.0, 2, 3.4), "uyu", "Uyu (sabah 07:00'ye kadar)", sonuc)
	yuruyus_yolu(kok, 30, -12, -7)
	apartman(kok, Vector3(14, 0, -16), 8, 8, 4, Color(0.85, 0.8, 0.7), sonuc)
	apartman(kok, Vector3(46, 0, -16), 8, 8, 4, Color(0.8, 0.85, 0.78), sonuc)
	for x in [14.0, 30.0, 46.0]:
		apartman(kok, Vector3(x, 0, -40), 12, 12, rng.randi_range(3, 5) * 3.0, Color(0.75 + rng.randf() * 0.2, 0.7 + rng.randf() * 0.2, 0.62 + rng.randf() * 0.2), sonuc)
	for x in [22.0, 38.0]:
		agac(kok, Vector3(x, 0, -10), rng)

	# --- BAKKAL + PARK (kuzeybatı blok)
	var bakkal := bina(kok, Vector3(-30, 0, -14), 12.0, 10.0, 4.2, Color(0.95, 0.9, 0.6), Color(0.3, 0.45, 0.6), "BAKKAL", sonuc)
	for x in [-4.5, -2.5]:
		kutu(bakkal, Vector3(0.6, 1.8, 4.0), Vector3(x, 0.9, -1.5), malzeme(Color(0.6, 0.45, 0.3)))
	kutu(bakkal, Vector3(8.0, 2.0, 0.6), Vector3(0, 1.0, -4.3), malzeme(Color(0.6, 0.45, 0.3)))
	var urun := [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.75, 0.3)]
	for i in 14:
		kutu(bakkal, Vector3(0.4, 0.3, 0.3), Vector3(-3.6 + i * 0.55, 2.15, -4.3), malzeme(urun[i % 4]), false)
	kutu(bakkal, Vector3(3.0, 1.0, 0.8), Vector3(3.5, 0.5, 0.8), malzeme(Color(0.5, 0.33, 0.2)))
	sabit_kisi(bakkal, Vector3(3.5, 0, -0.2), Color(0.95, 0.95, 0.95), rng)
	bolge(bakkal, Vector3(3.5, 1, 2.2), Vector3(3.0, 2, 1.8), "simit", "Simit + ayran al (25 TL)", sonuc, "bakkal_hasan", "Bakkal Hasan Amca")
	yuruyus_yolu(kok, -30, -9, -7)
	apartman(kok, Vector3(-46, 0, -14), 10, 10, 9, Color(0.82, 0.72, 0.62), sonuc)
	apartman(kok, Vector3(-14, 0, -14), 10, 10, 12, Color(0.72, 0.76, 0.82), sonuc)
	kutu(kok, Vector3(44, 0.04, 26), Vector3(-30, 0.02, -38), malzeme(Color(0.32, 0.6, 0.3), "doku_cimen", 0.3), false)
	for i in 14:
		agac(kok, Vector3(-50 + rng.randf() * 40, 0, -52 + rng.randf() * 26), rng)
	silindir(kok, 2.2, 0.6, Vector3(-30, 0.3, -38), malzeme(Color(0.7, 0.7, 0.72)))
	silindir(kok, 1.9, 0.08, Vector3(-30, 0.62, -38), malzeme(Color(0.3, 0.55, 0.85)), false)
	for x in [-36.0, -24.0]:
		kutu(kok, Vector3(2.0, 0.45, 0.6), Vector3(x, 0.225, -33), malzeme(Color(0.5, 0.33, 0.2)))

	# --- KAHVEHANE (güneybatı blok)
	var kahve := bina(kok, Vector3(-30, 0, 46), 14.0, 10.0, 4.2, Color(0.88, 0.75, 0.6), Color(0.45, 0.25, 0.15), "KAHVEHANE", sonuc)
	for p in [Vector3(-4, 0, -1), Vector3(0, 0, -1), Vector3(-4, 0, 2.5), Vector3(0, 0, 2.5)]:
		silindir(kahve, 0.55, 0.75, p + Vector3(0, 0.375, 0), malzeme(Color(0.55, 0.38, 0.22)))
		for s in [-0.9, 0.9]:
			kutu(kahve, Vector3(0.45, 0.45, 0.45), p + Vector3(s, 0.225, 0), malzeme(Color(0.4, 0.26, 0.15)))
	kutu(kahve, Vector3(4.0, 1.0, 0.8), Vector3(4.5, 0.5, -3.5), malzeme(Color(0.5, 0.33, 0.2)))
	silindir(kahve, 0.25, 0.6, Vector3(4.0, 1.3, -3.5), malzeme(Color(0.8, 0.7, 0.4)), false)
	sabit_kisi(kahve, Vector3(4.5, 0, -4.4), Color(0.9, 0.9, 0.9), rng)
	sabit_kisi(kahve, Vector3(-4.9, 0, -1), Color(0.4, 0.3, 0.25), rng)
	sabit_kisi(kahve, Vector3(0.9, 0, 2.5), Color(0.3, 0.35, 0.5), rng)
	bolge(kahve, Vector3(4.5, 1, -2.0), Vector3(4.0, 2, 1.8), "cay", "Çay iç (10 TL)", sonuc, "kahveci_riza", "Kahveci Rıza Usta")
	yuruyus_yolu(kok, -30, 51, 53)
	apartman(kok, Vector3(-47, 0, 46), 8, 9, 6, Color(0.9, 0.82, 0.7), sonuc)
	apartman(kok, Vector3(-13, 0, 46), 10, 9, 9, Color(0.78, 0.8, 0.72), sonuc)
	for x in [-45.0, -30.0, -15.0]:
		apartman(kok, Vector3(x, 0, 20), 12, 10, rng.randi_range(3, 6) * 3.0, Color(0.7 + rng.randf() * 0.25, 0.7 + rng.randf() * 0.2, 0.65 + rng.randf() * 0.2), sonuc)

	# --- HASTANE + OTOPARK (güneydoğu blok)
	var hst := bina(kok, Vector3(30, 0, 44), 26.0, 14.0, 7.0, Color(0.94, 0.95, 0.97), Color(0.55, 0.6, 0.65), "HASTANE", sonuc, Color(0.85, 0.87, 0.88))
	var arti := Label3D.new()
	arti.text = "+"
	arti.font_size = 260
	arti.pixel_size = 0.01
	arti.modulate = Color(0.9, 0.1, 0.1)
	arti.outline_size = 20
	arti.position = Vector3(9, 5.0, 7.06)
	hst.add_child(arti)
	kutu(hst, Vector3(5.0, 1.1, 1.0), Vector3(0, 0.55, -2.0), malzeme(Color(0.85, 0.85, 0.9)))
	sabit_kisi(hst, Vector3(-1.0, 0, -3.0), Color(0.97, 0.97, 0.97), rng)
	sabit_kisi(hst, Vector3(1.2, 0, -3.0), Color(0.3, 0.6, 0.65), rng)
	for x in [8.0, 10.0]:
		kutu(hst, Vector3(0.9, 0.7, 2.0), Vector3(x, 0.35, -4.0), malzeme(Color(0.95, 0.95, 0.95)))
	for i in 6:
		kutu(hst, Vector3(0.6, 0.5, 0.6), Vector3(-10.0 + i * 0.8, 0.25, 2.0), malzeme(Color(0.3, 0.45, 0.7)))
	bolge(hst, Vector3(0, 1, -0.6), Vector3(5.0, 2, 1.8), "nobet", "Nöbete gir (8 saat, +400 TL)", sonuc, "doktor_selin", "Başhekim Dr. Selin")
	yuruyus_yolu(kok, 30, 51, 53)
	kutu(kok, Vector3(40, 0.05, 24), Vector3(30, 0.025, 21), malzeme(Color(0.3, 0.3, 0.32), "doku_asfalt", 0.2), false)
	var park_cizgi: Array = []
	for i in 9:
		park_cizgi.append(Vector3(13.0 + i * 4.0, 0.06, 15.0))
		park_cizgi.append(Vector3(13.0 + i * 4.0, 0.06, 27.0))
	toplu(kok, Vector3(0.15, 0.02, 4.5), beyaz, park_cizgi)
	var araba_renk := [Color(0.8, 0.1, 0.1), Color(0.1, 0.3, 0.7), Color(0.9, 0.9, 0.9), Color(0.15, 0.15, 0.15), Color(0.9, 0.75, 0.1)]
	for i in 8:
		if rng.randf() < 0.75:
			araba(kok, Vector3(15.0 + i * 4.0, 0, 15.0 if i % 2 == 0 else 27.0), araba_renk[rng.randi() % araba_renk.size()], 0.0)

	# --- dış halka: apartman blokları
	for xa in ARALIKLAR:
		for za in ARALIKLAR:
			var ic: bool = absf(xa[0]) < 60.0 and absf(za[0]) < 60.0
			if ic:
				continue
			var xb: float = xa[1] - xa[0]
			var zb: float = za[1] - za[0]
			var nx := maxi(1, int(xb / 14.0))
			var nz := maxi(1, int(zb / 14.0))
			for i in nx:
				for j in nz:
					var hx := xb / nx
					var hz := zb / nz
					var c := Vector3(xa[0] + hx * (i + 0.5), 0, za[0] + hz * (j + 0.5))
					if rng.randf() < 0.15:
						agac(kok, c, rng)
						continue
					var renk := Color(0.65 + rng.randf() * 0.3, 0.6 + rng.randf() * 0.3, 0.55 + rng.randf() * 0.3)
					apartman(kok, c, hx - 3.0, hz - 3.0, rng.randi_range(2, 7) * 3.0, renk, sonuc)

	# --- pencereler ve kapılar tek çizimde
	var pencere := StandardMaterial3D.new()
	pencere.albedo_color = Color(0.25, 0.35, 0.5)
	pencere.emission_enabled = true
	pencere.emission = Color(1.0, 0.8, 0.45)
	pencere.emission_energy_multiplier = 0.0
	toplu(kok, Vector3(1.2, 1.4, 0.08), pencere, sonuc["pencereler"])
	toplu(kok, Vector3(1.4, 2.2, 0.08), malzeme(Color(0.35, 0.22, 0.12)), sonuc["kapilar"])
	sonuc["pencere_malzeme"] = pencere
	return sonuc
