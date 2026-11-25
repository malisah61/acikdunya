extends Control
## Dokunmatik sanal joystick (telefonda sol alt köşe).

const YARICAP := 90.0

var oyuncu
var _parmak := -1
var _uc := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed and _parmak == -1 and get_global_rect().has_point(e.position):
			_parmak = e.index
			_guncelle(e.position)
		elif not e.pressed and e.index == _parmak:
			_parmak = -1
			_uc = Vector2.ZERO
			if oyuncu:
				oyuncu.joystick = Vector2.ZERO
			queue_redraw()
	elif e is InputEventScreenDrag and e.index == _parmak:
		_guncelle(e.position)


func _guncelle(p: Vector2) -> void:
	var v := p - get_global_rect().get_center()
	if v.length() > YARICAP:
		v = v.normalized() * YARICAP
	_uc = v
	if oyuncu:
		oyuncu.joystick = v / YARICAP
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, YARICAP, Color(1, 1, 1, 0.15))
	draw_arc(c, YARICAP, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 3.0)
	draw_circle(c + _uc, 38.0, Color(1, 1, 1, 0.45))
