extends Node
## Ses yöneticisi (autoload "Ses"): efektler, NPC replikleri, ortam sesi ve müzik.
## Dosyalar assets/ses/<tur>/<ad>.ogg; dosya yoksa sessizce geçer (hiçbir ses zorunlu değil).

const KOK := "res://assets/ses/"
const AYAR_YOLU := "user://ayarlar.json"
## Aynı anda çalabilecek en fazla efekt (telefon performansı)
const EN_FAZLA_EFEKT := 6
const EN_FAZLA_KONUMLU := 6
## Aynı kişi en fazla bu kadar saniyede bir konuşur
const REPLIK_ARA := 25.0

var efekt_duzey := 0.8
var muzik_duzey := 0.6
## İçinde bulunulan bina sayısı (ana sahne günceller)
var ic_mekan := 0

var _onbellek := {}
var _efektler: Array[AudioStreamPlayer] = []
var _konumlular: Array[AudioStreamPlayer3D] = []
var _replik: AudioStreamPlayer3D
var _replik_son := {}
## ortam/müzik katmanları: ad -> {oyuncu, hedef}
var _katmanlar := {}
var _sira := 0
var _sira3 := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ayar_yukle()
	for ad in ["Efekt", "Ortam", "Muzik"]:
		if AudioServer.get_bus_index(ad) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, ad)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in EN_FAZLA_EFEKT:
		var p := AudioStreamPlayer.new()
		p.bus = "Efekt"
		add_child(p)
		_efektler.append(p)
	for i in EN_FAZLA_KONUMLU:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "Efekt"
		p3.unit_size = 6.0
		p3.max_distance = 40.0
		add_child(p3)
		_konumlular.append(p3)
	_replik = AudioStreamPlayer3D.new()
	_replik.bus = "Efekt"
	_replik.unit_size = 8.0
	_replik.max_distance = 30.0
	add_child(_replik)
	for ad in ["ortam/mahalle_gunduz", "ortam/gece", "ortam/kahvehane", "ortam/hastane", "muzik/mahalle", "muzik/gece"]:
		var s := _yukle(ad)
		if s == null:
			continue
		if "loop" in s:
			s.set("loop", true)
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = "Muzik" if ad.begins_with("muzik") else "Ortam"
		p.volume_db = -80.0
		add_child(p)
		_katmanlar[ad] = {"oyuncu": p, "hedef": 0.0, "duzey": 0.0}
	_duzeyleri_uygula()


func _yukle(ad: String) -> AudioStream:
	if _onbellek.has(ad):
		return _onbellek[ad]
	var yol := KOK + ad + ".ogg"
	var s: AudioStream = null
	if ResourceLoader.exists(yol):
		s = load(yol) as AudioStream
	_onbellek[ad] = s
	return s


## Efekt çalar. konum verilirse 3D (uzaklaştıkça kısılır). perde: rastgele perde oynaması.
func cal(ad: String, konum = null, perde := 0.05, db := 0.0) -> void:
	var s := _yukle("efekt/" + ad)
	if s == null:
		return
	if konum is Vector3:
		var p3: AudioStreamPlayer3D = _konumlular[_sira3]
		_sira3 = (_sira3 + 1) % _konumlular.size()
		p3.stream = s
		p3.global_position = konum
		p3.pitch_scale = randf_range(1.0 - perde, 1.0 + perde)
		p3.volume_db = db
		p3.play()
		return
	var p: AudioStreamPlayer = _efektler[_sira]
	_sira = (_sira + 1) % _efektler.size()
	p.stream = s
	p.pitch_scale = randf_range(1.0 - perde, 1.0 + perde)
	p.volume_db = db
	p.play()


## Zemine göre adım sesi: "asfalt", "cim", "ev".
func adim(zemin: String, konum: Vector3, kosuyor := false) -> void:
	cal("adim_" + zemin, konum, 0.12, -4.0 if kosuyor else -8.0)


## Kişinin selam repliği (assets/ses/replik/<kisi>_selam.ogg). Sık tekrarlamaz.
func replik(kisi: String, konum: Vector3) -> void:
	if kisi == "":
		return
	var simdi := Time.get_ticks_msec() / 1000.0
	if simdi - float(_replik_son.get(kisi, -999.0)) < REPLIK_ARA:
		return
	var s := _yukle("replik/" + kisi + "_selam")
	if s == null:
		return
	_replik_son[kisi] = simdi
	_replik.stream = s
	_replik.global_position = konum
	_replik.play()


func _process(delta: float) -> void:
	if _katmanlar.is_empty():
		return
	var d: float = Oyun.dakika
	var gece := d < 6.0 * 60.0 or d > 21.0 * 60.0
	var icerde := ic_mekan > 0
	for ad in _katmanlar:
		_katmanlar[ad]["hedef"] = 0.0
	# dışarıdaki ortam içeride de kısık duyulur
	var dis := 0.35 if icerde else 1.0
	_hedef("ortam/gece" if gece else "ortam/mahalle_gunduz", dis)
	_hedef("muzik/gece" if gece else "muzik/mahalle", 0.7)
	for ad in _katmanlar:
		var k: Dictionary = _katmanlar[ad]
		k["duzey"] = move_toward(float(k["duzey"]), float(k["hedef"]), delta * 0.4)
		var p: AudioStreamPlayer = k["oyuncu"]
		if k["duzey"] <= 0.001:
			if p.playing:
				p.stop()
			continue
		if not p.playing:
			p.play(randf() * maxf(p.stream.get_length() - 1.0, 0.0))
		p.volume_db = linear_to_db(float(k["duzey"]))


func _hedef(ad: String, duzey: float) -> void:
	if _katmanlar.has(ad):
		_katmanlar[ad]["hedef"] = duzey


func duzey_ayarla(efekt: float, muzik: float) -> void:
	efekt_duzey = clampf(efekt, 0.0, 1.0)
	muzik_duzey = clampf(muzik, 0.0, 1.0)
	_duzeyleri_uygula()
	var f := FileAccess.open(AYAR_YOLU, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"efekt": efekt_duzey, "muzik": muzik_duzey}))


func _duzeyleri_uygula() -> void:
	var e := AudioServer.get_bus_index("Efekt")
	var o := AudioServer.get_bus_index("Ortam")
	var m := AudioServer.get_bus_index("Muzik")
	if e >= 0:
		AudioServer.set_bus_volume_db(e, linear_to_db(maxf(efekt_duzey, 0.0001)))
	if o >= 0:
		AudioServer.set_bus_volume_db(o, linear_to_db(maxf(muzik_duzey, 0.0001)))
	if m >= 0:
		AudioServer.set_bus_volume_db(m, linear_to_db(maxf(muzik_duzey * 0.8, 0.0001)))


func _ayar_yukle() -> void:
	if not FileAccess.file_exists(AYAR_YOLU):
		return
	var f := FileAccess.open(AYAR_YOLU, FileAccess.READ)
	if f == null:
		return
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) == TYPE_DICTIONARY:
		efekt_duzey = clampf(float(v.get("efekt", 0.8)), 0.0, 1.0)
		muzik_duzey = clampf(float(v.get("muzik", 0.6)), 0.0, 1.0)
