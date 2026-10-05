extends Node
# ═══════════════════════════════════════════════════
# SIMULADOR DE BALANCE — Void Sentinel
#
# Juega partidas de verdad en headless, con el tiempo acelerado y una politica
# de compra programada, y apunta como acaban. NO es un modelo matematico del
# juego: monta `mundo.tscn` y deja correr los sistemas reales, para que los
# numeros no se separen del juego segun este evolucione.
#
# El balance real era el unico "?" grande del estado del proyecto: cuanto se
# tarda por ascension, de que se muere uno y si una politica de compra domina
# a las demas. Esto lo mide sin tener que jugarlo a mano.
#
#   godot --headless --path . tools/SimuladorBalance.tscn -- --partidas=5 --politica=bonus
#
# Argumentos (todos opcionales):
#   --partidas=N     cuantas partidas por politica (por defecto 3)
#   --politica=X     bonus | ataque | defensa | equilibrada | todas (por defecto todas)
#   --velocidad=N    aceleracion del tiempo (por defecto 5)
#   --tope=N         ascension a la que se corta la partida (por defecto 25)
#
# Deja `tools/balance/resultados.csv` con una fila por partida.
#
# ⚠ Toca user:// como cualquier partida: lanzalo con el guardado respaldado.
# ═══════════════════════════════════════════════════

const RUTA_MUNDO := "res://escenas/mundo.tscn"
const DIR_SALIDA := "res://tools/balance"

# Orden de compra de cada politica. Se compra lo primero que se pueda pagar,
# de arriba abajo, asi que el orden ES la estrategia.
const POLITICAS := {
	"bonus": [
		"energia_espectro", "energia_ascension", "interes_tasa", "interes_cap",
		"ecos_ascension", "salud", "recuperacion", "danio", "velocidad_ataque",
	],
	"ataque": [
		"danio", "velocidad_ataque", "disparo_critico", "multidisparo",
		"rebote", "salud", "energia_espectro",
	],
	"defensa": [
		"salud", "recuperacion", "escudo", "dureza_escudo", "blindaje",
		"danio", "energia_espectro",
	],
	"equilibrada": [
		"danio", "salud", "energia_espectro", "velocidad_ataque", "recuperacion",
		"interes_tasa", "disparo_critico", "escudo",
	],
}

var _partidas: int = 3
var _politicas: Array = []
var _velocidad: float = 5.0
var _tope_ascension: int = 25

var _filas: Array = []


func _ready() -> void:
	_leer_argumentos()
	print("═══ SIMULADOR DE BALANCE ═══")
	print("%d partidas por politica, hasta ascension %d, a x%.0f\n"
		% [_partidas, _tope_ascension, _velocidad])

	for politica in _politicas:
		for i in _partidas:
			var fila: Dictionary = await _jugar_partida(politica, i + 1)
			_filas.append(fila)
			print("  %-12s #%d -> asc %d, %s, %.0fs de juego"
				% [politica, i + 1, fila["ascension"], fila["causa"], fila["segundos"]])

	_escribir_csv()
	_resumen()
	get_tree().quit(0)


func _leer_argumentos() -> void:
	var politica := "todas"
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=")
		if partes.size() != 2:
			continue
		match partes[0]:
			"--partidas":  _partidas = maxi(1, int(partes[1]))
			"--politica":  politica = partes[1]
			"--velocidad": _velocidad = maxf(1.0, float(partes[1]))
			"--tope":      _tope_ascension = maxi(1, int(partes[1]))
	_politicas = POLITICAS.keys() if politica == "todas" else [politica]


# ═══════════════════════════════════════════════════
# UNA PARTIDA
# ═══════════════════════════════════════════════════
func _jugar_partida(politica: String, numero: int) -> Dictionary:
	# Estado limpio: la partida anterior no puede condicionar a la siguiente.
	Economia.iniciar_partida()
	NexusStats.reiniciar_partida()
	MejoraManager.reiniciar_mejoras_inrun()

	# En un array porque las lambdas de GDScript capturan los locales POR VALOR:
	# con un String, la lambda escribia en su copia y aqui nunca llegaba la causa.
	var fin := [false, ""]
	var cb := func(c: String):
		if not fin[0]:
			fin[0] = true
			fin[1] = c
	Economia.juego_terminado.connect(cb)

	# Al morir, el juego pausa el arbol para el game over: si no se quita, la
	# siguiente partida arranca congelada y se queda en ascension 0.
	get_tree().paused = false

	var mundo: Node = load(RUTA_MUNDO).instantiate()
	add_child(mundo)
	await get_tree().process_frame

	Engine.time_scale = _velocidad
	var compras: int = 0
	var t0 := Time.get_ticks_msec()
	var segundos_juego := 0.0
	var energia_total := 0.0
	var energia_previa := Economia.energia
	var ultima_asc: int = Economia.numero_ascension
	var t_ultimo_avance := Time.get_ticks_msec()

	while not fin[0] and Economia.numero_ascension < _tope_ascension:
		await get_tree().create_timer(0.25).timeout
		# Energia ganada (solo lo que sube, no lo que se gasta).
		if Economia.energia > energia_previa:
			energia_total += Economia.energia - energia_previa
		energia_previa = Economia.energia
		compras += _comprar(politica)
		# Cortafuegos: una partida que no avanza no puede comerse la tanda en
		# silencio. Se distingue "estancada" (la ascension no sube en 2 min) de
		# "tiempo agotado" (avanza, pero muy despacio).
		if Economia.numero_ascension != ultima_asc:
			ultima_asc = Economia.numero_ascension
			t_ultimo_avance = Time.get_ticks_msec()
		elif Time.get_ticks_msec() - t_ultimo_avance > 120000:
			fin[1] = "estancada"
			break
		if Time.get_ticks_msec() - t0 > 600000:
			fin[1] = "tiempo agotado"
			break

	Engine.time_scale = 1.0
	# El reloj de juego sale del reloj real por la aceleracion: el temporizador
	# del bucle ya corre en tiempo de juego, multiplicarlo lo contaba dos veces.
	segundos_juego = float(Time.get_ticks_msec() - t0) / 1000.0 * _velocidad
	var causa: String = fin[1]
	if causa == "":
		causa = "tope alcanzado"
	var fila := {
		"politica": politica,
		"partida": numero,
		"ascension": Economia.numero_ascension,
		"causa": causa,
		"segundos": segundos_juego,
		"compras": compras,
		"energia_total": energia_total,
		"salud_final": NexusStats.salud_actual,
	}

	if Economia.juego_terminado.is_connected(cb):
		Economia.juego_terminado.disconnect(cb)
	mundo.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	return fila


# Compra lo primero de la lista que se pueda pagar. Devuelve cuantos niveles
# se compraron en esta pasada.
func _comprar(politica: String) -> int:
	var comprados := 0
	for id in POLITICAS[politica]:
		if MejoraManager.esta_bloqueada(id):
			continue
		if not MejoraManager.puede_comprar(id):
			continue
		comprados += MejoraManager.comprar_mejora(id, 1)
	return comprados


# ═══════════════════════════════════════════════════
# SALIDA
# ═══════════════════════════════════════════════════
func _escribir_csv() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	var ruta := DIR_SALIDA + "/resultados.csv"
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	if not f:
		print("No se pudo escribir ", ruta)
		return
	f.store_line("politica,partida,ascension,causa,segundos,compras,energia_total,salud_final")
	for fila in _filas:
		f.store_line("%s,%d,%d,%s,%.0f,%d,%.0f,%.0f" % [
			fila["politica"], fila["partida"], fila["ascension"], fila["causa"],
			fila["segundos"], fila["compras"], fila["energia_total"], fila["salud_final"],
		])
	f.close()
	print("\nCSV en ", ProjectSettings.globalize_path(ruta))


func _resumen() -> void:
	print("\n── Resumen por politica")
	for politica in _politicas:
		var suyas := _filas.filter(func(f): return f["politica"] == politica)
		if suyas.is_empty():
			continue
		var asc := 0.0
		var seg := 0.0
		var causas := {}
		for f in suyas:
			asc += f["ascension"]
			seg += f["segundos"]
			causas[f["causa"]] = causas.get(f["causa"], 0) + 1
		print("   %-12s ascension media %.1f, %.0fs de juego, causas: %s"
			% [politica, asc / suyas.size(), seg / suyas.size(), causas])
	print("\nOjo: son partidas reales aceleradas. Si una politica gana por mucho,")
	print("es que esa rama domina y las demas decisiones pesan poco.")
