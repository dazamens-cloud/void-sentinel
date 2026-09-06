extends Node
# ═══════════════════════════════════════════════════
# PRUEBAS DE COMBATE — Void Sentinel
#
# Stats del Nexo (escudo, defensa, crítico, cadencia, regeneración) y ciclo
# de vida de los espectros. Lógica pura: no juzga lo visual ni el "feel".
#
#   godot --path . --headless tools/tests/TestCombate.tscn
# ═══════════════════════════════════════════════════

var _fallos: int = 0
var _pasados: int = 0


func _ready() -> void:
	print("═══ PRUEBAS DE COMBATE ═══\n")
	_test_salud_y_escudo()
	_test_defensa()
	_test_critico()
	_test_cadencia()
	_test_reinicio()
	await _test_espectros()
	await _test_espectro_muerte()
	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


func _test_salud_y_escudo() -> void:
	_sec("Salud y escudo del Nexo")
	NexusStats.reiniciar_partida()
	NexusStats.salud_actual = 100.0
	NexusStats.escudo_actual = 0.0

	var vivo: bool = NexusStats.recibir_ataque(30.0)
	_eq(NexusStats.salud_actual, 70.0, "un ataque sin escudo resta salud directa")
	_ok(vivo, "sigue vivo con salud restante")

	# El escudo debe absorber primero y solo el exceso llega a la salud.
	NexusStats.salud_actual = 100.0
	NexusStats.escudo_actual = 20.0
	NexusStats.recibir_ataque(30.0)
	_eq(NexusStats.escudo_actual, 0.0, "el escudo se consume primero")
	_eq(NexusStats.salud_actual, 90.0, "solo el exceso (10) llega a la salud")

	# Escudo de sobra: la salud no se toca.
	NexusStats.salud_actual = 100.0
	NexusStats.escudo_actual = 50.0
	NexusStats.recibir_ataque(20.0)
	_eq(NexusStats.escudo_actual, 30.0, "el escudo absorbe el golpe entero")
	_eq(NexusStats.salud_actual, 100.0, "la salud queda intacta tras absorber")

	# Muerte.
	NexusStats.salud_actual = 10.0
	NexusStats.escudo_actual = 0.0
	var sigue: bool = NexusStats.recibir_ataque(999.0)
	_ok(not sigue, "recibir_ataque avisa de la muerte")
	_eq(NexusStats.salud_actual, 0.0, "la salud no baja de 0")

	# Curación.
	NexusStats.salud_actual = 50.0
	NexusStats.curar(20.0)
	_eq(NexusStats.salud_actual, 70.0, "curar suma salud")
	NexusStats.curar(9999.0)
	_eq(NexusStats.salud_actual, NexusStats.salud_base, "curar no pasa del máximo")


func _test_defensa() -> void:
	_sec("Defensa (reducción de daño)")
	NexusStats.reiniciar_partida()
	_eq(NexusStats.get_defensa(), 0.0, "sin mejoras no hay reducción")

	# mejora_defensa llega como delta negativo.
	NexusStats.mejora_defensa = -0.25
	_eq(NexusStats.get_defensa(), 0.25, "un delta de -0.25 da 25% de reducción")

	# Tope documentado del 75%.
	NexusStats.mejora_defensa = -50.0
	_eq(NexusStats.get_defensa(), 0.75, "la reducción topa en 75% aunque se dispare")

	# Y nunca negativa (que curaría al atacante).
	NexusStats.mejora_defensa = 5.0
	_ok(NexusStats.get_defensa() >= 0.0,
		"la reducción nunca es negativa (%.2f)" % NexusStats.get_defensa())
	NexusStats.reiniciar_partida()


func _test_critico() -> void:
	_sec("Crítico")
	NexusStats.reiniciar_partida()
	_ok(NexusStats.get_critico_chance() > 0.0, "hay probabilidad crítica base")

	NexusStats.mejora_critico_chance = 99.0
	_eq(NexusStats.get_critico_chance(), 0.75, "la probabilidad crítica topa en 75%")

	NexusStats.reiniciar_partida()
	_ok(NexusStats.get_critico_factor() >= 1.0,
		"el factor crítico nunca reduce el daño (%.2f)" % NexusStats.get_critico_factor())


func _test_cadencia() -> void:
	_sec("Cadencia de disparo")
	NexusStats.reiniciar_partida()
	var base: float = NexusStats.get_cadencia_timer()
	_ok(base > 0.0, "el timer de cadencia es positivo (%.3f s)" % base)

	# Más mejora = menos tiempo entre disparos.
	NexusStats.mejora_cadencia = -0.5
	var mejorado: float = NexusStats.get_cadencia_timer()
	_ok(mejorado < base, "mejorar la cadencia acorta el timer (%.3f → %.3f)" % [base, mejorado])

	# Suelo: ni con la mejora al máximo debe llegar a 0 (división por cero al disparar).
	NexusStats.mejora_cadencia = -99.0
	var suelo: float = NexusStats.get_cadencia_timer()
	_ok(suelo > 0.0, "el timer nunca llega a 0 (%.4f s)" % suelo)
	_ok(suelo >= 0.049, "respeta el suelo documentado de 0.05 s (%.4f)" % suelo)
	NexusStats.reiniciar_partida()


func _test_reinicio() -> void:
	_sec("Reinicio de partida")
	NexusStats.mult_danio = 5.0
	NexusStats.mejora_cadencia = -0.8
	NexusStats.mejora_multidisparo = 7
	NexusStats.escudo_actual = 500.0
	NexusStats.reiniciar_partida()
	_eq(NexusStats.mult_danio, 1.0, "el multiplicador de daño vuelve a la base")
	_eq(NexusStats.mejora_cadencia, 0.0, "la cadencia vuelve a la base")
	_eq(float(NexusStats.get_multidisparo()), 0.0, "el multidisparo vuelve a 0")
	_ok(NexusStats.salud_actual > 0.0, "arranca con salud")
	_eq(NexusStats.salud_actual, NexusStats.salud_base, "arranca a salud máxima")


# ═══════════════════════════════════════════════════
# ESPECTROS
# ═══════════════════════════════════════════════════
func _test_espectros() -> void:
	_sec("Espectros — configuración y daño")
	var escena: PackedScene = load("res://escenas/enemigos/Espectro.tscn")
	_ok(escena != null, "la escena del espectro carga")
	if escena == null:
		return

	var e: Node = escena.instantiate()
	add_child(e)
	await get_tree().process_frame

	var stats: Dictionary = EscaladoEnemigos.stats("tanque", 4)
	e.configurar(stats)
	_eq(e.salud_maxima, stats["hp"], "configurar aplica el HP escalado")
	_eq(e.salud_actual, e.salud_maxima, "arranca a vida completa")
	_eq(float(e.recompensa_energia), float(stats["recompensa"]), "aplica la recompensa")
	_ok(e.tipo_espectro == "tanque", "aplica el tipo")

	# Daño parcial.
	var mitad: float = e.salud_maxima / 2.0
	e.recibir_dano(mitad)
	_eq(e.salud_actual, e.salud_maxima - mitad, "el daño resta vida exacta")
	_ok(not e.esta_destruido, "sigue vivo a media vida")

	# Lentitud: frena, no acelera.
	e.aplicar_lentitud(0.5, 1.0)
	var m: float = e._mult_lentitud(0.016)
	_ok(m <= 1.0 and m >= 0.0, "la lentitud frena sin invertir el movimiento (x%.2f)" % m)

	e.queue_free()
	await get_tree().process_frame


func _test_espectro_muerte() -> void:
	_sec("Espectros — muerte")
	var escena: PackedScene = load("res://escenas/enemigos/Espectro.tscn")
	if escena == null:
		return
	var e: Node = escena.instantiate()
	add_child(e)
	await get_tree().process_frame
	e.configurar(EscaladoEnemigos.stats("basico", 0))

	var muertes: Array = []
	e.espectro_destruido.connect(func(_pos, _rec): muertes.append(1))

	e.recibir_dano(99999.0)
	await get_tree().process_frame
	_ok(e.esta_destruido, "muere al bajar de 0 de vida")
	_eq(float(muertes.size()), 1.0, "emite la señal de muerte una sola vez")

	# Rematar a un muerto no debe volver a puntuar (kills/ecos duplicados).
	e.recibir_dano(99999.0)
	e.recibir_dano(99999.0)
	await get_tree().process_frame
	_eq(float(muertes.size()), 1.0, "rematar a un espectro muerto no vuelve a puntuar")

	if is_instance_valid(e):
		e.queue_free()
	await get_tree().process_frame


# ═══════════════════════════════════════════════════
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
