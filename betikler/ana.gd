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

var gunes: DirectionalLight3D
var ortam: Environment
var oyuncu
var kamera
var hud
var bilgi: Dictionary
var aktif_bolgeler: Array = []
var _lambalar_acik := false
var _lamba_sayac := 0.0


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
		a.oyuncu_girdi.connect(func() -> void: kamera.ic_mekan += 1)
		a.oyuncu_cikti.connect(func() -> void: kamera.ic_mekan = maxi(0, kamera.ic_mekan - 1))
	Oyun.bayildi.connect(_bayildi)


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


func _bolgeye_girdi(body: Node3D, b) -> void:
	if body == oyuncu:
		aktif_bolgeler.append(b)
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
