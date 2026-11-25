extends CanvasLayer
## Ekran arayüzü: saat, para, tokluk/enerji, eylem düğmesi, joystick, mesajlar, karakter oluşturma.
## Sprite Atölye'den gelen ikon/portre (assets/uretilen/...) varsa otomatik gösterilir.

signal eylem_istendi

const JOYSTICK := preload("res://betikler/joystick.gd")
const EYLEM_IKONU := {"uyu": "ikon_yatak", "simit": "ikon_simit", "cay": "ikon_cay", "nobet": "ikon_nobet"}

var oyuncu
var kamera
var saat_etiket: Label
var para_etiket: Label
var tokluk_cubuk: ProgressBar
var enerji_cubuk: ProgressBar
var eylem_dugme: Button
var kisi_karti: VBoxContainer
var kisi_resim: TextureRect
var kisi_etiket: Label
var mesaj_etiket: Label
var perde: ColorRect
var karakter_paneli: PanelContainer
var telefon_paneli: PanelContainer
var telefon_yazi: Label
var _zaman := 0.0
var _mesaj_sure := 0.0
var _dokunmatik := false


static func gorsel(ad: String) -> Texture2D:
	var yol := "res://assets/uretilen/%s.png" % ad
	if ResourceLoader.exists(yol):
		return load(yol)
	return null


func _ready() -> void:
	_dokunmatik = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	var kok := Control.new()
	kok.set_anchors_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kok)

	# --- sol üst: durum paneli
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	kok.add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)
	var portre_doku := gorsel("oyuncu_portre")
	if portre_doku == null:
		portre_doku = gorsel("karakterler/oyuncu")
	if portre_doku:
		var portre := TextureRect.new()
		portre.texture = portre_doku
		portre.custom_minimum_size = Vector2(80, 80)
		portre.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portre.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(portre)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = 260
	hb.add_child(vb)
	saat_etiket = _etiket(vb, 22)
	para_etiket = _etiket(vb, 20)
	tokluk_cubuk = _cubuk(vb, "Tokluk", Color(0.95, 0.6, 0.2), "ikon_simit")
	enerji_cubuk = _cubuk(vb, "Enerji", Color(0.3, 0.8, 0.4), "ikon_cay")

	# --- sağ alt: yakınlaştırma, karakter, eylem
	var sag := VBoxContainer.new()
	sag.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sag.offset_left = -24
	sag.offset_right = -24
	sag.offset_top = -24
	sag.offset_bottom = -24
	sag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sag.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sag.alignment = BoxContainer.ALIGNMENT_END
	sag.add_theme_constant_override("separation", 10)
	kok.add_child(sag)
	var ust := HBoxContainer.new()
	ust.alignment = BoxContainer.ALIGNMENT_END
	sag.add_child(ust)
	var kd := _dugme(ust, "Karakter", Vector2(130, 60))
	kd.pressed.connect(karakter_ekrani_ac)
	var td := _dugme(ust, "Telefon", Vector2(130, 60))
	td.pressed.connect(telefon_ac)
	var eksi := _dugme(ust, "-", Vector2(60, 60))
	eksi.pressed.connect(func() -> void: kamera.yakinlas(3.0))
	var arti := _dugme(ust, "+", Vector2(60, 60))
	arti.pressed.connect(func() -> void: kamera.yakinlas(-3.0))
	kisi_karti = VBoxContainer.new()
	kisi_karti.visible = false
	sag.add_child(kisi_karti)
	kisi_resim = TextureRect.new()
	kisi_resim.custom_minimum_size = Vector2(320, 220)
	kisi_resim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kisi_resim.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kisi_karti.add_child(kisi_resim)
	kisi_etiket = _etiket(kisi_karti, 22)
	kisi_etiket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kisi_etiket.add_theme_constant_override("outline_size", 8)
	kisi_etiket.add_theme_color_override("font_outline_color", Color.BLACK)
	eylem_dugme = _dugme(sag, "", Vector2(320, 90))
	eylem_dugme.add_theme_font_size_override("font_size", 24)
	eylem_dugme.expand_icon = true
	eylem_dugme.visible = false
	eylem_dugme.pressed.connect(func() -> void: eylem_istendi.emit())

	# --- sol alt: joystick (dokunmatik cihazlarda)
	var js = JOYSTICK.new()
	js.oyuncu = oyuncu
	js.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	js.offset_left = 30
	js.offset_right = 250
	js.offset_top = -250
	js.offset_bottom = -30
	js.visible = _dokunmatik
	kok.add_child(js)

	# --- üst orta: mesaj
	mesaj_etiket = Label.new()
	mesaj_etiket.set_anchors_preset(Control.PRESET_CENTER_TOP)
	mesaj_etiket.offset_top = 24
	mesaj_etiket.grow_horizontal = Control.GROW_DIRECTION_BOTH
	mesaj_etiket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mesaj_etiket.add_theme_font_size_override("font_size", 26)
	mesaj_etiket.add_theme_constant_override("outline_size", 8)
	mesaj_etiket.add_theme_color_override("font_outline_color", Color.BLACK)
	kok.add_child(mesaj_etiket)
	Oyun.mesaj.connect(mesaj_goster)

	# --- kararma perdesi (uyku/nöbet)
	perde = ColorRect.new()
	perde.color = Color(0, 0, 0, 0)
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(perde)

	_karakter_paneli_kur(kok)
	_telefon_kur(kok)
	if not Oyun.karakter_hazir:
		karakter_ekrani_ac()


func _etiket(ebeveyn: Control, boyut: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", boyut)
	ebeveyn.add_child(l)
	return l


func _dugme(ebeveyn: Control, yazi: String, boyut: Vector2) -> Button:
	var b := Button.new()
	b.text = yazi
	b.custom_minimum_size = boyut
	b.add_theme_font_size_override("font_size", 22)
	b.focus_mode = Control.FOCUS_NONE
	ebeveyn.add_child(b)
	return b


func _cubuk(ebeveyn: Control, ad: String, renk: Color, ikon: String) -> ProgressBar:
	var hb := HBoxContainer.new()
	ebeveyn.add_child(hb)
	var t := gorsel(ikon)
	if t:
		var tr := TextureRect.new()
		tr.texture = t
		tr.custom_minimum_size = Vector2(26, 26)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(tr)
	var l := Label.new()
	l.text = ad
	l.custom_minimum_size.x = 72
	hb.add_child(l)
	var pb := ProgressBar.new()
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.custom_minimum_size.y = 20
	pb.show_percentage = false
	var dolgu := StyleBoxFlat.new()
	dolgu.bg_color = renk
	dolgu.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", dolgu)
	hb.add_child(pb)
	return pb


func _process(delta: float) -> void:
	saat_etiket.text = Oyun.saat_metni()
	para_etiket.text = "Para: %d TL" % Oyun.para
	tokluk_cubuk.value = Oyun.tokluk
	enerji_cubuk.value = Oyun.enerji
	# ihtiyaç azalınca çubuk kırmızı yanıp söner
	_zaman += delta
	var nabiz := 0.5 + 0.5 * sin(_zaman * 6.0)
	var kirmizi := Color(1.0, 0.35, 0.35)
	tokluk_cubuk.modulate = kirmizi.lerp(Color.WHITE, nabiz) if Oyun.tokluk < 20.0 else Color.WHITE
	enerji_cubuk.modulate = kirmizi.lerp(Color.WHITE, nabiz) if Oyun.enerji < 15.0 else Color.WHITE
	if _mesaj_sure > 0.0:
		_mesaj_sure -= delta
		mesaj_etiket.modulate.a = clampf(_mesaj_sure, 0.0, 1.0)


func mesaj_goster(metin: String) -> void:
	mesaj_etiket.text = metin
	_mesaj_sure = 4.0
	mesaj_etiket.modulate.a = 1.0


func eylem_goster(ad: String, metin: String, kisi := "", kisi_ad := "") -> void:
	var resim: Texture2D = null
	if kisi != "":
		resim = gorsel("karakterler/" + kisi)
	kisi_resim.texture = resim
	kisi_resim.visible = resim != null
	kisi_etiket.text = kisi_ad
	kisi_karti.visible = kisi_ad != ""
	eylem_dugme.text = metin if _dokunmatik else "[E]  " + metin
	eylem_dugme.icon = gorsel(EYLEM_IKONU.get(ad, ""))
	eylem_dugme.visible = true


func eylem_gizle() -> void:
	eylem_dugme.visible = false
	kisi_karti.visible = false


func karart() -> void:
	perde.color.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(perde, "color:a", 0.0, 1.2)


# --- karakter oluşturma ("kendini oyuna ekle")
func _karakter_paneli_kur(kok: Control) -> void:
	karakter_paneli = PanelContainer.new()
	karakter_paneli.set_anchors_preset(Control.PRESET_CENTER)
	karakter_paneli.grow_horizontal = Control.GROW_DIRECTION_BOTH
	karakter_paneli.grow_vertical = Control.GROW_DIRECTION_BOTH
	karakter_paneli.visible = false
	kok.add_child(karakter_paneli)
	var kenar := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		kenar.add_theme_constant_override(k, 20)
	karakter_paneli.add_child(kenar)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	kenar.add_child(vb)
	var baslik := _etiket(vb, 28)
	baslik.text = "Kendini oyuna ekle"
	var isim_satir := HBoxContainer.new()
	vb.add_child(isim_satir)
	var il := Label.new()
	il.text = "İsim"
	il.custom_minimum_size.x = 140
	isim_satir.add_child(il)
	var isim := LineEdit.new()
	isim.custom_minimum_size = Vector2(260, 44)
	isim.text = str(Oyun.karakter["isim"])
	isim.text_changed.connect(func(t: String) -> void:
		Oyun.karakter["isim"] = t
		Oyun.karakter_degisti.emit()
	)
	isim_satir.add_child(isim)
	_secici(vb, "Ten rengi", "ten", Oyun.TEN_RENKLERI)
	_secici(vb, "Saç rengi", "sac", Oyun.SAC_RENKLERI)
	_secici(vb, "Saç modeli", "sac_model", [])
	_secici(vb, "Gömlek", "gomlek", Oyun.GOMLEK_RENKLERI)
	_secici(vb, "Pantolon", "pantolon", Oyun.PANTOLON_RENKLERI)
	var sakal := CheckBox.new()
	sakal.text = "Sakal"
	sakal.button_pressed = bool(Oyun.karakter["sakal"])
	sakal.toggled.connect(func(b: bool) -> void:
		Oyun.karakter["sakal"] = b
		Oyun.karakter_degisti.emit()
	)
	vb.add_child(sakal)
	var ipucu := Label.new()
	ipucu.text = "İpucu: Fotoğrafını depoya assets/ben/foto.png olarak yüklersen\nSprite Atölye senin çizgi film portreni yapar, burada görünür."
	ipucu.add_theme_font_size_override("font_size", 15)
	ipucu.modulate = Color(1, 1, 1, 0.75)
	vb.add_child(ipucu)
	var basla := _dugme(vb, "Başla", Vector2(200, 60))
	basla.pressed.connect(func() -> void:
		Oyun.karakter_hazir = true
		Oyun.duraklat = false
		karakter_paneli.visible = false
		Oyun.kaydet()
	)


func _secici(vb: VBoxContainer, baslik: String, anahtar: String, renkler: Array) -> void:
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	var l := Label.new()
	l.text = baslik
	l.custom_minimum_size.x = 140
	hb.add_child(l)
	var geri := _dugme(hb, "<", Vector2(56, 44))
	var ornek := ColorRect.new()
	ornek.custom_minimum_size = Vector2(140, 44)
	hb.add_child(ornek)
	var yazi := Label.new()
	yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	yazi.set_anchors_preset(Control.PRESET_FULL_RECT)
	ornek.add_child(yazi)
	var ileri := _dugme(hb, ">", Vector2(56, 44))
	var adet: int = renkler.size() if not renkler.is_empty() else Oyun.SAC_MODELLERI.size()
	var guncelle := func() -> void:
		var i := int(Oyun.karakter[anahtar])
		if renkler.is_empty():
			ornek.color = Color(0.2, 0.2, 0.22)
			yazi.text = Oyun.SAC_MODELLERI[posmod(i, adet)]
		else:
			ornek.color = Oyun.renk(renkler, i)
	guncelle.call()
	geri.pressed.connect(func() -> void:
		Oyun.karakter[anahtar] = posmod(int(Oyun.karakter[anahtar]) - 1, adet)
		Oyun.karakter_degisti.emit()
		guncelle.call()
	)
	ileri.pressed.connect(func() -> void:
		Oyun.karakter[anahtar] = posmod(int(Oyun.karakter[anahtar]) + 1, adet)
		Oyun.karakter_degisti.emit()
		guncelle.call()
	)


# --- telefon menüsü: meslekler, kariyer basamakları, ipucu
func _telefon_kur(kok: Control) -> void:
	telefon_paneli = PanelContainer.new()
	telefon_paneli.set_anchors_preset(Control.PRESET_CENTER)
	telefon_paneli.grow_horizontal = Control.GROW_DIRECTION_BOTH
	telefon_paneli.grow_vertical = Control.GROW_DIRECTION_BOTH
	telefon_paneli.custom_minimum_size = Vector2(440, 0)
	telefon_paneli.visible = false
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(0.07, 0.08, 0.11, 0.96)
	stil.border_color = Color(0.32, 0.33, 0.38)
	stil.set_border_width_all(6)
	stil.set_corner_radius_all(28)
	telefon_paneli.add_theme_stylebox_override("panel", stil)
	kok.add_child(telefon_paneli)
	var kenar := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		kenar.add_theme_constant_override(k, 26)
	telefon_paneli.add_child(kenar)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	kenar.add_child(vb)
	var baslik := _etiket(vb, 26)
	baslik.text = "Telefon"
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	telefon_yazi = _etiket(vb, 19)
	telefon_yazi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	telefon_yazi.custom_minimum_size.x = 388
	var kapat := _dugme(vb, "Kapat", Vector2(200, 56))
	kapat.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kapat.pressed.connect(func() -> void:
		telefon_paneli.visible = false
		Oyun.duraklat = false
	)


func telefon_ac() -> void:
	if karakter_paneli.visible:
		return
	if telefon_paneli.visible:
		telefon_paneli.visible = false
		Oyun.duraklat = false
		return
	telefon_yazi.text = Oyun.telefon_metni()
	Oyun.duraklat = true
	telefon_paneli.visible = true


func karakter_ekrani_ac() -> void:
	if telefon_paneli.visible:
		telefon_paneli.visible = false
	Oyun.duraklat = true
	karakter_paneli.visible = true
