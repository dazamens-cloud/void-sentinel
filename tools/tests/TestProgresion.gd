extends Node
# ═══════════════════════════════════════════════════
# PRUEBAS DE PROGRESIÓN — Void Sentinel
#
# Oleadas y ascensiones, y el checkpoint de reanudar partida (que toca el
# guardado del jugador, así que se respalda y restaura).
#
#   godot --path . --headless tools/tests/TestProgresion.tscn
# ═══════════════════════════════════════════════════

# AscensionManager no es autoload (vive como nodo en mundo.tscn), así que se
# carga el script para leer sus constantes de balance.
const ASC := preload("res://scripts/utils/AscensionManager.gd")

var _fallos: int = 0
var _pasados: int = 0
var _backup: Dictionary = {}

const FICHEROS_SAVE := [
	"user://economia.save", "user://nexo.save", "user://estadisticas.save",
	"user://misiones.save", "user://run.save",
]


func _ready() -> void:
	_respaldar()
	print("═══ PRUEBAS DE PROGRESIÓN ═══\n")
	_test_oleadas()
	_test_ascension()
	_test_reanudar()
	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


func _exit_tree() -> void:
	_restaurar()


# ═══════════════════════════════════════════════════
# OLEADAS
# ═══════════════════════════════════════════════════
func _test_oleadas() -> void:
	_sec("Oleadas — cantidad de enemigos")
	var base: int = ASC.ESPECTROS_BASE
	var tope: int = ASC.TOPE_ESPECTROS_OLEADA

	# Valores concretos esperados de la fórmula documentada (8 + asc, con tope).
	_eq(float(base), 8.0, "la oleada base son 8 espectros")
	_eq(float(tope), 30.0, "el tope por oleada son 30 espectros")
	_eq(float(mini(tope, base + 0)), 8.0, "asc 0 → 8 espectros")
	_eq(float(mini(tope, base + 5)), 13.0, "asc 5 → 13 espectros")
	_eq(float(mini(tope, base + 22)), 30.0, "asc 22 → 30, justo en el tope")

	# El tope debe morder en ascensiones altas: sin él eran miles.
	_eq(float(mini(tope, base + 5000)), float(tope),
		"en asc 5000 la oleada se aplana en el tope (%d)" % tope)
	_ok(tope >= base, "el tope no es menor que la cantidad base")
	_ok(ASC.MAX_ENEMIGOS_SIMULTANEOS <= tope,
		"los simultáneos (%d) no superan el tope de la oleada (%d)"
		% [ASC.MAX_ENEMIGOS_SIMULTANEOS, tope])
	_ok(ASC.DURACION_ASCENSION > 0.0 and ASC.PAUSA_ENTRE_ASCENSIONES > 0.0,
		"la duración de ascensión y la pausa son positivas")


# ═══════════════════════════════════════════════════
# ASCENSIONES
# ═══════════════════════════════════════════════════
func _test_ascension() -> void:
	_sec("Ascensiones — avance y recompensas")
	MejoraManager.reiniciar_mejoras_inrun()
	Economia.iniciar_partida()
	_eq(float(Economia.numero_ascension), 0.0, "la partida arranca en asc 0")

	var energia_antes: float = Economia.energia
	Economia.avanzar_ascension()
	_eq(float(Economia.numero_ascension), 1.0, "avanzar sube la ascensión")
	_ok(Economia.energia > energia_antes, "completar una ascensión da energía")

	# La recompensa base crece con el número de ascensión (10 + asc).
	Economia.energia = 0.0
	Economia.numero_ascension = 0
	Economia.avanzar_ascension()
	var premio_bajo: float = Economia.energia
	Economia.energia = 0.0
	Economia.numero_ascension = 50
	Economia.avanzar_ascension()
	var premio_alto: float = Economia.energia
	_ok(premio_alto > premio_bajo,
		"la recompensa crece con la ascensión (%.0f → %.0f)" % [premio_bajo, premio_alto])

	# Muchas ascensiones seguidas: nada debe desbordar ni volverse NaN.
	Economia.iniciar_partida()
	for i in 300:
		Economia.avanzar_ascension()
	_eq(float(Economia.numero_ascension), 300.0, "aguanta 300 ascensiones seguidas")
	_ok(not is_nan(Economia.energia) and not is_inf(Economia.energia),
		"la energía sigue siendo un número finito (%.0f)" % Economia.energia)
	_ok(Economia.energia > 0.0, "la energía no se vuelve negativa")

	Economia.iniciar_partida()


# ═══════════════════════════════════════════════════
# REANUDAR PARTIDA
# ═══════════════════════════════════════════════════
func _test_reanudar() -> void:
	_sec("Reanudar partida — checkpoint")
	ReanudarPartida.borrar()
	_ok(not ReanudarPartida.hay_partida(), "de inicio no hay checkpoint")

	# Montar una run reconocible y guardarla.
	MejoraManager.reiniciar_mejoras_inrun()
	Economia.iniciar_partida()
	Economia.energia = 4321.0
	Economia.numero_ascension = 17
	Economia.espectros_eliminados = 99
	MejoraManager.mejoras["danio"]["nivel"] = 12
	MejoraManager._aplicar_mejora("danio")
	NexusStats.salud_actual = maxf(1.0, NexusStats.get_salud() * 0.5)
	var salud_guardada: float = NexusStats.salud_actual

	ReanudarPartida.guardar()
	_ok(ReanudarPartida.hay_partida(), "guardar deja un checkpoint en disco")

	# Simular el reinicio: resets como los que hace mundo.gd.
	Economia.iniciar_partida()
	MejoraManager.reiniciar_mejoras_inrun()
	NexusStats.reiniciar_partida()
	_eq(float(Economia.numero_ascension), 0.0, "tras el reset la ascensión vuelve a 0")
	_eq(float(MejoraManager.get_nivel("danio")), 0.0, "tras el reset las mejoras vuelven a 0")

	ReanudarPartida.aplicar()
	_eq(Economia.energia, 4321.0, "restaura la energía")
	_eq(float(Economia.numero_ascension), 17.0, "restaura la ascensión")
	_eq(float(Economia.espectros_eliminados), 99.0, "restaura los espectros eliminados")
	_eq(float(MejoraManager.get_nivel("danio")), 12.0, "restaura los niveles in-run")
	_ok(absf(NexusStats.salud_actual - salud_guardada) < 1.0,
		"restaura la salud del Nexo (%.1f vs %.1f)" % [NexusStats.salud_actual, salud_guardada])
	_ok(NexusStats.salud_actual <= NexusStats.get_salud(),
		"la salud restaurada nunca supera el máximo")

	# El checkpoint se consume: no debe poder reanudarse dos veces.
	_ok(not ReanudarPartida.hay_partida(), "reanudar consume el checkpoint")
	_ok(not ReanudarPartida.debe_reanudar, "la bandera de reanudar queda apagada")

	# Aplicar sin checkpoint no debe reventar ni corromper la partida.
	var asc_previa: int = Economia.numero_ascension
	ReanudarPartida.aplicar()
	_eq(float(Economia.numero_ascension), float(asc_previa),
		"aplicar sin checkpoint no toca la partida")

	# Y borrar dos veces tampoco.
	ReanudarPartida.borrar()
	ReanudarPartida.borrar()
	_ok(not ReanudarPartida.hay_partida(), "borrar es idempotente")


# ═══════════════════════════════════════════════════
func _respaldar() -> void:
	for f in FICHEROS_SAVE:
		if FileAccess.file_exists(f):
			var fa := FileAccess.open(f, FileAccess.READ)
			if fa:
				_backup[f] = fa.get_buffer(fa.get_length())
				fa.close()


func _restaurar() -> void:
	for f in FICHEROS_SAVE:
		if _backup.has(f):
			var fa := FileAccess.open(f, FileAccess.WRITE)
			if fa:
				fa.store_buffer(_backup[f])
				fa.close()
		elif FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("\n[guardado del jugador restaurado]")


func _sec(t: String) -> void:
	print("── %s" % t)


func _ok(cond: bool, desc: String) -> void:
	if cond:
		_pasados += 1
		print("   ✓ ", desc)
	else:
		_fallos += 1
		print("   ✗ FALLO: ", desc)


func _eq(a: float, b: float, desc: String) -> void:
	_ok(absf(a - b) < 0.001, "%s  [%s vs %s]" % [desc, a, b])
