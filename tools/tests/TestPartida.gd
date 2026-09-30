extends Node
# ═══════════════════════════════════════════════════
# PRUEBAS DE PARTIDA — Void Sentinel
#
# Los sistemas que se jugaban sin red: disparos especiales, Commander, el
# depósito del dron y el tutorial. Todos existían y compilaban, pero nadie
# comprobaba su lógica — que es justo donde han salido los bugs de este
# proyecto (gastar negativo regalaba recursos, rematar a un muerto puntuaba
# dos veces).
#
#   powershell -File tools\tests\ejecutar-pruebas.ps1
#
# ⚠ Toca user:// (el flag del tutorial): lánzala con el runner, que respalda
#   y restaura el guardado del jugador.
# ═══════════════════════════════════════════════════

# No tiene class_name: es el script de una escena, así que se carga por ruta.
const TutorialOverlay = preload("res://scripts/ui/TutorialOverlay.gd")

var _fallos: int = 0
var _pasados: int = 0


func _ready() -> void:
	print("═══ PRUEBAS DE PARTIDA ═══\n")
	_test_disparos_especiales()
	_test_commander_fin()
	await _test_dron_deposito()
	_test_tutorial()
	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


# ═══════════════════════════════════════════════════
# DISPAROS ESPECIALES
# ═══════════════════════════════════════════════════
func _test_disparos_especiales() -> void:
	_sec("Disparos especiales")
	var sis := get_node("/root/Sistemadisparosespeciales")
	_reset_disparos(sis)

	# Sin Commander en pantalla, matar no carga nada: la recarga se pausa.
	sis.registrar_kill_enemigo()
	_eq(float(sis.get_disparos_disponibles()), 0.0, "sin Commander, las bajas no cargan disparos")

	# Al aparecer el Commander se regalan 3 (DISPAROS_INICIALES).
	var falso := Node.new()
	add_child(falso)
	sis.registrar_commander(falso)
	_eq(float(sis.get_disparos_disponibles()), float(sis.DISPAROS_INICIALES),
		"el Commander regala %d disparos al aparecer" % sis.DISPAROS_INICIALES)
	_ok(sis.get_commander_activo(), "queda marcado como activo")

	# Cada tanda de bajas da un disparo más.
	var por_disparo: int = sis.get_kills_para_proximo_disparo()
	for i in por_disparo - 1:
		sis.registrar_kill_enemigo()
	_eq(float(sis.get_disparos_disponibles()), float(sis.DISPAROS_INICIALES),
		"antes de completar la tanda no hay disparo nuevo")
	sis.registrar_kill_enemigo()
	_eq(float(sis.get_disparos_disponibles()), float(sis.DISPAROS_INICIALES + 1),
		"al completar la tanda se gana uno")

	# Gastar.
	var antes: int = sis.get_disparos_disponibles()
	_ok(sis.usar_disparo_especial(), "usar un disparo cuando hay devuelve true")
	_eq(float(sis.get_disparos_disponibles()), float(antes - 1), "y descuenta uno")

	# El tope no se puede pasar ni regalando de más.
	sis.disparos_disponibles = sis.CAP_MAXIMO_DISPAROS
	sis.registrar_commander(falso)
	_eq(float(sis.get_disparos_disponibles()), float(sis.CAP_MAXIMO_DISPAROS),
		"no se pasa del tope de %d" % sis.CAP_MAXIMO_DISPAROS)

	# Sin disparos, usar no puede devolver true (ni dejar el contador negativo).
	sis.disparos_disponibles = 0
	_ok(not sis.usar_disparo_especial(), "sin disparos, usar devuelve false")
	_eq(float(sis.get_disparos_disponibles()), 0.0, "y el contador no baja de cero")

	falso.queue_free()


# Muerto y escapado NO son lo mismo: si muere se pierden los disparos, si
# escapa se conservan hasta su próxima aparición.
func _test_commander_fin() -> void:
	_sec("Commander: muere o escapa")
	var sis := get_node("/root/Sistemadisparosespeciales")

	_reset_disparos(sis)
	var falso := Node.new()
	add_child(falso)
	sis.registrar_commander(falso)
	sis._on_commander_muerto()
	_eq(float(sis.get_disparos_disponibles()), 0.0, "si muere, se pierden los disparos")
	_ok(not sis.get_commander_activo(), "y deja de estar activo")

	_reset_disparos(sis)
	sis.registrar_commander(falso)
	var antes: int = sis.get_disparos_disponibles()
	sis._on_commander_escapo()
	_eq(float(sis.get_disparos_disponibles()), float(antes), "si escapa, los disparos se conservan")
	_ok(not sis.get_commander_activo(), "pero tampoco sigue activo")

	# Y la escena del Commander muere una sola vez, como el resto de espectros.
	var escena: PackedScene = load("res://escenas/enemigos/EspectroComander.tscn")
	_ok(escena != null, "la escena del Commander carga")
	falso.queue_free()


# ═══════════════════════════════════════════════════
# DRON
# ═══════════════════════════════════════════════════
func _test_dron_deposito() -> void:
	_sec("Dron: depósito en el Nexo")
	var escena: PackedScene = load("res://escenas/jugador/Dron.tscn")
	if escena == null:
		_ok(false, "la escena del dron carga")
		return
	var dron: Node2D = escena.instantiate()
	add_child(dron)
	await get_tree().process_frame
	dron.set_physics_process(false)

	var energia_antes: float = Economia.energia
	var frag_antes: int = Economia.fragmentos
	dron.fragmentos_en_dron = 7
	dron._depositar()

	_eq(Economia.energia - energia_antes, 70.0, "cada fragmento deja 10 de energía")
	_eq(float(Economia.fragmentos - frag_antes), 7.0, "y los fragmentos se acumulan en el perfil")
	_eq(float(dron.fragmentos_en_dron), 0.0, "el dron se vacía al depositar")
	_ok(dron.estado == dron.Estado.EN_RECARGA, "y entra en recarga")

	# La capacidad sube con la ascensión (1 cada 3).
	var cap_base: int = dron.capacidad_actual
	Economia.numero_ascension += 9
	dron._actualizar_capacidad()
	_eq(float(dron.capacidad_actual - cap_base), 3.0, "la capacidad sube 1 cada 3 ascensiones")
	Economia.numero_ascension -= 9

	dron.queue_free()
	await get_tree().process_frame


# ═══════════════════════════════════════════════════
# TUTORIAL
# ═══════════════════════════════════════════════════
func _test_tutorial() -> void:
	_sec("Tutorial")
	var ruta := "user://tutorial.save"
	var habia := FileAccess.file_exists(ruta)

	var d := DirAccess.open("user://")
	if habia and d:
		d.remove("tutorial.save")
	_ok(TutorialOverlay.debe_mostrar(), "se muestra la primera vez")

	TutorialOverlay._marcar_visto()
	_ok(TutorialOverlay.ya_visto(), "queda marcado como visto")
	_ok(not TutorialOverlay.debe_mostrar(), "y no vuelve a salir")

	_ok(TutorialOverlay.SLIDES.size() > 0, "tiene pasos que enseñar (%d)" % TutorialOverlay.SLIDES.size())
	# Los iconos son texto: si caen en la zona de emoji, en Android salen huecos.
	var malos := ""
	for slide in TutorialOverlay.SLIDES:
		malos += _simbolos_problematicos(str(slide.get("icono", "")))
		malos += _simbolos_problematicos(str(slide.get("titulo", "")))
	_ok(malos.is_empty(), "sus iconos y títulos se pintan en Android%s"
		% ("" if malos.is_empty() else " (%s)" % malos))

	# Dejar el flag como estaba: el runner restaura user://, pero no conviene
	# que una prueba cambie lo que ve la siguiente.
	if not habia and d:
		d.remove("tutorial.save")


# ═══════════════════════════════════════════════════
func _reset_disparos(sis: Node) -> void:
	sis.disparos_disponibles = 0
	sis.kills_desde_ultimo_disparo = 0
	sis.commander_activo = false


func _simbolos_problematicos(texto: String) -> String:
	var malos := ""
	for i in texto.length():
		var cp := texto.unicode_at(i)
		if cp > 0xFFFF or (cp >= 0x2600 and cp <= 0x26FF) or cp == 0xFE0F:
			malos += "U+%04X " % cp
	return malos.strip_edges()


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
	_ok(is_equal_approx(a, b), "%s  [%s vs %s]" % [desc, a, b])
