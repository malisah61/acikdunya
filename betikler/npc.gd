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
	model = Karakter.olustur(
		Oyun.renk(Oyun.TEN_RENKLERI, _rng.randi()), Oyun.renk(Oyun.SAC_RENKLERI, _rng.randi()), _rng.randi() % 3,
		Color(_rng.randf(), _rng.randf(), _rng.randf()).lerp(Color(0.5, 0.5, 0.5), 0.3),
		Oyun.renk(Oyun.PANTOLON_RENKLERI, _rng.randi()), _rng.randf() < 0.3)
	model.scale = Vector3.ONE * _rng.randf_range(0.9, 1.05)
	add_child(model)


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
