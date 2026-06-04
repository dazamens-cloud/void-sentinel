extends Node
# ═══════════════════════════════════════════════════
# MEJORA MANAGER — Void Sentinel
# FASE 1: Bugfixes
#   - Eliminada llamada a test_costos() inexistente
#   - Completado _aplicar_mejora() con todas las mejoras
# ═══════════════════════════════════════════════════

signal mejora_comprada(mejora_id: String, nuevo_nivel: int)
signal mejoras_actualizadas

# Fase 2 del balance: daño y vida escalan MULTIPLICATIVAMENTE.
#   stat = base × FACTOR^nivel   (compuesto)
# Esto permite que el techo de ascensión suba con la meta-progresión del
# Nexo. El resto de mejoras siguen siendo aditivas/acotadas.
const FACTOR_MULTIPLICATIVO: float = 1.03
const MEJORAS_MULTIPLICATIVAS: Array = ["danio", "salud"]

var mejoras: Dictionary = {
	# ========== ATAQUE ==========
	"danio": {
		"nombre": "Daño",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 10,
		"max_nivel": 2000,
		"descripcion": "Aumenta el daño base del Nexus por nivel."
	},
	"velocidad_ataque": {
		"nombre": "Velocidad de Ataque",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": -0.01,
		"coste_base": 8,
		"max_nivel": 95,
		"min_valor": 0.05,
		"descripcion": "Reduce el tiempo entre disparos. Mínimo 0.05s."
	},
	"disparo_critico": {
		"nombre": "Disparo Crítico",
		"categoria": "ataque",
		"nivel": 0,
		"incremento_prob": 0.005,
		"incremento_danio": 0.25,
		"coste_base": 12,
		"max_nivel": 50,
		"descripcion": "Aumenta la probabilidad y el multiplicador de daño crítico."
	},
	"multidisparo": {
		"nombre": "Multidisparo",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 20,
		"max_nivel": 9,
		"descripcion": "Ataca a un enemigo cercano adicional al mismo tiempo por nivel."
	},
	"rebote": {
		"nombre": "Rebote",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 15,
		"max_nivel": 5,
		"descripcion": "Los proyectiles rebotan a otros enemigos cercanos."
	},
	"alcance_rebote": {
		"nombre": "Alcance de Rebote",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 30,
		"coste_base": 10,
		"max_nivel": 10,
		"descripcion": "Aumenta el radio de búsqueda del rebote en píxeles."
	},
	
	# ========== DEFENSA ==========
	"salud": {
		"nombre": "Salud",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 5,
		"coste_base": 10,
		"max_nivel": 2000,
		"descripcion": "Aumenta la salud máxima del Nexus."
	},
	"recuperacion": {
		"nombre": "Recuperación",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 0.1,
		"coste_base": 12,
		"max_nivel": 500,
		"descripcion": "Regenera salud por segundo de forma pasiva."
	},
	"escudo": {
		"nombre": "Escudo",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 5,
		"coste_base": 15,
		"max_nivel": 1000,
		"descripcion": "Añade una capa de escudo que absorbe daño."
	},
	"dureza_escudo": {
		"nombre": "Dureza del Escudo",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": -0.005,
		"coste_base": 15,
		"max_nivel": 150,
		"min_valor": 0.25,
		"descripcion": "Reduce el daño recibido. Máximo 75% de reducción."
	},
	"pulso_quartz": {
		"nombre": "Pulso de Quartz",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 40,
		"coste_base": 20,
		"max_nivel": 15,
		"descripcion": "Aumenta el radio del pulso expansivo defensivo."
	},
	"poder_pulso": {
		"nombre": "Poder del Pulso",
		"categoria": "defensa",
		"nivel": 0,
		"incremento_lentitud": 0.2,
		"incremento_empuje": 0.05,
		"coste_base": 25,
		"max_nivel": 20,
		"descripcion": "Aumenta la lentitud y fuerza de empuje del pulso."
	},
	
	# ========== BONIFICACIÓN ==========
	"energia_ascension": {
		"nombre": "Energía por Ascensión",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 2,
		"coste_base": 10,
		"max_nivel": 500,
		"descripcion": "Ganas más energía al completar cada ascensión."
	},
	"energia_espectro": {
		"nombre": "Energía por Espectro",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 8,
		"max_nivel": 100,
		"descripcion": "Ganas más energía por cada enemigo destruido."
	},
	"ecos_ascension": {
		"nombre": "Ecos por Ascensión",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 15,
		"max_nivel": 50,
		"descripcion": "Ganas más ecos al completar ascensiones."
	},
	"ecos_rapido": {
		"nombre": "Ecos Rápidos",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 20,
		"max_nivel": 35,
		"descripcion": "Probabilidad de obtener ecos extra por cada enemigo."
	},
	"mejora_ataque_gratis": {
		"nombre": "Ataque Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de que una mejora de ataque sea gratuita."
	},
	"mejora_defensa_gratis": {
		"nombre": "Defensa Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de que una mejora de defensa sea gratuita."
	},
	"mejora_bonificacion_gratis": {
		"nombre": "Bonificación Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de que una mejora de bonificación sea gratuita."
	},
	
	# ========== COMMANDER (bloqueado hasta desbloqueo) ==========
	"blindaje": {
		"nombre": "Blindaje",
		"categoria": "commander",
		"nivel": 0,
		"incremento": -0.05,
		"coste_base": 50,
		"max_nivel": 50,
		"min_valor": 0.5,
		"bloqueado": true,
		"descripcion": "Reduce el daño de los enemigos invocados por el Commander."
	},
	"disparos_iniciales": {
		"nombre": "Disparos Iniciales",
		"categoria": "commander",
		"nivel": 0,
		"incremento": 0.02,
		"coste_base": 40,
		"max_nivel": 25,
		"max_valor": 0.5,
		"bloqueado": true,
		"descripcion": "Probabilidad de disparo extra al detectar al Commander."
	},
	"recarga_rapida": {
		"nombre": "Recarga Rápida",
		"categoria": "commander",
		"nivel": 0,
		"incremento": -1,
		"coste_base": 60,
		"max_nivel": 7,
		"min_valor": 3,
		"bloqueado": true,
		"descripcion": "Reduce los enemigos necesarios para activar el disparo especial."
	},
	"lock_on": {
		"nombre": "Lock-On",
		"categoria": "commander",
		"nivel": 0,
		"incremento": 0.2,
		"coste_base": 45,
		"max_nivel": 20,
		"bloqueado": true,
		"descripcion": "Aumenta el tiempo de retención del objetivo contra el Commander."
	}
}

# ═══════════════════════════════════════════════════
func _ready() -> void:
	# Cada mejora lleva dos contadores:
	#   - "nivel_nexo": nivel PERMANENTE comprado en el Nexo con ecos (suelo).
	#   - "nivel":      nivel EFECTIVO de la partida actual (suelo + compras
	#                   in-run con energía). Se resetea al suelo cada partida.
	for id in mejoras.keys():
		mejoras[id]["nivel_nexo"] = 0
	cargar_mejoras_nexo()

# ═══════════════════════════════════════════════════
# GETTERS
# ═══════════════════════════════════════════════════
func get_nivel(mejora_id: String) -> int:
	return mejoras.get(mejora_id, {}).get("nivel", 0)

func get_valor(mejora_id: String) -> float:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return 0.0
	var nivel = data["nivel"]
	
	match mejora_id:
		"disparo_critico":
			return nivel * data.get("incremento_prob", 0.0)
		"poder_pulso":
			return nivel * data.get("incremento_lentitud", 0.0)
	
	# Valor = delta acumulado (nivel × incremento).
	# El "suelo" de los stats con incremento NEGATIVO (velocidad_ataque,
	# dureza_escudo, blindaje, recarga_rapida) se aplica sobre el VALOR FINAL
	# en el consumidor (NexusStats / EspectroComander / SistemaDisparos),
	# NO sobre este delta — antes max(delta, min_valor) lo dejaba clavado
	# en min_valor para cualquier nivel.
	var valor: float = nivel * data.get("incremento", 0.0)
	# max_valor sí es un tope legítimo del propio valor (incrementos positivos).
	if data.has("max_valor"):
		valor = minf(valor, data["max_valor"])
	return valor

func get_valor_secundario(mejora_id: String) -> float:
	var data = mejoras.get(mejora_id, {})
	match mejora_id:
		"disparo_critico":
			return data.get("nivel", 0) * data.get("incremento_danio", 0.0)
		"poder_pulso":
			return data.get("nivel", 0) * data.get("incremento_empuje", 0.0)
	return 0.0

# Multiplicador compuesto de una mejora multiplicativa (danio/salud).
func get_multiplicador(mejora_id: String) -> float:
	return pow(FACTOR_MULTIPLICATIVO, get_nivel(mejora_id))

func get_coste(mejora_id: String) -> int:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return 0
	var factor: float = 1.09
	match data.get("categoria", ""):
		"ataque":       factor = 1.09
		"defensa":      factor = 1.08
		"bonificacion": factor = 1.11
		"commander":    factor = 1.12
	return int(data["coste_base"] * pow(factor, data["nivel"]))

# Coste en ECOS de la siguiente compra en el Nexo. Escala con el nivel
# PERMANENTE (nivel_nexo), no con el efectivo de la partida.
func get_coste_nexo(mejora_id: String) -> int:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return 0
	var factor: float = 1.09
	match data.get("categoria", ""):
		"ataque":       factor = 1.09
		"defensa":      factor = 1.08
		"bonificacion": factor = 1.11
		"commander":    factor = 1.12
	return int(data["coste_base"] * pow(factor, data.get("nivel_nexo", 0)))

func get_max_nivel(mejora_id: String) -> int:
	return mejoras.get(mejora_id, {}).get("max_nivel", 0)

func esta_bloqueada(mejora_id: String) -> bool:
	return mejoras.get(mejora_id, {}).get("bloqueado", false)

func puede_comprar(mejora_id: String) -> bool:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty(): return false
	if data["nivel"] >= data["max_nivel"]: return false
	if data.get("bloqueado", false): return false
	return Economia.energia >= get_coste(mejora_id)

# ═══════════════════════════════════════════════════
# COMPRAR
# ═══════════════════════════════════════════════════
func comprar_mejora(mejora_id: String, cantidad: int = 1) -> int:
	var compradas = 0
	for i in range(cantidad):
		if not puede_comprar(mejora_id):
			break
		var coste = get_coste(mejora_id)
		# Mejoras "gratis" (por categoría): probabilidad de no pagar el coste.
		if _es_compra_gratis(mejora_id):
			coste = 0
		if coste > 0 and not Economia.gastar_energia(coste):
			break
		mejoras[mejora_id]["nivel"] += 1
		compradas += 1
		_aplicar_mejora(mejora_id)
		mejora_comprada.emit(mejora_id, mejoras[mejora_id]["nivel"])
	if compradas > 0:
		mejoras_actualizadas.emit()
	return compradas

# Tira la probabilidad de "compra gratis" según la categoría de la mejora.
# Solo se evalúa cuando el jugador YA puede pagar (puede_comprar pasó), así
# que actúa como reembolso del coste, sin desincronizar la UI.
func _es_compra_gratis(mejora_id: String) -> bool:
	var cat: String = mejoras.get(mejora_id, {}).get("categoria", "")
	var prob: float = 0.0
	match cat:
		"ataque":       prob = get_valor("mejora_ataque_gratis")
		"defensa":      prob = get_valor("mejora_defensa_gratis")
		"bonificacion": prob = get_valor("mejora_bonificacion_gratis")
	return prob > 0.0 and randf() < prob

func _aplicar_mejora(mejora_id: String) -> void:
	# ═══════ ATAQUE ═══════
	match mejora_id:
		"danio":
			NexusStats.set_mult_danio(get_multiplicador(mejora_id))

		"velocidad_ataque":
			NexusStats.set_mejora_cadencia(get_valor(mejora_id))
		
		"disparo_critico":
			NexusStats.set_mejora_critico(
				get_valor(mejora_id),
				get_valor_secundario(mejora_id)  # factor base 1.5 ya en NexusStats; +1.5 lo duplicaba
			)
		
		"multidisparo":
			# ✅ FIX: ahora aplica correctamente al NexusStats
			if NexusStats.has_method("set_mejora_multidisparo"):
				NexusStats.set_mejora_multidisparo(int(get_valor(mejora_id)))
		
		"rebote":
			if NexusStats.has_method("set_mejora_rebote"):
				NexusStats.set_mejora_rebote(int(get_valor(mejora_id)), get_valor("alcance_rebote"))
		
		"alcance_rebote":
			# Se aplica junto con rebote
			if NexusStats.has_method("set_mejora_rebote"):
				NexusStats.set_mejora_rebote(int(get_valor("rebote")), get_valor(mejora_id))
		
		# ═══════ DEFENSA ═══════
		"salud":
			NexusStats.set_mult_salud(get_multiplicador(mejora_id))
		
		"recuperacion":
			NexusStats.set_mejora_regen(get_valor(mejora_id))
		
		"escudo":
			if NexusStats.has_method("set_mejora_escudo"):
				NexusStats.set_mejora_escudo(get_valor(mejora_id))
		
		"dureza_escudo":
			NexusStats.set_mejora_defensa(get_valor(mejora_id))
		
		"pulso_quartz":
			if NexusStats.has_method("set_mejora_pulso"):
				NexusStats.set_mejora_pulso(get_valor("pulso_quartz"), get_valor("poder_pulso"), get_valor_secundario("poder_pulso"))
		
		"poder_pulso":
			if NexusStats.has_method("set_mejora_pulso"):
				NexusStats.set_mejora_pulso(get_valor("pulso_quartz"), get_valor("poder_pulso"), get_valor_secundario("poder_pulso"))
		
		# ═══════ BONIFICACIÓN ═══════
		# Estas se leen bajo demanda por EconomiaEcos y Economia
		# No necesitan aplicarse inmediatamente a NexusStats
		"energia_ascension", "energia_espectro", \
		"ecos_ascension", "ecos_rapido", \
		"mejora_ataque_gratis", "mejora_defensa_gratis", "mejora_bonificacion_gratis":
			pass  # El sistema de Economía las consulta directamente con get_valor()
		
		# ═══════ COMMANDER ═══════
		"blindaje", "disparos_iniciales", "recarga_rapida", "lock_on":
			pass  # Bloqueadas — se implementarán al desbloquear Commander

func subir_nivel_nexo(mejora_id: String) -> void:
	# Compra PERMANENTE del Nexo (el pago en ecos ya lo procesó Economia).
	# Sube el suelo permanente y, de paso, el nivel efectivo actual.
	if not mejoras.has(mejora_id):
		return
	mejoras[mejora_id]["nivel_nexo"] = mejoras[mejora_id].get("nivel_nexo", 0) + 1
	mejoras[mejora_id]["nivel"] += 1
	_aplicar_mejora(mejora_id)
	guardar_mejoras_nexo()  # ✅ persistir inmediatamente (antes solo se guardaba en game over)
	mejora_comprada.emit(mejora_id, mejoras[mejora_id]["nivel"])
	mejoras_actualizadas.emit()

func reiniciar_mejoras_inrun() -> void:
	# Al empezar una partida el nivel efectivo NO vuelve a 0, sino al SUELO
	# permanente comprado en el Nexo. Así las mejoras del Nexo "ya están
	# compradas" al entrar al juego. Re-aplicamos cada una a NexusStats
	# (que mundo.gd acaba de resetear vía NexusStats.reiniciar_partida()).
	for id in mejoras.keys():
		mejoras[id]["nivel"] = mejoras[id].get("nivel_nexo", 0)
		_aplicar_mejora(id)
	mejoras_actualizadas.emit()

func reiniciar_mejoras() -> void:
	reiniciar_mejoras_inrun()

func guardar_mejoras_nexo() -> void:
	var datos: Dictionary = {}
	for id in mejoras.keys():
		var nn: int = mejoras[id].get("nivel_nexo", 0)
		if nn > 0:
			datos[id] = nn
	var file = FileAccess.open("user://nexo.save", FileAccess.WRITE)
	if file:
		file.store_var(datos)
		file.close()

func cargar_mejoras_nexo() -> void:
	if not FileAccess.file_exists("user://nexo.save"):
		return
	var file = FileAccess.open("user://nexo.save", FileAccess.READ)
	if not file:
		return
	var datos = file.get_var()
	file.close()
	if not datos is Dictionary:
		return
	for id in datos.keys():
		if mejoras.has(id):
			mejoras[id]["nivel_nexo"] = datos[id]
			mejoras[id]["nivel"] = datos[id]
			_aplicar_mejora(id)
	mejoras_actualizadas.emit()
