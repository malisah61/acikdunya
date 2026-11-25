extends Node
## Oyunun ortak durumu (autoload "Oyun"): saat, ihtiyaçlar, para, karakter, kayıt.

signal mesaj(metin: String)
signal bayildi
signal karakter_degisti

const KAYIT_YOLU := "user://kayit.json"
## 1 gerçek saniye = kaç oyun dakikası (24 dakikada bir gün)
const SANIYE_BASINA_DAKIKA := 1.0

const TEN_RENKLERI := [Color(1.0, 0.87, 0.74), Color(0.94, 0.76, 0.6), Color(0.8, 0.6, 0.43), Color(0.6, 0.42, 0.28), Color(0.4, 0.27, 0.18)]
const SAC_RENKLERI := [Color(0.08, 0.06, 0.05), Color(0.3, 0.18, 0.1), Color(0.55, 0.35, 0.18), Color(0.85, 0.7, 0.4), Color(0.62, 0.62, 0.62)]
const GOMLEK_RENKLERI := [Color(0.2, 0.4, 0.75), Color(0.88, 0.88, 0.88), Color(0.7, 0.15, 0.15), Color(0.2, 0.55, 0.3), Color(0.15, 0.15, 0.18), Color(0.9, 0.6, 0.15)]
const PANTOLON_RENKLERI := [Color(0.15, 0.2, 0.35), Color(0.12, 0.12, 0.12), Color(0.45, 0.38, 0.28), Color(0.35, 0.35, 0.38)]
const SAC_MODELLERI := ["Kısa", "Uzun", "Kel"]

var gun := 1
var dakika := 8.0 * 60.0
var para := 250
var tokluk := 80.0
var enerji := 90.0
var karakter := {"isim": "Mehmet Ali", "ten": 1, "sac": 0, "sac_model": 0, "gomlek": 0, "pantolon": 0, "sakal": false}
var karakter_hazir := false
var oyuncu_konum := Vector3.ZERO
var konum_kayitli := false
## Karakter ekranı açıkken saat ve hareket durur
var duraklat := false
var _kayit_sayaci := 0.0


func _ready() -> void:
	yukle()


func _process(delta: float) -> void:
	if duraklat:
		return
	ilerle(delta * SANIYE_BASINA_DAKIKA)
	_kayit_sayaci += delta
	if _kayit_sayaci >= 60.0:
		_kayit_sayaci = 0.0
		kaydet()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		kaydet()


func renk(dizi: Array, i) -> Color:
	return dizi[posmod(int(i), dizi.size())]


func _saat_ekle(dk: float) -> void:
	dakika += dk
	while dakika >= 1440.0:
		dakika -= 1440.0
		gun += 1


## Zamanı ilerletir ve ihtiyaçları buna göre düşürür.
func ilerle(dk: float, uyku := false) -> void:
	_saat_ekle(dk)
	var acikma := dk * 100.0 / 1800.0   # tam toktan ~30 oyun saatinde acıkır
	if uyku:
		acikma *= 0.5
	tokluk = clampf(tokluk - acikma, 0.0, 100.0)
	if not uyku:
		var yorulma := dk * 100.0 / 1080.0   # ~18 saat uyanık kalınabilir
		if tokluk <= 0.0:
			yorulma *= 2.0
		enerji = clampf(enerji - yorulma, 0.0, 100.0)
		if enerji <= 0.0:
			_bayil()


func _bayil() -> void:
	enerji = 40.0
	para = maxi(0, para - 100)
	_saat_ekle(180.0)
	bayildi.emit()
	mesaj.emit("Yorgunluktan bayıldın! Komşular seni eve taşıdı. (-100 TL ilaç)")


func saat_metni() -> String:
	var d := int(dakika)
	return "Gün %d   %02d:%02d" % [gun, d / 60, d % 60]


func gece_mi() -> bool:
	return dakika < 7.0 * 60.0 or dakika > 22.0 * 60.0


## Bir etkileşim bölgesindeki eylemi uygular. Zaman atlandıysa true döner (ekran kararır).
func eylem(ad: String) -> bool:
	match ad:
		"uyu":
			if enerji > 85.0:
				mesaj.emit("Henüz uykun yok.")
				return false
			var dk := 7.0 * 60.0 - dakika
			if dk <= 0.0:
				dk += 1440.0
			ilerle(dk, true)
			enerji = 100.0
			mesaj.emit("Güzel bir uyku çektin. Günaydın!")
			kaydet()
			return true
		"simit":
			if para < 25:
				mesaj.emit("Paran yetmiyor! Hastanede nöbet tutarak para kazanabilirsin.")
				return false
			para -= 25
			tokluk = minf(tokluk + 35.0, 100.0)
			ilerle(10.0)
			mesaj.emit("Simit ve ayran aldın. Afiyet olsun! (-25 TL)")
			return false
		"cay":
			if para < 10:
				mesaj.emit("Çaya bile paran yok!")
				return false
			para -= 10
			enerji = minf(enerji + 12.0, 100.0)
			ilerle(20.0)
			mesaj.emit("Bir çay içtin, açıldın. (-10 TL)")
			return false
		"nobet":
			if enerji < 50.0:
				mesaj.emit("Nöbete girmek için çok yorgunsun. Önce dinlen.")
				return false
			ilerle(8.0 * 60.0)
			para += 400
			mesaj.emit("Nöbet bitti! 8 saat çalıştın. (+400 TL)")
			kaydet()
			return true
	return false


func kaydet() -> void:
	var veri := {
		"gun": gun, "dakika": dakika, "para": para, "tokluk": tokluk, "enerji": enerji,
		"karakter": karakter, "karakter_hazir": karakter_hazir,
		"konum": [oyuncu_konum.x, oyuncu_konum.y, oyuncu_konum.z],
	}
	var f := FileAccess.open(KAYIT_YOLU, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(veri))


func yukle() -> void:
	if not FileAccess.file_exists(KAYIT_YOLU):
		return
	var f := FileAccess.open(KAYIT_YOLU, FileAccess.READ)
	if f == null:
		return
	var v = JSON.parse_string(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY:
		return
	gun = int(v.get("gun", 1))
	dakika = float(v.get("dakika", 480.0))
	para = int(v.get("para", 250))
	tokluk = float(v.get("tokluk", 80.0))
	enerji = float(v.get("enerji", 90.0))
	karakter_hazir = bool(v.get("karakter_hazir", false))
	var k = v.get("karakter", {})
	if typeof(k) == TYPE_DICTIONARY:
		for a in k:
			if a == "isim":
				karakter[a] = str(k[a])
			elif a == "sakal":
				karakter[a] = bool(k[a])
			else:
				karakter[a] = int(k[a])
	var p = v.get("konum", null)
	if p is Array and p.size() == 3:
		oyuncu_konum = Vector3(float(p[0]), float(p[1]), float(p[2]))
		konum_kayitli = true
