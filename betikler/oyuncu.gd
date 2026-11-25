extends CharacterBody3D
## Oyuncu: klavye (WASD / oklar, Shift koşu) veya dokunmatik joystick ile yürür.

const Karakter := preload("res://betikler/karakter.gd")
const Dunya := preload("res://betikler/dunya.gd")
const YURUME := 4.5
const KOSMA := 7.5

var joystick := Vector2.ZERO
var model: Node3D
var etiket: Label3D
var _faz := 0.0
var _salinim := 0.0
var _adim_sayi := 0


func _ready() -> void:
	add_to_group("oyuncu")
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var k := CapsuleShape3D.new()
	k.radius = 0.3
	k.height = 1.8
	cs.shape = k
	cs.position.y = 0.9
	add_child(cs)
	etiket = Label3D.new()
	etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiket.position.y = 2.25
	etiket.font_size = 48
	etiket.pixel_size = 0.006
	etiket.outline_size = 12
	etiket.no_depth_test = true
	add_child(etiket)
	gorunumu_yenile()
	Oyun.karakter_degisti.connect(gorunumu_yenile)


func gorunumu_yenile() -> void:
	var yon := 0.0
	if model:
		yon = model.rotation.y
		model.queue_free()
	var k: Dictionary = Oyun.karakter
	model = Karakter.olustur(
		Oyun.renk(Oyun.TEN_RENKLERI, k["ten"]), Oyun.renk(Oyun.SAC_RENKLERI, k["sac"]), int(k["sac_model"]),
		Oyun.renk(Oyun.GOMLEK_RENKLERI, k["gomlek"]), Oyun.renk(Oyun.PANTOLON_RENKLERI, k["pantolon"]), bool(k["sakal"]))
	model.rotation.y = yon
	add_child(model)
	etiket.text = str(k["isim"])


func _physics_process(delta: float) -> void:
	var g := Vector2.ZERO
	if not Oyun.duraklat:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			g.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			g.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			g.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			g.x += 1.0
		if g == Vector2.ZERO:
			g = joystick
	if g.length() > 1.0:
		g = g.normalized()
	var hiz := KOSMA if Input.is_physical_key_pressed(KEY_SHIFT) or joystick.length() > 0.95 else YURUME
	if Oyun.enerji < 10.0:
		hiz *= 0.6
	var yon := Vector3(g.x, 0.0, g.y)
	velocity.x = yon.x * hiz
	velocity.z = yon.z * hiz
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= 20.0 * delta
	move_and_slide()
	var hareket := yon.length() > 0.1
	_salinim = lerpf(_salinim, 1.0 if hareket else 0.0, clampf(10.0 * delta, 0.0, 1.0))
	if hareket:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(yon.x, yon.z), clampf(12.0 * delta, 0.0, 1.0))
		_faz += delta * hiz * 2.2 * g.length()
		var n := int(_faz / PI)
		if n != _adim_sayi:
			_adim_sayi = n
			Ses.adim(_zemin(), global_position, hiz > YURUME)
	Karakter.yuru(model, _faz, _salinim)


## Ayağın altındaki zemin: bina içi, yol/kaldırım/otopark ya da çimen.
func _zemin() -> String:
	if Ses.ic_mekan > 0:
		return "ev"
	var p := global_position
	for r in Dunya.YOLLAR:
		if absf(p.x - r) < Dunya.YOL_EN / 2.0 + 2.0 or absf(p.z - r) < Dunya.YOL_EN / 2.0 + 2.0:
			return "asfalt"
	if p.x > 10.0 and p.x < 50.0 and p.z > 9.0 and p.z < 33.0:
		return "asfalt"
	return "cim"
