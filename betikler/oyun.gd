extends Node
## Oyunun ortak durumu (autoload "Oyun"): saat, ihtiyaçlar, para, karakter, kayıt.

signal mesaj(metin: String)
signal bayildi
signal karakter_degisti
## Hava değişti: "acik" ya da "yagmur"
signal hava_degisti(hava: String)
## Memur cüzdanını parkta düşürdü: ana sahne cüzdanı parka koyar
signal cuzdan_dustu

const KAYIT_YOLU := "user://kayit.json"
## 1 gerçek saniye = kaç oyun dakikası (24 dakikada bir gün)
const SANIYE_BASINA_DAKIKA := 1.0

const TEN_RENKLERI := [Color(1.0, 0.87, 0.74), Color(0.94, 0.76, 0.6), Color(0.8, 0.6, 0.43), Color(0.6, 0.42, 0.28), Color(0.4, 0.27, 0.18)]
const SAC_RENKLERI := [Color(0.08, 0.06, 0.05), Color(0.3, 0.18, 0.1), Color(0.55, 0.35, 0.18), Color(0.85, 0.7, 0.4), Color(0.62, 0.62, 0.62)]
const GOMLEK_RENKLERI := [Color(0.2, 0.4, 0.75), Color(0.88, 0.88, 0.88), Color(0.7, 0.15, 0.15), Color(0.2, 0.55, 0.3), Color(0.15, 0.15, 0.18), Color(0.9, 0.6, 0.15)]
const PANTOLON_RENKLERI := [Color(0.15, 0.2, 0.35), Color(0.12, 0.12, 0.12), Color(0.45, 0.38, 0.28), Color(0.35, 0.35, 0.38)]
const SAC_MODELLERI := ["Kısa", "Uzun", "Kel"]
## Meslekler ve kariyer basamakları: [unvan, gereken iş sayısı, iş başı ücret TL]
const MESLEKLER := {
	"nobet": {"ad": "Hastane", "is": "Nöbete gir", "bitti": "Nöbet", "saat": 8, "enerji": 50,
		"basamak": [["Stajyer", 0, 400], ["Hemşire", 3, 480], ["Asistan Doktor", 8, 600], ["Uzman Doktor", 15, 800]]},
	"bakkal_is": {"ad": "Bakkal", "is": "Rafları diz", "bitti": "Mesai", "saat": 4, "enerji": 30,
		"basamak": [["Çırak", 0, 150], ["Tezgâhtar", 4, 200], ["Kalfa", 10, 260]]},
	"garson": {"ad": "Kahvehane", "is": "Garsonluk yap", "bitti": "Mesai", "saat": 3, "enerji": 25,
		"basamak": [["Çaycı Çırağı", 0, 110], ["Garson", 4, 150], ["Ocakbaşı Ustası", 10, 200]]},
}

## Esnafla dostluk: her alışveriş/mesai +1 puan. [ad, gereken puan]
const DOSTLUK_SEVIYELERI := [["Tanıdık", 0], ["Ahbap", 5], ["Dost", 15]]
const ESNAF := {"bakkal_hasan": "Bakkal Hasan Amca", "kahveci_riza": "Kahveci Rıza Usta", "doktor_selin": "Dr. Selin"}
## Hangi eylem hangi esnafla yapılır
const EYLEM_ESNAF := {"simit": "bakkal_hasan", "bakkal_is": "bakkal_hasan", "cay": "kahveci_riza", "garson": "kahveci_riza", "nobet": "doktor_selin"}
## Günlük görev havuzu: her yeni gün 3 tanesi seçilir (Stardew'deki ilan panosu gibi)
const GOREV_HAVUZU := [
	{"id": "simit", "ad": "Bakkaldan simit al", "hedef": 2, "odul": 30},
	{"id": "cay", "ad": "Kahvehanede çay iç", "hedef": 2, "odul": 30},
	{"id": "mesai", "ad": "Bir işte mesai ya da nöbet tamamla", "hedef": 1, "odul": 60},
	{"id": "selam", "ad": "Komşularla selamlaş", "hedef": 5, "odul": 40},
	{"id": "teyze", "ad": "Bir teyzeyle laflaş", "hedef": 1, "odul": 30},
	{"id": "bakkal_is", "ad": "Bakkalda rafları diz", "hedef": 1, "odul": 50},
]
const GOREV_HEPSI_ODUL := 50
## Mahalledeki itibar (komşuluk puanı) basamakları
const ITIBAR_SEVIYELERI := [["Yeni gelen", 0], ["Bilinen yüz", 5], ["Sevilen komşu", 15], ["Mahallenin gözdesi", 30]]

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
## Her meslekte tamamlanan iş sayısı (kariyer basamağını belirler)
var is_sayilari := {"nobet": 0, "bakkal_is": 0, "garson": 0}
var dostluk := {"bakkal_hasan": 0, "kahveci_riza": 0, "doktor_selin": 0}
## Bugünün görevleri: [{id, ad, hedef, n, odul}] ve hangi güne ait oldukları
var gorevler: Array = []
var gorev_gunu := 0
## Yan görev durumu: "" yok; "ekmek"/"ekmek_alindi" (teyzenin ekmeği),
## "cuzdan"/"cuzdan_bulundu" (memurun kayıp cüzdanı), "yemek"/"yemek_alindi" (işçinin yemeği)
var yan_gorev := ""
## Hava durumu: "acik" ya da "yagmur"; yagmur_bitis = yağmurun biteceği mutlak oyun dakikası
var hava := "acik"
var yagmur_bitis := 0.0
## Yağış şiddeti 0..1 (yumuşak geçiş; görüntü ve ses bunu kullanır)
var yagis := 0.0
var _hava_saati := -1
var komsuluk := 0
var _ac_uyarildi := false
var _yorgun_uyarildi := false


func _ready() -> void:
	yukle()
	if gorev_gunu != gun or gorevler.is_empty():
		_gunluk_yenile()
	# duman testi için: godot -- --yagmur --cuzdan (yağmuru ve cüzdan görevini hemen başlatır)
	var argumanlar := OS.get_cmdline_user_args()
	if "--yagmur" in argumanlar:
		hava = "yagmur"
		yagmur_bitis = mutlak_dakika() + 120.0
		yagis = 1.0
	if "--cuzdan" in argumanlar:
		yan_gorev = "cuzdan"


func _process(delta: float) -> void:
	if duraklat:
		return
	ilerle(delta * SANIYE_BASINA_DAKIKA)
	yagis = move_toward(yagis, 1.0 if hava == "yagmur" else 0.0, delta * 0.15)
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
	if gorev_gunu != gun:
		_gunluk_yenile()
	_hava_guncelle()


func mutlak_dakika() -> float:
	return gun * 1440.0 + dakika


## Her oyun saatinde bir: açık havada %10 yağmur başlar (1-3 saat sürer); süre dolunca açar.
func _hava_guncelle() -> void:
	var saat := int(mutlak_dakika() / 60.0)
	if saat == _hava_saati:
		return
	var ilk := _hava_saati < 0
	_hava_saati = saat
	if ilk:
		return
	if hava == "yagmur" and mutlak_dakika() >= yagmur_bitis:
		hava = "acik"
		hava_degisti.emit(hava)
		mesaj.emit("Yağmur dindi, hava açtı.")
	elif hava == "acik" and randf() < 0.10:
		hava = "yagmur"
		yagmur_bitis = mutlak_dakika() + randf_range(60.0, 180.0)
		hava_degisti.emit(hava)
		mesaj.emit("Yağmur başladı! Sakinler şemsiyelerini açtı. Kahvehanede bir çay iyi gider.")


func yagmurda_disarida() -> bool:
	return hava == "yagmur" and Ses.ic_mekan == 0


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
		if yagmurda_disarida():
			yorulma *= 1.3   # ıslanınca daha çabuk yorulursun
		enerji = clampf(enerji - yorulma, 0.0, 100.0)
		if enerji <= 0.0:
			_bayil()
	_uyar()


## İhtiyaç azalınca bir kere uyarır; toparlanınca uyarı yeniden kurulur.
func _uyar() -> void:
	if tokluk < 20.0 and not _ac_uyarildi:
		_ac_uyarildi = true
		mesaj.emit("Karnın acıktı! Bakkaldan simit alabilirsin.")
	elif tokluk > 30.0:
		_ac_uyarildi = false
	if enerji < 15.0 and not _yorgun_uyarildi:
		_yorgun_uyarildi = true
		mesaj.emit("Çok yorgunsun! Eve gidip uyu ya da kahvehanede çay iç.")
	elif enerji > 25.0:
		_yorgun_uyarildi = false


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
			Ses.cal("uyuma", null, 0.0, -3.0)
			mesaj.emit("Güzel bir uyku çektin. Günaydın!")
			kaydet()
			return true
		"simit":
			var f := fiyat("simit")
			if para < f:
				mesaj.emit("Paran yetmiyor! Hastanede nöbet tutarak para kazanabilirsin.")
				return false
			para -= f
			tokluk = minf(tokluk + 35.0, 100.0)
			ilerle(10.0)
			Ses.cal("kasa_para")
			Ses.cal("yeme", null, 0.05, -2.0)
			var ek := ""
			if yan_gorev == "ekmek" and para >= 5:
				para -= 5
				yan_gorev = "ekmek_alindi"
				ek = "\nTeyze için bir ekmek de aldın (-5 TL). Şimdi ona götür!"
			elif yan_gorev == "yemek" and para >= f:
				para -= f
				yan_gorev = "yemek_alindi"
				ek = "\nİşçi usta için de bir simit + ayran aldın (-%d TL). Şimdi ona götür!" % f
			mesaj.emit("Simit ve ayran aldın. Afiyet olsun! (-%d TL)%s%s%s" % [f, _dost_artir("bakkal_hasan"), ek, gorev_ilerle("simit")])
			return false
		"cay":
			var f := fiyat("cay")
			if para < f:
				mesaj.emit("Çaya bile paran yok!")
				return false
			para -= f
			enerji = minf(enerji + 12.0, 100.0)
			ilerle(20.0)
			Ses.cal("cay_kasik")
			mesaj.emit("Bir çay içtin, açıldın. (-%d TL)%s%s" % [f, _dost_artir("kahveci_riza"), gorev_ilerle("cay")])
			return false
		"nobet", "bakkal_is", "garson":
			return _calis(ad)
	return false


## Meslekteki mevcut kariyer basamağının sırası.
func basamak(meslek: String) -> int:
	var b: Array = MESLEKLER[meslek]["basamak"]
	var n := int(is_sayilari.get(meslek, 0))
	var i := 0
	for k in b.size():
		if n >= int(b[k][1]):
			i = k
	return i


func _calis(meslek: String) -> bool:
	var m: Dictionary = MESLEKLER[meslek]
	if enerji < float(m["enerji"]):
		mesaj.emit("İşe girmek için çok yorgunsun. Önce dinlen.")
		return false
	var b: Array = m["basamak"]
	var once := basamak(meslek)
	var ucret := int(b[once][2])
	var esnaf: String = EYLEM_ESNAF.get(meslek, "")
	var bahsis := 0
	if dostluk_seviye(esnaf) >= 2:
		bahsis = int(ucret * 0.1)
	ucret += bahsis
	var saat := int(m["saat"])
	ilerle(saat * 60.0)
	para += ucret
	is_sayilari[meslek] = int(is_sayilari.get(meslek, 0)) + 1
	var sonra := basamak(meslek)
	Ses.cal("kasa_para")
	var metin: String = "%s bitti! %d saat çalıştın. (+%d TL)" % [m["bitti"], saat, ucret]
	if bahsis > 0:
		metin += "\n%s dostun olduğu için %d TL fazladan verdi." % [ESNAF[esnaf], bahsis]
	metin += _dost_artir(esnaf)
	if sonra > once:
		metin += "\nTERFİ! Yeni unvanın: %s (iş başı %d TL)" % [b[sonra][0], int(b[sonra][2])]
	metin += gorev_ilerle("mesai") + gorev_ilerle(meslek)
	# işveren konuşur: terfide Dr. Selin tebrik eder, esnaf mesai sonunda teşekkür eder (dosya yoksa sessiz)
	if sonra > once:
		Ses.cal("terfi", null, 0.0, -2.0)
	if sonra > once and esnaf == "doktor_selin":
		Ses.soz("doktor_selin_terfi", 1.6)
	elif esnaf != "doktor_selin":
		Ses.soz(esnaf + "_tesekkur")
	mesaj.emit(metin)
	kaydet()
	return true


## Esnafla dostluk seviyesi: 0 Tanıdık, 1 Ahbap, 2 Dost.
func dostluk_seviye(kisi: String) -> int:
	var n := int(dostluk.get(kisi, 0))
	var i := 0
	for k in DOSTLUK_SEVIYELERI.size():
		if n >= int(DOSTLUK_SEVIYELERI[k][1]):
			i = k
	return i


## Dostluk puanını artırır; seviye atladıysa mesaja eklenecek satırı döndürür.
func _dost_artir(kisi: String) -> String:
	if not dostluk.has(kisi):
		return ""
	var once := dostluk_seviye(kisi)
	dostluk[kisi] = int(dostluk[kisi]) + 1
	var sonra := dostluk_seviye(kisi)
	if sonra > once:
		var ek := ""
		if kisi == "bakkal_hasan":
			ek = " Simit artık daha ucuz!" if sonra == 1 else " İşte bahşiş de verecek."
		elif kisi == "kahveci_riza":
			ek = " Çay artık daha ucuz!" if sonra == 1 else " İşte bahşiş de verecek."
		elif sonra == 2:
			ek = " Nöbette fazladan ödeme yapacak."
		return "\n%s ile artık %s oldunuz!%s" % [ESNAF[kisi], DOSTLUK_SEVIYELERI[sonra][0].to_lower(), ek]
	return ""


## Alışveriş fiyatı (esnafla ahbap olunca indirimli).
func fiyat(ad: String) -> int:
	match ad:
		"simit":
			return 20 if dostluk_seviye("bakkal_hasan") >= 1 else 25
		"cay":
			return 8 if dostluk_seviye("kahveci_riza") >= 1 else 10
	return 0


## Eylem düğmesinin yazısı (meslek eylemlerinde güncel ücret ve unvan).
func eylem_metni(ad: String, varsayilan: String) -> String:
	if ad == "simit":
		return "Simit + ayran al (%d TL)" % fiyat("simit")
	if ad == "cay":
		return "Çay iç (%d TL)" % fiyat("cay")
	if not MESLEKLER.has(ad):
		return varsayilan
	var m: Dictionary = MESLEKLER[ad]
	var b: Array = m["basamak"][basamak(ad)]
	return "%s (%d saat, +%d TL) — %s" % [m["is"], int(m["saat"]), int(b[2]), b[0]]


## Telefon menüsünde görünen özet.
func telefon_metni() -> String:
	var s: String = "%s\n%s   •   Para: %d TL\n%s\n\nMESLEKLER\n" % [karakter["isim"], saat_metni(), para, hava_metni()]
	for ad in MESLEKLER:
		var m: Dictionary = MESLEKLER[ad]
		var b: Array = m["basamak"]
		var i := basamak(ad)
		var n := int(is_sayilari.get(ad, 0))
		s += "• %s: %s — iş başı %d TL (%d iş)\n" % [m["ad"], b[i][0], int(b[i][2]), n]
		if i + 1 < b.size():
			s += "     %s olmak için %d iş daha\n" % [b[i + 1][0], int(b[i + 1][1]) - n]
		else:
			s += "     En üst basamaktasın!\n"
	s += "\nDOSTLAR\n"
	for k in ESNAF:
		var n := int(dostluk.get(k, 0))
		var i := dostluk_seviye(k)
		s += "• %s: %s (%d puan)" % [ESNAF[k], DOSTLUK_SEVIYELERI[i][0], n]
		if i + 1 < DOSTLUK_SEVIYELERI.size():
			s += " — %s için %d daha" % [DOSTLUK_SEVIYELERI[i + 1][0], int(DOSTLUK_SEVIYELERI[i + 1][1]) - n]
		s += "\n"
	s += "\nBUGÜNÜN GÖREVLERİ\n"
	for g in gorevler:
		var tamam: bool = int(g["n"]) >= int(g["hedef"])
		s += "%s %s (%d/%d) — %d TL\n" % ["[x]" if tamam else "[ ]", g["ad"], mini(int(g["n"]), int(g["hedef"])), int(g["hedef"]), int(g["odul"])]
	s += "Hepsini bitirirsen +%d TL ödül.\n" % GOREV_HEPSI_ODUL
	if yan_gorev == "ekmek":
		s += "» Yan görev: Teyze için bakkaldan ekmek al (alışverişte).\n"
	elif yan_gorev == "ekmek_alindi":
		s += "» Yan görev: Ekmeği mahalledeki teyzeye götür (yanına git).\n"
	elif yan_gorev == "cuzdan":
		s += "» Yan görev: Memurun cüzdanı parkta (bakkalın arkası, havuzun çevresi). Parlayan cüzdanı bul.\n"
	elif yan_gorev == "cuzdan_bulundu":
		s += "» Yan görev: Cüzdanı bir memura geri ver.\n"
	elif yan_gorev == "yemek":
		s += "» Yan görev: İşçi usta için bakkaldan simit + ayran al (alışverişte).\n"
	elif yan_gorev == "yemek_alindi":
		s += "» Yan görev: Yemeği işçi ustaya götür.\n"
	var it := itibar_seviye()
	s += "Mahallede itibarın: %s (%d puan)\n" % [ITIBAR_SEVIYELERI[it][0], komsuluk]
	s += "\nİPUCU\n"
	if tokluk < 30.0:
		s += "Karnın aç: bakkalda simit + ayran 25 TL."
	elif enerji < 30.0:
		s += "Yorgunsun: evde uyu ya da kahvehanede çay iç."
	elif para < 50:
		s += "Para azaldı: hastanede nöbet, bakkalda ya da kahvehanede mesai."
	elif hava == "yagmur":
		s += "Yağmur yağıyor: dışarıda ıslanınca daha çabuk yorulursun. Kahvehanede çay içip bekle."
	elif gece_mi():
		s += "Gece oldu, sakinler evlerine çekildi. Uyumak için iyi bir saat."
	else:
		s += "Her işte biraz daha çalış, terfi edip daha çok kazan."
	return s


func kaydet() -> void:
	var veri := {
		"gun": gun, "dakika": dakika, "para": para, "tokluk": tokluk, "enerji": enerji,
		"karakter": karakter, "karakter_hazir": karakter_hazir, "is_sayilari": is_sayilari, "dostluk": dostluk,
		"gorevler": gorevler, "gorev_gunu": gorev_gunu, "yan_gorev": yan_gorev, "komsuluk": komsuluk,
		"hava": hava, "yagmur_bitis": yagmur_bitis,
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
	var isler = v.get("is_sayilari", {})
	if typeof(isler) == TYPE_DICTIONARY:
		for a in is_sayilari.keys():
			if isler.has(a):
				is_sayilari[a] = int(isler[a])
	var dost = v.get("dostluk", {})
	if typeof(dost) == TYPE_DICTIONARY:
		for a in dostluk.keys():
			if dost.has(a):
				dostluk[a] = int(dost[a])
	var gv = v.get("gorevler", [])
	if gv is Array:
		gorevler = []
		for g in gv:
			if typeof(g) == TYPE_DICTIONARY and g.has("id"):
				gorevler.append({"id": str(g["id"]), "ad": str(g.get("ad", "")), "hedef": int(g.get("hedef", 1)),
					"n": int(g.get("n", 0)), "odul": int(g.get("odul", 0))})
	gorev_gunu = int(v.get("gorev_gunu", 0))
	yan_gorev = str(v.get("yan_gorev", ""))
	komsuluk = int(v.get("komsuluk", 0))
	hava = "yagmur" if str(v.get("hava", "acik")) == "yagmur" else "acik"
	yagmur_bitis = float(v.get("yagmur_bitis", 0.0))
	yagis = 1.0 if hava == "yagmur" else 0.0
	var p = v.get("konum", null)
	if p is Array and p.size() == 3:
		oyuncu_konum = Vector3(float(p[0]), float(p[1]), float(p[2]))
		konum_kayitli = true


# --- günlük görevler, yan görev, mahalle itibarı

## Yeni günün 3 görevini seçer (aynı gün hep aynı görevler: tohum = gün).
func _gunluk_yenile() -> void:
	gorev_gunu = gun
	var r := RandomNumberGenerator.new()
	r.seed = 7919 * gun + 13
	var havuz: Array = GOREV_HAVUZU.duplicate()
	gorevler = []
	for i in 3:
		var g: Dictionary = havuz.pop_at(r.randi() % havuz.size())
		gorevler.append({"id": g["id"], "ad": g["ad"], "hedef": g["hedef"], "n": 0, "odul": g["odul"]})


## Görevi bir adım ilerletir. Tamamlandıysa ödülü verir ve mesaja eklenecek satırı döndürür.
func gorev_ilerle(id: String) -> String:
	var ek := ""
	for g in gorevler:
		if g["id"] != id or int(g["n"]) >= int(g["hedef"]):
			continue
		g["n"] = int(g["n"]) + 1
		if int(g["n"]) >= int(g["hedef"]):
			para += int(g["odul"])
			Ses.cal("gorev_tamam", null, 0.0, -2.0)
			ek += "\nGörev tamam: %s (+%d TL)" % [g["ad"], int(g["odul"])]
			ek += _itibar_artir(1)
			var hepsi := true
			for h in gorevler:
				if int(h["n"]) < int(h["hedef"]):
					hepsi = false
			if hepsi:
				para += GOREV_HEPSI_ODUL
				ek += "\nBugünün bütün görevlerini bitirdin! (+%d TL)" % GOREV_HEPSI_ODUL
	return ek


func itibar_seviye() -> int:
	var i := 0
	for k in ITIBAR_SEVIYELERI.size():
		if komsuluk >= int(ITIBAR_SEVIYELERI[k][1]):
			i = k
	return i


func _itibar_artir(n: int) -> String:
	var once := itibar_seviye()
	komsuluk += n
	var sonra := itibar_seviye()
	if sonra > once:
		return "\nMahallede artık \"%s\" olarak biliniyorsun!" % ITIBAR_SEVIYELERI[sonra][0]
	return ""


## Sol üst panelde görünen kısa yan görev hatırlatması ("" = yan görev yok).
func yan_gorev_ozet() -> String:
	match yan_gorev:
		"ekmek":
			return "Teyzeye ekmek: bakkaldan al"
		"ekmek_alindi":
			return "Teyzeye ekmeği götür"
		"cuzdan":
			return "Memurun cüzdanı: parkta ara"
		"cuzdan_bulundu":
			return "Cüzdanı memura ver"
		"yemek":
			return "İşçiye yemek: bakkaldan al"
		"yemek_alindi":
			return "Yemeği işçiye götür"
	return ""


func hava_metni() -> String:
	if hava == "yagmur":
		var kalan := maxf(yagmur_bitis - mutlak_dakika(), 0.0)
		return "Hava: Yağmurlu (yaklaşık %d saat daha)" % maxi(1, int(ceil(kalan / 60.0)))
	return "Hava: Açık" if not gece_mi() else "Hava: Açık, yıldızlı gece"


## Oyuncu parktaki cüzdanı buldu (ana sahnedeki cüzdan bölgesi çağırır).
func cuzdan_bul() -> void:
	if yan_gorev != "cuzdan":
		return
	yan_gorev = "cuzdan_bulundu"
	Ses.cal("cuzdan_bul", null, 0.0, -2.0)
	mesaj.emit("Memurun cüzdanını buldun! Şimdi bir memura geri ver.")


## Bir sakin oyuncuyu selamladı (npc.gd). tip: "teyze", "ogrenci", "memur", "isci", "kadin" ya da "".
## Sakinin balonunda söyleyeceği özel söz varsa döndürür (yan görev), yoksa "".
func selamlasti(tip: String) -> String:
	var ek := gorev_ilerle("selam")
	var soz := ""
	if tip == "teyze":
		ek += gorev_ilerle("teyze")
		if yan_gorev == "ekmek_alindi":
			yan_gorev = ""
			para += 60
			soz = "Sağ ol evladım, Allah razı olsun!"
			Ses.soz("sakin_teyze_tesekkur", 0.2)
			ek += "\nTeyzeye ekmeğini götürdün. Hayır duasını aldın! (+60 TL)" + _itibar_artir(2)
		elif yan_gorev == "" and not gece_mi() and randf() < 0.35:
			yan_gorev = "ekmek"
			soz = "Evladım, bakkaldan bana bir ekmek alır mısın?"
			Ses.soz("sakin_teyze_ekmek", 0.2)
			ek += "\nYan görev: Teyze bakkaldan ekmek istedi. Alışverişte ekmek de al, sonra ona götür."
	elif tip == "memur":
		if yan_gorev == "cuzdan_bulundu":
			yan_gorev = ""
			para += 80
			soz = "Cüzdanım! Allah razı olsun komşu!"
			Ses.soz("sakin_memur_tesekkur", 0.2)
			ek += "\nCüzdanı sahibine verdin. Memur teşekkür edip 80 TL verdi! (+80 TL)" + _itibar_artir(2)
		elif yan_gorev == "" and not gece_mi() and hava == "acik" and randf() < 0.3:
			yan_gorev = "cuzdan"
			soz = "Komşu, cüzdanımı parkta düşürdüm galiba!"
			Ses.soz("sakin_memur_cuzdan", 0.2)
			ek += "\nYan görev: Memur cüzdanını bakkalın arkasındaki parkta düşürmüş. Bul ve geri getir!"
			cuzdan_dustu.emit()
	elif tip == "isci":
		if yan_gorev == "yemek_alindi":
			yan_gorev = ""
			para += 50
			soz = "Eline sağlık usta, açlıktan ölüyordum!"
			Ses.soz("sakin_isci_tesekkur", 0.2)
			ek += "\nİşçi ustaya yemeğini götürdün. Dua etti, bahşiş verdi! (+50 TL)" + _itibar_artir(2)
		elif yan_gorev == "" and not gece_mi() and randf() < 0.3:
			yan_gorev = "yemek"
			soz = "Usta, sefertasımı evde unuttum. Bana bir simit alır mısın?"
			Ses.soz("sakin_isci_yemek", 0.2)
			ek += "\nYan görev: İşçi usta aç kalmış. Bakkalda alışveriş yaparken ona da simit + ayran al, sonra götür."
	if ek != "":
		mesaj.emit(ek.strip_edges())
	return soz
