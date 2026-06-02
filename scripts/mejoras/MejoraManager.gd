extends Node
# ═══════════════════════════════════════════════════
# MEJORA MANAGER — Void Sentinel
# FASE 1: Bugfixes
#   - Eliminada llamada a test_costos() inexistente
#   - Completado _aplicar_mejora() con todas las mejoras
# ═══════════════════════════════════════════════════

signal mejora_comprada(mejora_id: String, nuevo_nivel: int)
signal mejoras_actualizadas

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
		"max_nivel": 65,
		"min_valor": 0.2,
		"descripcion": "Reduce el tiempo entre disparos. Mínimo 0.2s."
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
		"descripcion": "Dispara proyectiles adicionales por nivel."
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
		if not Economia.gastar_energia(coste):
			break
		mejoras[mejora_id]["nivel"] += 1
		compradas += 1
		_aplicar_mejora(mejora_id)
		mejora_comprada.emit(mejora_id, mejoras[mejora_id]["nivel"])
	if compradas > 0:
		mejoras_actualizadas.emit()
	return compradas

func _aplicar_mejora(mejora_id: String) -> void:
	# ═══════ ATAQUE ═══════
	match mejora_id:
		"danio":
			NexusStats.set_mejora_danio(get_valor(mejora_id))
		
		"velocidad_ataque":
			NexusStats.set_mejora_cadencia(get_valor(mejora_id))
		
		"disparo_critico":
			NexusStats.set_mejora_critico(
				get_valor(mejora_id),
				get_valor_secundario(mejora_id) + 1.5
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
			NexusStats.set_mejora_salud(get_valor(mejora_id), NexusStats.mejora_regeneracion)
		
		"recuperacion":
			NexusStats.set_mejora_salud(NexusStats.mejora_salud_extra, get_valor(mejora_id))
		
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
	# Para compras del Nexo (el pago en ecos ya fue procesado por Economia)
	if not mejoras.has(mejora_id):
		return
	mejoras[mejora_id]["nivel"] += 1
	_aplicar_mejora(mejora_id)
	mejora_comprada.emit(mejora_id, mejoras[mejora_id]["nivel"])
	mejoras_actualizadas.emit()

func reiniciar_mejoras_inrun() -> void:
	var categorias_inrun = ["ataque", "defensa", "bonificacion"]
	for id in mejoras.keys():
		if mejoras[id].get("categoria", "") in categorias_inrun:
			mejoras[id]["nivel"] = 0
	mejoras_actualizadas.emit()

func reiniciar_mejoras() -> void:
	reiniciar_mejoras_inrun()

func guardar_mejoras_nexo() -> void:
	var datos: Dictionary = {}
	for id in mejoras.keys():
		if mejoras[id]["nivel"] > 0:
			datos[id] = mejoras[id]["nivel"]
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
			mejoras[id]["nivel"] = datos[id]
			_aplicar_mejora(id)
	mejoras_actualizadas.emit()
