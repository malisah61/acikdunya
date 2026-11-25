extends Node3D
## Ana sahne: dünyayı, oyuncuyu, kamerayı, halkı ve arayüzü kurar; gece-gündüz döngüsünü yönetir.

const Dunya := preload("res://betikler/dunya.gd")
const OYUNCU := preload("res://betikler/oyuncu.gd")
const KAMERA := preload("res://betikler/kamera.gd")
const NPC := preload("res://betikler/npc.gd")
const HUD := preload("res://betikler/hud.gd")
const HALK_SAYISI := 24
## Gece aynı anda yanan en fazla sokak lambası ışığı (gl_compatibility'de her ışık pahalı)
const YAKIN_LAMBA := 8
## Memurun cüzdanının düşebileceği yerler (bakkalın arkasındaki park; havuz ve bankların dışında)
const CUZDAN_YERLERI := [Vector3(-42, 0, -30), Vector3(-18, 0, -44), Vector3(-37, 0, -47), Vector3(-21, 0, -31), Vector3(-45, 0, -41), Vector3(-26, 0, -42)]
## Yağmur damlası sayısı (CPU parçacık; telefon için sınırlı)
const DAMLA_SAYISI := 450

var gunes: DirectionalLight3D
var ortam: Environment
var oyuncu
var kamera
var hud
var bilgi: Dictionary
var aktif_bolgeler: Array = []
var _lambalar_acik := false
var _lamba_sayac := 0.0
var _yagmur: CPUParticles3D
var _simsek := 0.0
var _gok_sayac := 25.0
var _cuzdan: Area3D


func _ready() -> void:
	_ortam_kur()
	bilgi = Dunya.kur(self)

	oyuncu = OYUNCU.new()
	add_child(oyuncu)
	oyuncu.global_position = Oyun.oyuncu_konum if Oyun.konum_kayitli else bilgi["baslangic"]

	kamera = KAMERA.new()
	kamera.hedef = oyuncu
	add_child(kamera)
	kamera.make_current()
	kamera.yerles()

	for i in HALK_SAYISI:
		var n = NPC.new()
		add_child(n)
		n.kur(Dunya.HATLAR, 1000 + i)

	hud = HUD.new()
	hud.oyuncu = oyuncu
	hud.kamera = kamera
	add_child(hud)
	hud.eylem_istendi.connect(_eylem)

	for b in bilgi["bolgeler"]:
		b.body_entered.connect(_bolgeye_girdi.bind(b))
		b.body_exited.connect(_bolgeden_cikti.bind(b))
	for a in bilgi["ic_mekanlar"]:
		a.oyuncu_girdi.connect(_ice_girdi.bind(a))
		a.oyuncu_cikti.connect(_disari_cikti.bind(a))
	Oyun.bayildi.connect(_bayildi)
	_yagmur_kur()
	Oyun.cuzdan_dustu.connect(_cuzdan_koy)
	if Oyun.yan_gorev == "cuzdan":
		_cuzdan_koy()


func _ortam_kur() -> void:
	ortam = Environment.new()
	ortam.background_mode = Environment.BG_COLOR
	ortam.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ortam.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = ortam
	add_child(we)
	gunes = DirectionalLight3D.new()
	gunes.shadow_enabled = true
	gunes.directional_shadow_max_distance = 60.0
	add_child(gunes)


func _process(delta: float) -> void:
	var s := Oyun.dakika / 60.0
	var t := (s - 6.0) / 12.0
	var yukseklik := sin(t * PI)
	var gunduz := clampf(yukseklik * 3.0 + 0.3, 0.0, 1.0)
	var gun_batimi := clampf(1.0 - absf(yukseklik) * 4.0, 0.0, 1.0)
	gunes.rotation_degrees = Vector3(-10.0 - maxf(yukseklik, 0.05) * 60.0, lerpf(70.0, -70.0, clampf(t, 0.0, 1.0)), 0.0)
	gunes.light_energy = gunduz * 1.1
	gunes.light_color = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.6, 0.35), gun_batimi)
	var gok := Color(0.02, 0.03, 0.08).lerp(Color(0.55, 0.75, 0.95), gunduz)
	ortam.background_color = gok.lerp(Color(0.95, 0.55, 0.3), gun_batimi * 0.5)
	ortam.ambient_light_color = Color(0.35, 0.4, 0.65).lerp(Color.WHITE, gunduz)
	ortam.ambient_light_energy = lerpf(0.35, 0.55, gunduz)
	_hava_uygula(delta, gunduz)
	var gece := gunduz < 0.35
	if gece != _lambalar_acik:
		_lambalar_acik = gece
		for l in bilgi["lambalar"]:
			l.visible = gece
		bilgi["pencere_malzeme"].emission_energy_multiplier = 1.0 if gece else 0.0
		bilgi["lamba_bas_malzeme"].emission_energy_multiplier = 2.0 if gece else 0.0
		_lambalari_guncelle()
	_lamba_sayac += delta
	if _lambalar_acik and _lamba_sayac > 0.5:
		_lamba_sayac = 0.0
		_lambalari_guncelle()
	Oyun.oyuncu_konum = oyuncu.global_position


## Sadece oyuncuya en yakın YAKIN_LAMBA sokak lambasının ışığını açar; gündüz hepsi kapalı.
func _lambalari_guncelle() -> void:
	var p: Vector3 = oyuncu.global_position
	var sirali: Array = bilgi["sokak_lambalari"].duplicate()
	if _lambalar_acik:
		sirali.sort_custom(func(a, b) -> bool:
			return a.global_position.distance_squared_to(p) < b.global_position.distance_squared_to(p))
	for i in sirali.size():
		sirali[i].visible = _lambalar_acik and i < YAKIN_LAMBA


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_E:
		_eylem()


func _ice_girdi(a) -> void:
	kamera.ic_mekan += 1
	Ses.ic_mekan += 1
	Ses.ic_yer = String(a.ad).to_lower()
	var kapi: Vector3 = a.global_position
	Ses.cal("kapi", kapi)
	if a.ad == "BAKKAL":
		Ses.cal("bakkal_zili", kapi, 0.0)
	elif a.ad == "HASTANE":
		Ses.replik("hemsire_ayse", kapi + Vector3(1.2, 1.5, -3.0))
	elif a.ad == "KAHVEHANE" and Oyun.hava == "yagmur":
		Ses.soz("kahveci_riza_yagmur", 0.8)
		Oyun.mesaj.emit("Rıza Usta: \"Gel evlat, otur şöyle. Yağmur dinene kadar bir çay içeriz.\"")


func _disari_cikti(a) -> void:
	kamera.ic_mekan = maxi(0, kamera.ic_mekan - 1)
	Ses.ic_mekan = maxi(0, Ses.ic_mekan - 1)
	if Ses.ic_mekan == 0:
		Ses.ic_yer = ""
	Ses.cal("kapi", a.global_position)


func _bolgeye_girdi(body: Node3D, b) -> void:
	if body == oyuncu:
		aktif_bolgeler.append(b)
		Ses.replik(b.kisi, b.global_position)
		hud.eylem_goster(b.eylem, Oyun.eylem_metni(b.eylem, b.metin), b.kisi, b.kisi_ad)


func _bolgeden_cikti(body: Node3D, b) -> void:
	if body == oyuncu:
		aktif_bolgeler.erase(b)
		if aktif_bolgeler.is_empty():
			hud.eylem_gizle()
		else:
			var son = aktif_bolgeler.back()
			hud.eylem_goster(son.eylem, Oyun.eylem_metni(son.eylem, son.metin), son.kisi, son.kisi_ad)


func _eylem() -> void:
	if aktif_bolgeler.is_empty() or Oyun.duraklat:
		return
	var b = aktif_bolgeler.back()
	if Oyun.eylem(b.eylem):
		hud.karart()
	# ücret/unvan değişmiş olabilir (terfi): düğme yazısını yenile
	if not aktif_bolgeler.is_empty():
		var son = aktif_bolgeler.back()
		hud.eylem_goster(son.eylem, Oyun.eylem_metni(son.eylem, son.metin), son.kisi, son.kisi_ad)


func _bayildi() -> void:
	hud.karart()
	oyuncu.global_position = bilgi["ev_yatak"]


# --- hava durumu: yağmur damlaları, kapalı gök, sis, şimşek

func _yagmur_kur() -> void:
	_yagmur = CPUParticles3D.new()
	_yagmur.amount = DAMLA_SAYISI
	_yagmur.lifetime = 0.8
	_yagmur.emitting = false
	_yagmur.local_coords = false
	_yagmur.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_yagmur.emission_box_extents = Vector3(18, 0.5, 14)
	_yagmur.direction = Vector3(0.08, -1, 0.04)
	_yagmur.spread = 2.0
	_yagmur.gravity = Vector3(0, -9.8, 0)
	_yagmur.initial_velocity_min = 16.0
	_yagmur.initial_velocity_max = 20.0
	var damla := QuadMesh.new()
	damla.size = Vector2(0.025, 0.55)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.78, 0.84, 0.95, 0.45)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	damla.material = m
	_yagmur.mesh = damla
	_yagmur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_yagmur)


## Yağış şiddetine (Oyun.yagis) göre gök kararır, güneş zayıflar, hafif sis çöker; ara ara şimşek çakar.
func _hava_uygula(delta: float, gunduz: float) -> void:
	var y: float = Oyun.yagis
	_yagmur.global_position = oyuncu.global_position + Vector3(0, 13, -2)
	# iç mekânda damlalar çatıdan görünmesin
	var yagsin := y > 0.25 and Ses.ic_mekan == 0
	if _yagmur.emitting != yagsin:
		_yagmur.emitting = yagsin
	if y <= 0.001:
		if ortam.fog_enabled:
			ortam.fog_enabled = false
		return
	var gri := Color(0.42, 0.45, 0.5) * lerpf(0.15, 1.0, gunduz)
	ortam.background_color = ortam.background_color.lerp(gri, y * 0.85)
	gunes.light_energy *= lerpf(1.0, 0.4, y)
	ortam.ambient_light_color = ortam.ambient_light_color.lerp(Color(0.6, 0.65, 0.75), y * 0.5)
	ortam.fog_enabled = true
	ortam.fog_light_color = gri
	ortam.fog_density = 0.012 * y
	# şimşek ve gök gürültüsü (sadece sağanak sürerken)
	if Oyun.hava == "yagmur" and not Oyun.duraklat:
		_gok_sayac -= delta
		if _gok_sayac <= 0.0:
			_gok_sayac = randf_range(18.0, 45.0)
			_simsek = 0.35
			Ses.cal("gok_gurultusu", null, 0.12, -6.0 if Ses.ic_mekan > 0 else 0.0)
	if _simsek > 0.0:
		_simsek -= delta
		var parlama := clampf(_simsek / 0.35, 0.0, 1.0) * (0.6 if fmod(_simsek, 0.12) > 0.06 else 1.0)
		ortam.background_color = ortam.background_color.lerp(Color(0.85, 0.88, 1.0), parlama * 0.7)
		ortam.ambient_light_energy += parlama * 0.8


# --- memurun kayıp cüzdanı (yan görev)

func _cuzdan_koy() -> void:
	if is_instance_valid(_cuzdan):
		return
	_cuzdan = Area3D.new()
	_cuzdan.collision_layer = 0
	_cuzdan.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.0
	cs.shape = sh
	_cuzdan.add_child(cs)
	var doku: Texture2D = HUD.gorsel("ikon_cuzdan")
	if doku:
		var sp := Sprite3D.new()
		sp.texture = doku
		sp.pixel_size = 0.7 / maxf(doku.get_width(), 1.0)
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.position.y = 0.45
		sp.name = "Gorsel"
		_cuzdan.add_child(sp)
	else:
		var kutu := Dunya.kutu(_cuzdan, Vector3(0.35, 0.08, 0.25), Vector3(0, 0.3, 0), Dunya.malzeme(Color(0.4, 0.25, 0.12)), false)
		kutu.name = "Gorsel"
	# yerde parlayan halka: uzaktan görünsün
	var halka := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.7
	cm.bottom_radius = 0.7
	cm.height = 0.02
	halka.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 1.0, 0.5, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halka.material_override = m
	halka.position.y = 0.06
	_cuzdan.add_child(halka)
	_cuzdan.position = CUZDAN_YERLERI[randi() % CUZDAN_YERLERI.size()]
	add_child(_cuzdan)
	_cuzdan.body_entered.connect(func(body: Node3D) -> void:
		if body == oyuncu:
			Oyun.cuzdan_bul()
			_cuzdan.queue_free())
	# hafifçe zıplayan görsel
	var g: Node3D = _cuzdan.get_node("Gorsel")
	var tw := g.create_tween().set_loops()
	tw.tween_property(g, "position:y", g.position.y + 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(g, "position:y", g.position.y, 0.6).set_trans(Tween.TRANS_SINE)
