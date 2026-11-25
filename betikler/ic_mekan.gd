extends Area3D
## Bir binanın içi. Oyuncu girince çatı ve ön duvar gizlenir (Commandos tarzı kesit görünüm).

signal oyuncu_girdi
signal oyuncu_cikti

var gizlenecekler: Array = []


func _ready() -> void:
	body_entered.connect(_girdi)
	body_exited.connect(_cikti)


func _girdi(b: Node3D) -> void:
	if b.is_in_group("oyuncu"):
		for g in gizlenecekler:
			g.visible = false
		oyuncu_girdi.emit()


func _cikti(b: Node3D) -> void:
	if b.is_in_group("oyuncu"):
		for g in gizlenecekler:
			g.visible = true
		oyuncu_cikti.emit()
