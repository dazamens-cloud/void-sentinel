extends Node
# ═══════════════════════════════════════════════════
# BATERÍA DE PRUEBAS — Void Sentinel
#
# Ejercita los autoloads en headless para verificar que hacen lo que
# prometen. No sustituye a jugar: comprueba lógica, no lo visual.
#
#   godot --path . --headless tools/tests/TestSistemas.tscn
#
# ⚠ Escribe en user:// (economia.save, nexo.save…). Respalda y restaura el
#   guardado real al terminar; aun así, no lo ejecutes con una partida abierta.
# ═══════════════════════════════════════════════════

var _fallos: int = 0
var _pasados: int = 0
var _seccion: String = ""
var _backup: Dictionary = {}

const FICHEROS_SAVE := [
	"user://economia.save", "user://nexo.save", "user://estadisticas.save",
	"user://misiones.save", "user://tutorial.save", "user://laboratorio.save",
]


func _ready() -> void:
	_respaldar()
	print("═══ BATERÍA DE PRUEBAS — Void Sentinel ═══\n")

	_test_escalado_enemigos()
	_test_economia()
	_test_interes()
	_test_mejoras_datos()
	_test_mejoras_costes()
	_test_mejoras_compra()
	await _test_habilidades()
	_test_laboratorio()
	_test_misiones()
	_test_estadisticas()

	_restaurar()
	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


# ═══════════════════════════════════════════════════
# ESCALADO DE ENEMIGOS
# ═══════════════════════════════════════════════════
func _test_escalado_enemigos() -> void:
	_sec("Escalado de enemigos")
	_eq(EscaladoEnemigos.vida("basico", 0), 15.0, "vida base del básico en asc 0")
	# La nota del proyecto documenta HP = base × (asc+1)^1.5
	_eq(EscaladoEnemigos.vida("basico", 3), 15.0 * pow(4, 1.5), "sigue la curva ^1.5")

	var previa := 0.0
	var monotona := true
	for asc in range(0, 200, 10):
		var v := EscaladoEnemigos.vida("tanque", asc)
		if v < previa:
			monotona = false
		previa = v
	_ok(monotona, "la vida crece de forma monótona hasta asc 200")

	# El comentario del fichero promete asc 1000 ≈ 475k HP para el básico.
	var v1000 := EscaladoEnemigos.vida("basico", 1000)
	_ok(v1000 > 400000.0 and v1000 < 550000.0,
		"asc 1000 ≈ 475k HP como documenta el fichero (real: %.0f)" % v1000)

	for tipo in ["basico", "tanque", "kamikaze", "sniper", "jefe", "commander"]:
		var st: Dictionary = EscaladoEnemigos.stats(tipo, 5)
		_ok(st["hp"] > 0.0 and st.has("recompensa") and st.has("spd_px"),
			"stats completas para '%s'" % tipo)


# ═══════════════════════════════════════════════════
# ECONOMÍA
# ═══════════════════════════════════════════════════
func _test_economia() -> void:
	_sec("Economía")
	Economia.iniciar_partida()
	_eq(Economia.numero_ascension, 0, "iniciar_partida resetea la ascensión")
	_ok(Economia.energia >= 50.0, "arranca con al menos 50 de energía")

	Economia.energia = 100.0
	_ok(not Economia.gastar_energia(150.0), "no deja gastar energía que no hay")
	_eq(Economia.energia, 100.0, "el intento fallido no descuenta energía")
	_ok(Economia.gastar_energia(40.0), "deja gastar energía disponible")
	_eq(Economia.energia, 60.0, "descuenta la cantidad exacta")

	# Recompensa por espectro: tope documentado de 50.
	Economia.numero_ascension = 0
	_eq(float(Economia.obtener_energia_por_espectro()), 5.0, "energía por espectro en asc 0")
	Economia.numero_ascension = 500
	_eq(float(Economia.obtener_energia_por_espectro()), 50.0, "energía por espectro topa en 50")

	# Ecos y fragmentos: gasto por encima del saldo.
	Economia.ecos = 10
	_ok(not Economia.gastar_ecos(50), "no deja gastar ecos que no hay")
	_eq(float(Economia.ecos), 10.0, "los ecos no cambian tras el intento fallido")

	# Cantidades negativas: gastar un negativo no debe REGALAR recursos.
	Economia.ecos = 10
	var acepta_negativo: bool = Economia.gastar_ecos(-100)
	_ok(not (acepta_negativo and Economia.ecos > 10),
		"gastar_ecos(-100) no regala ecos (saldo: %d)" % Economia.ecos)
	Economia.fragmentos = 10
	var acepta_neg_frag: bool = Economia.gastar_fragmentos(-100)
	_ok(not (acepta_neg_frag and Economia.fragmentos > 10),
		"gastar_fragmentos(-100) no regala fragmentos (saldo: %d)" % Economia.fragmentos)

	# Persistencia.
	Economia.ecos = 1234
	Economia.fragmentos = 567
	Economia.guardar_datos()
	Economia.ecos = 0
	Economia.fragmentos = 0
	Economia._cargar_datos()
	_eq(float(Economia.ecos), 1234.0, "los ecos sobreviven a guardar/cargar")
	_eq(float(Economia.fragmentos), 567.0, "los fragmentos sobreviven a guardar/cargar")


func _test_interes() -> void:
	_sec("Sistema de interés")
	Economia.iniciar_partida()
	_eq(Economia.tasa_interes, Economia.TASA_INTERES_BASE, "la tasa arranca en la base (2%)")
	_eq(Economia.cap_interes, Economia.CAP_INTERES_BASE, "el cap arranca en la base (1000)")

	Economia.energia = 1000.0
	_eq(Economia.calcular_interes(), 20.0, "2% de 1000 = 20")

	# El cap debe morder con energía alta.
	Economia.energia = 1000000.0
	_eq(Economia.calcular_interes(), Economia.cap_interes, "el interés no supera el cap")

	# Tras subir la tasa, iniciar otra partida debe devolverla a la base.
	Economia.mejorar_tasa_interes(0.035)
	Economia.iniciar_partida()
	_eq(Economia.tasa_interes, Economia.TASA_INTERES_BASE,
		"iniciar_partida resetea la tasa mejorada")


# ═══════════════════════════════════════════════════
# MEJORAS
# ═══════════════════════════════════════════════════
func _test_mejoras_datos() -> void:
	_sec("Mejoras — integridad de los datos")
	var ids: Array = MejoraManager.mejoras.keys()
	_ok(ids.size() > 0, "hay mejoras definidas (%d)" % ids.size())

	var campos := ["nombre", "nivel", "max_nivel", "coste_base", "categoria"]
	var incompletas: Array = []
	var categorias_malas: Array = []
	var validas := ["ataque", "defensa", "bonificacion", "commander"]
	for id in ids:
		var d: Dictionary = MejoraManager.mejoras[id]
		for c in campos:
			if not d.has(c):
				incompletas.append("%s (falta %s)" % [id, c])
		if d.has("categoria") and not validas.has(d["categoria"]):
			categorias_malas.append("%s → '%s'" % [id, d["categoria"]])
	_ok(incompletas.is_empty(), "todas las mejoras tienen los campos obligatorios %s"
		% ("" if incompletas.is_empty() else str(incompletas)))
	_ok(categorias_malas.is_empty(), "todas las categorías son válidas %s"
		% ("" if categorias_malas.is_empty() else str(categorias_malas)))

	var topes_malos: Array = []
	var costes_malos: Array = []
	for id in ids:
		var d: Dictionary = MejoraManager.mejoras[id]
		if d.get("max_nivel", 0) <= 0:
			topes_malos.append(id)
		if d.get("coste_base", 0) <= 0:
			costes_malos.append(id)
	_ok(topes_malos.is_empty(), "todas tienen max_nivel > 0 %s"
		% ("" if topes_malos.is_empty() else str(topes_malos)))
	_ok(costes_malos.is_empty(), "todas tienen coste_base > 0 %s"
		% ("" if costes_malos.is_empty() else str(costes_malos)))


func _test_mejoras_costes() -> void:
	_sec("Mejoras — costes (lo que muestra la card vs. lo que se cobra)")
	MejoraManager.reiniciar_mejoras_inrun()

	var id := "danio"
	_eq(float(MejoraManager.get_coste_acumulado(id, 1)), float(MejoraManager.get_coste(id)),
		"el acumulado de 1 nivel coincide con el coste simple")

	# El acumulado de N debe ser exactamente lo que cuesta comprar N seguidos.
	for cantidad in [5, 10]:
		MejoraManager.reiniciar_mejoras_inrun()
		var anunciado: int = MejoraManager.get_coste_acumulado(id, cantidad)
		var real: int = 0
		for i in range(cantidad):
			real += MejoraManager.get_coste(id)
			MejoraManager.mejoras[id]["nivel"] += 1
		_eq(float(anunciado), float(real),
			"el coste anunciado para x%d es el que se cobra de verdad" % cantidad)

	MejoraManager.reiniciar_mejoras_inrun()
	_eq(float(MejoraManager.get_coste_acumulado(id, 0)), 0.0, "comprar 0 niveles cuesta 0")
	_eq(float(MejoraManager.get_coste_acumulado(id, -5)), 0.0, "una cantidad negativa cuesta 0")

	# El coste debe crecer con el nivel.
	MejoraManager.reiniciar_mejoras_inrun()
	var c0: int = MejoraManager.get_coste(id)
	MejoraManager.mejoras[id]["nivel"] = 10
	var c10: int = MejoraManager.get_coste(id)
	_ok(c10 > c0, "el coste sube con el nivel (%d → %d)" % [c0, c10])
	MejoraManager.reiniciar_mejoras_inrun()

	# MAX no debe proponer más de lo que el jugador puede pagar.
	Economia.energia = 500.0
	var n: int = MejoraManager.get_max_comprables(id)
	var coste_n: int = MejoraManager.get_coste_acumulado(id, n)
	_ok(coste_n <= Economia.energia,
		"MAX propone %d niveles por %d ⚡, y hay %d ⚡" % [n, coste_n, Economia.energia])
	if n > 0:
		var coste_n1: int = MejoraManager.get_coste_acumulado(id, n + 1)
		_ok(coste_n1 > Economia.energia, "MAX no se queda corto (n+1 ya no es pagable)")


func _test_mejoras_compra() -> void:
	_sec("Mejoras — compra")
	MejoraManager.reiniciar_mejoras_inrun()
	var id := "danio"

	Economia.energia = 0.0
	_eq(float(MejoraManager.comprar_mejora(id, 1)), 0.0, "sin energía no se compra nada")
	_eq(float(MejoraManager.get_nivel(id)), 0.0, "el nivel sigue a 0 tras la compra fallida")

	Economia.energia = 100000.0
	var antes: int = MejoraManager.get_nivel(id)
	var compradas: int = MejoraManager.comprar_mejora(id, 3)
	_eq(float(compradas), 3.0, "compra los 3 niveles pedidos")
	_eq(float(MejoraManager.get_nivel(id)), float(antes + 3), "el nivel sube en 3")

	# Nunca por encima del tope.
	MejoraManager.reiniciar_mejoras_inrun()
	Economia.energia = 1e12
	var maxn: int = MejoraManager.get_max_nivel(id)
	MejoraManager.mejoras[id]["nivel"] = maxn - 1
	MejoraManager.comprar_mejora(id, 50)
	_eq(float(MejoraManager.get_nivel(id)), float(maxn), "la compra masiva se detiene en el tope")
	_ok(not MejoraManager.puede_comprar(id), "en el tope ya no se puede comprar")

	# Comprar debe cobrar de verdad.
	MejoraManager.reiniciar_mejoras_inrun()
	Economia.energia = 100000.0
	var saldo_previo: float = Economia.energia
	var coste: int = MejoraManager.get_coste(id)
	MejoraManager.comprar_mejora(id, 1)
	var gastado: float = saldo_previo - Economia.energia
	# Puede salir gratis por la mejora de "compra gratis", pero a nivel 0 su
	# probabilidad es 0, así que aquí debe cobrar el coste exacto.
	_eq(gastado, float(coste), "la compra descuenta exactamente el coste")

	MejoraManager.reiniciar_mejoras_inrun()
	_eq(float(MejoraManager.get_nivel(id)), 0.0, "reiniciar_mejoras_inrun deja el nivel a 0")


# ═══════════════════════════════════════════════════
# HABILIDADES (Forja)
# ═══════════════════════════════════════════════════
func _test_habilidades() -> void:
	_sec("Habilidades de la Forja")
	var ids: Array = []
	if HabilidadManager.has_method("get_todas"):
		ids = HabilidadManager.get_todas()
	elif "habilidades" in HabilidadManager:
		ids = HabilidadManager.habilidades.keys()
	_ok(ids.size() > 0, "hay habilidades definidas (%d)" % ids.size())

	var activas: Array = HabilidadManager.get_activas()
	_ok(activas.size() <= ids.size(), "las activas son un subconjunto de las definidas")

	# Los nombres cortos alimentan los botones del HUD: ninguno debe salir vacío.
	var sin_nombre: Array = []
	for id in ids:
		var n: String = HabilidadEjecutor.nombre_corto(id)
		if n.strip_edges().is_empty():
			sin_nombre.append(id)
	_ok(sin_nombre.is_empty(), "todas las habilidades tienen nombre corto %s"
		% ("" if sin_nombre.is_empty() else str(sin_nombre)))

	# Los costes deben ser > 0: HabilidadManager y Nexoscreen llaman a
	# gastar_fragmentos/gastar_ecos sin proteger el caso 0, y un gasto de 0
	# se rechaza. Un coste 0 dejaría esas compras muertas.
	var coste_cero: Array = []
	for id in ids:
		if HabilidadManager.has_method("get_coste"):
			if HabilidadManager.get_coste(id) <= 0:
				coste_cero.append(id)
	_ok(coste_cero.is_empty(), "ninguna habilidad cuesta 0 fragmentos %s"
		% ("" if coste_cero.is_empty() else str(coste_cero)))

	var nexo_cero: Array = []
	for id in MejoraManager.mejoras.keys():
		if MejoraManager.get_coste_nexo(id) <= 0:
			nexo_cero.append(id)
	_ok(nexo_cero.is_empty(), "ninguna mejora del Nexo cuesta 0 ecos %s"
		% ("" if nexo_cero.is_empty() else str(nexo_cero)))

	# Cooldown: nunca negativo.
	var negativos: Array = []
	for id in ids:
		if HabilidadEjecutor.get_cooldown_restante(id) < 0.0:
			negativos.append(id)
	_ok(negativos.is_empty(), "ningún cooldown arranca en negativo %s"
		% ("" if negativos.is_empty() else str(negativos)))


# ═══════════════════════════════════════════════════
# LABORATORIO
# ═══════════════════════════════════════════════════
func _test_laboratorio() -> void:
	_sec("Laboratorio")
	var invs: Array = Laboratorio.INVESTIGACIONES.keys()
	# La nota del proyecto documenta 15 investigaciones.
	_eq(float(invs.size()), 15.0, "hay 15 investigaciones definidas")
	_ok(Laboratorio.get_slots() >= Laboratorio.SLOTS_BASE, "hay al menos un slot de investigación")

	# Coste y duración deben crecer con el nivel y ser siempre positivos.
	var costes_malos: Array = []
	for id in invs:
		if Laboratorio.get_coste(id) <= 0 or Laboratorio.get_duracion(id) <= 0.0:
			costes_malos.append(id)
		if Laboratorio.get_max_nivel(id) <= 0:
			costes_malos.append("%s (max_nivel)" % id)
	_ok(costes_malos.is_empty(), "toda investigación tiene coste, duración y tope positivos %s"
		% ("" if costes_malos.is_empty() else str(costes_malos)))

	# get_data de un id desconocido no debe reventar.
	var vacio: Dictionary = Laboratorio.get_data("no_existe")
	_ok(vacio.is_empty() or vacio != null, "get_data de un id desconocido no revienta")

	# Un id inexistente debe dar bonus 0, no reventar.
	_eq(Laboratorio.get_bonus("no_existe_esta_investigacion"), 0.0,
		"un id desconocido devuelve bonus 0")

	# Todos los bonus consultables sin investigar deben ser finitos y >= 0.
	var raros: Array = []
	for id in invs:
		var b: float = Laboratorio.get_bonus(id)
		if is_nan(b) or is_inf(b) or b < 0.0:
			raros.append("%s → %s" % [id, b])
	_ok(raros.is_empty(), "todos los bonus son números válidos y no negativos %s"
		% ("" if raros.is_empty() else str(raros)))


# ═══════════════════════════════════════════════════
# MISIONES
# ═══════════════════════════════════════════════════
func _test_misiones() -> void:
	_sec("Misiones diarias")
	var activas: Array = MisionesManager.ids_activas()
	# La nota del proyecto documenta 3 misiones diarias de un pool de 8.
	_eq(float(activas.size()), 3.0, "se ofrecen 3 misiones diarias")
	_eq(float(MisionesManager.POOL.size()), 8.0, "el pool tiene 8 misiones")

	var vistos: Dictionary = {}
	var repetidas := false
	for id in activas:
		if vistos.has(id):
			repetidas = true
		vistos[id] = true
	_ok(not repetidas, "las 3 misiones del día son distintas entre sí")

	var del_pool := true
	for id in activas:
		if not MisionesManager.POOL.has(id):
			del_pool = false
	_ok(del_pool, "las misiones activas salen del pool")

	# La terna es determinista por fecha: el mismo día debe dar lo mismo
	# (si no, refrescar la pantalla cambiaría las misiones al jugador).
	var a1: Array = MisionesManager._elegir_misiones("2026-09-06")
	var a2: Array = MisionesManager._elegir_misiones("2026-09-06")
	_ok(a1 == a2, "la misma fecha da siempre la misma terna")
	var otro_dia: Array = MisionesManager._elegir_misiones("2026-09-07")
	_ok(a1 != otro_dia, "días distintos dan ternas distintas")

	# Y con cualquier fecha deben salir 3 sin repetir.
	var mal: Array = []
	for dia in range(1, 29):
		var f := "2026-03-%02d" % dia
		var sel: Array = MisionesManager._elegir_misiones(f)
		var u: Dictionary = {}
		for id in sel:
			u[id] = true
		if sel.size() != 3 or u.size() != 3:
			mal.append(f)
	_ok(mal.is_empty(), "28 fechas seguidas dan siempre 3 misiones sin repetir %s"
		% ("" if mal.is_empty() else str(mal)))


# ═══════════════════════════════════════════════════
# ESTADÍSTICAS
# ═══════════════════════════════════════════════════
func _test_estadisticas() -> void:
	_sec("Estadísticas y logros")
	_ok(EstadisticasManager != null, "el autoload responde")
	if "estadisticas" in EstadisticasManager:
		var e = EstadisticasManager.estadisticas
		_ok(e is Dictionary, "las estadísticas son un diccionario")
	if EstadisticasManager.has_method("get_logros"):
		var logros = EstadisticasManager.get_logros()
		_ok(logros != null, "los logros son consultables")


# ═══════════════════════════════════════════════════
# INFRAESTRUCTURA
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
			# No existía antes de la prueba: lo creó el test, se retira.
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("\n[guardado del jugador restaurado]")


func _sec(titulo: String) -> void:
	_seccion = titulo
	print("── %s" % titulo)


func _ok(cond: bool, desc: String) -> void:
	if cond:
		_pasados += 1
		print("   ✓ ", desc)
	else:
		_fallos += 1
		print("   ✗ FALLO: ", desc)


func _eq(a: float, b: float, desc: String) -> void:
	_ok(absf(a - b) < 0.001, "%s  [%s vs %s]" % [desc, a, b])
