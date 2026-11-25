extends Camera3D
## Tepeden eğik bakan takip kamerası. Fare tekerleği / +- düğmeleri ile yakınlaşır, iç mekânda otomatik yaklaşır.

const EGIM := 55.0
const EN_YAKIN := 8.0
const EN_UZAK := 40.0

var hedef: Node3D
var hedef_mesafe := 16.0
var mesafe := 16.0
var ic_mekan := 0


func _ready() -> void:
	fov = 45.0
	far = 300.0
	rotation_degrees = Vector3(-EGIM, 0.0, 0.0)


func _ofset() -> Vector3:
	var r := deg_to_rad(EGIM)
	return Vector3(0.0, sin(r), cos(r)) * mesafe + Vector3(0.0, 1.0, 0.0)


func yerles() -> void:
	if hedef:
		global_position = hedef.global_position + _ofset()


func yakinlas(miktar: float) -> void:
	hedef_mesafe = clampf(hedef_mesafe + miktar, EN_YAKIN, EN_UZAK)


func _process(delta: float) -> void:
	if hedef == null:
		return
	var m := 9.0 if ic_mekan > 0 else hedef_mesafe
	mesafe = lerpf(mesafe, m, clampf(4.0 * delta, 0.0, 1.0))
	global_position = global_position.lerp(hedef.global_position + _ofset(), clampf(10.0 * delta, 0.0, 1.0))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			yakinlas(-2.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			yakinlas(2.0)
