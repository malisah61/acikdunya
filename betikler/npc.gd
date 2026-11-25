extends Node3D
## Mahalle sakini: gündüz kaldırımlarda dolaşır, gece evine (başladığı köşeye) dönüp kaybolur.

const Karakter := preload("res://betikler/karakter.gd")

var hatlar: Array = []
var hiz := 1.4
var model: Node3D
var _i := 0
var _j := 0
var _ev := Vector2i.ZERO
var _hedef := Vector3.ZERO
var _kayma := Vector3.ZERO
var _faz := 0.0
var _bekle := 0.0
var _rng := RandomNumberGenerator.new()
var _oyuncu: Node3D
var _balon: Label3D
var _selam_sure := 0.0
var _selamlasti := false
## Sakinin tipi: "teyze", "kadin", "ogrenci", "memur", "isci" ya da "" (kendi repliğiyle selam verir)
var _tip := ""
## Tipine göre balonda görünen söz (assets/ses/replik/sakin_<tip>_selam.ogg ile aynı cümle)
const TIP_SOZ := {
	"teyze": "Aman evladım, hoş geldin!",
	"kadin": "Merhaba canım! Pazardan dönüyorum.",
	"ogrenci": "Selam abi! Sınav vardı bugün.",
	"memur": "Günaydın komşu, hayırlı işler.",
	"isci": "Kolay gelsin usta! Şantiyeden geliyorum.",
}


func kur(h: Array, tohum: int) -> void:
	hatlar = h
	_rng.seed = tohum
	_i = _rng.randi_range(0, h.size() - 1)
	_j = _rng.randi_range(0, h.size() - 1)
	_ev = Vector2i(_i, _j)
	_kayma = Vector3(_rng.randf_range(-0.6, 0.6), 0.0, _rng.randf_range(-0.6, 0.6))
	position = _nokta(_i, _j)
	_hedef = position
	hiz = _rng.randf_range(1.1, 1.7)
	var ten := Oyun.renk(Oyun.TEN_RENKLERI, _rng.randi())
	var sac_renk := Oyun.renk(Oyun.SAC_RENKLERI, _rng.randi())
	var sac_model := _rng.randi() % 3
	var gomlek := Color(_rng.randf(), _rng.randf(), _rng.randf()).lerp(Color(0.5, 0.5, 0.5), 0.3)
	var pantolon := Oyun.renk(Oyun.PANTOLON_RENKLERI, _rng.randi())
	var sakal := _rng.randf() < 0.3
	# uzun saçlı, sakalsız sakinlerin bir kısmı mahallenin teyzeleri: kendi repliğiyle selam verir
	if sac_model == 1 and not sakal:
		_tip = "teyze" if _rng.randf() < 0.6 else "kadin"
	else:
		_tip = ["ogrenci", "memur", "isci", "", ""][_rng.randi() % 5]
	model = Karakter.olustur(ten, sac_renk, sac_model, gomlek, pantolon, sakal)
	model.scale = Vector3.ONE * _rng.randf_range(0.9, 1.05)
	add_child(model)
	_balon = Label3D.new()
	_balon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_balon.position.y = 2.3
	_balon.font_size = 40
	_balon.pixel_size = 0.006
	_balon.outline_size = 10
	_balon.no_depth_test = true
	_balon.visible = false
	add_child(_balon)


## Yanından geçen oyuncuyu durup selamlar (bir kere; oyuncu uzaklaşınca yeniden selamlayabilir).
func _selam_ver() -> void:
	var d := Oyun.dakika
	var sozler: Array = ["Selam komşu!", "Nasılsın?", "Hayırdır, nereye böyle?"]
	if d < 11.0 * 60.0:
		sozler.append("Günaydın!")
	elif d < 18.0 * 60.0:
		sozler.append("Kolay gelsin!")
	else:
		sozler.append("İyi akşamlar!")
	_balon.text = sozler[_rng.randi() % sozler.size()]
	_selam_sure = 2.0
	if _tip != "" and _rng.randf() < 0.5:
		_balon.text = TIP_SOZ[_tip]
		_selam_sure = 3.5
		Ses.replik("sakin_" + _tip, global_position + Vector3(0, 1.6, 0))
	# günlük görev / yan görev (teyzenin ekmeği): özel söz varsa balonda o görünür
	var ozel := Oyun.selamlasti(_tip)
	if ozel != "":
		_balon.text = ozel
		_selam_sure = 4.0


func _nokta(i: int, j: int) -> Vector3:
	return Vector3(float(hatlar[i]), 0.0, float(hatlar[j])) + _kayma


func _yeni_hedef() -> void:
	if Oyun.gece_mi():
		if _i != _ev.x:
			_i += signi(_ev.x - _i)
		elif _j != _ev.y:
			_j += signi(_ev.y - _j)
	else:
		var secenek: Array[Vector2i] = []
		if _i > 0:
			secenek.append(Vector2i(_i - 1, _j))
		if _i < hatlar.size() - 1:
			secenek.append(Vector2i(_i + 1, _j))
		if _j > 0:
			secenek.append(Vector2i(_i, _j - 1))
		if _j < hatlar.size() - 1:
			secenek.append(Vector2i(_i, _j + 1))
		var s: Vector2i = secenek[_rng.randi() % secenek.size()]
		_i = s.x
		_j = s.y
		if _rng.randf() < 0.25:
			_bekle = _rng.randf_range(1.0, 4.0)
	_hedef = _nokta(_i, _j)


func _process(delta: float) -> void:
	if model == null:
		return
	var evde := Vector2i(_i, _j) == _ev and position.distance_to(_hedef) < 0.1
	if Oyun.gece_mi() and evde:
		visible = false
		return
	visible = true
	if _oyuncu == null:
		_oyuncu = get_tree().get_first_node_in_group("oyuncu") as Node3D
	if _oyuncu:
		var uzaklik := global_position.distance_to(_oyuncu.global_position)
		if not _selamlasti and uzaklik < 2.5:
			_selamlasti = true
			_selam_ver()
		elif _selamlasti and uzaklik > 7.0:
			_selamlasti = false
		if _selam_sure > 0.0:
			_selam_sure -= delta
			_balon.visible = _selam_sure > 0.0
			var f := _oyuncu.global_position - global_position
			model.rotation.y = lerp_angle(model.rotation.y, atan2(f.x, f.z), clampf(8.0 * delta, 0.0, 1.0))
			Karakter.yuru(model, _faz, 0.0)
			return
	if _bekle > 0.0:
		_bekle -= delta
		Karakter.yuru(model, _faz, 0.0)
		return
	var fark := _hedef - position
	if fark.length() < 0.05:
		_yeni_hedef()
		return
	var yon := fark.normalized()
	position += yon * minf(hiz * delta, fark.length())
	model.rotation.y = lerp_angle(model.rotation.y, atan2(yon.x, yon.z), clampf(8.0 * delta, 0.0, 1.0))
	_faz += delta * hiz * 4.0
	Karakter.yuru(model, _faz, 1.0)
