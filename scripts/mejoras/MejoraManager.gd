extends Node
# ═══════════════════════════════════════════════════
# MEJORA MANAGER — Gestiona todas las mejoras in-game
# ═══════════════════════════════════════════════════

signal mejora_comprada(mejora_id: String, nuevo_nivel: int)
signal mejoras_actualizadas

# ── Datos de mejoras ────────────────────────────────────
var mejoras: Dictionary = {
	# ========== ATAQUE ==========
	"danio": {
		"nombre": "Daño",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 10,
		"max_nivel": 2000,
		"descripcion": "Aumenta el daño del Nexus"
	},
	"velocidad_ataque": {
		"nombre": "Velocidad de Ataque",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": -0.01,
		"coste_base": 8,
		"max_nivel": 65,
		"min_valor": 0.2,
		"descripcion": "Reduce el tiempo entre disparos"
	},
	"disparo_critico": {
		"nombre": "Disparo Crítico",
		"categoria": "ataque",
		"nivel": 0,
		"incremento_prob": 0.005,
		"incremento_danio": 0.25,
		"coste_base": 12,
		"max_nivel": 50,
		"descripcion": "Aumenta probabilidad y daño crítico"
	},
	"multidisparo": {
		"nombre": "Multidisparo",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 20,
		"max_nivel": 9,
		"descripcion": "Dispara proyectiles adicionales"
	},
	"rebote": {
		"nombre": "Rebote",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 15,
		"max_nivel": 5,
		"descripcion": "Los proyectiles rebotan a otros enemigos"
	},
	"alcance_rebote": {
		"nombre": "Alcance de Rebote",
		"categoria": "ataque",
		"nivel": 0,
		"incremento": 30,
		"coste_base": 10,
		"max_nivel": 10,
		"descripcion": "Aumenta la distancia de rebote"
	},
	
	# ========== DEFENSA ==========
	"salud": {
		"nombre": "Salud",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 5,
		"coste_base": 10,
		"max_nivel": 2000,
		"descripcion": "Aumenta la salud máxima del Nexus"
	},
	"recuperacion": {
		"nombre": "Recuperación",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 0.1,
		"coste_base": 12,
		"max_nivel": 500,
		"descripcion": "Regenera salud por segundo"
	},
	"escudo": {
		"nombre": "Escudo",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 5,
		"coste_base": 15,
		"max_nivel": 1000,
		"descripcion": "Añade una capa extra de vida"
	},
	"dureza_escudo": {
		"nombre": "Dureza del Escudo",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": -0.005,
		"coste_base": 15,
		"max_nivel": 150,
		"min_valor": 0.25,
		"descripcion": "Reduce el daño recibido"
	},
	"pulso_quartz": {
		"nombre": "Pulso de Quartz",
		"categoria": "defensa",
		"nivel": 0,
		"incremento": 40,
		"coste_base": 20,
		"max_nivel": 15,
		"descripcion": "Aumenta el radio del pulso expansivo"
	},
	"poder_pulso": {
		"nombre": "Poder del Pulso",
		"categoria": "defensa",
		"nivel": 0,
		"incremento_lentitud": 0.2,
		"incremento_empuje": 0.05,
		"coste_base": 25,
		"max_nivel": 20,
		"descripcion": "Aumenta lentitud y fuerza de empuje"
	},
	
	# ========== BONIFICACIÓN ==========
	"energia_ascension": {
		"nombre": "Energía por Ascensión",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 2,
		"coste_base": 10,
		"max_nivel": 500,
		"descripcion": "Ganas más energía al completar ascensiones"
	},
	"energia_espectro": {
		"nombre": "Energía por Espectro",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 8,
		"max_nivel": 100,
		"descripcion": "Ganas más energía por cada enemigo destruido"
	},
	"ecos_ascension": {
		"nombre": "Ecos por Ascensión",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 1,
		"coste_base": 15,
		"max_nivel": 50,
		"descripcion": "Ganas más ecos al completar ascensiones"
	},
	"ecos_rapido": {
		"nombre": "Ecos Rápidos",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 20,
		"max_nivel": 35,
		"descripcion": "Probabilidad de obtener ecos por cada enemigo"
	},
	"mejora_ataque_gratis": {
		"nombre": "Ataque Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de mejora de ataque gratuita"
	},
	"mejora_defensa_gratis": {
		"nombre": "Defensa Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de mejora de defensa gratuita"
	},
	"mejora_bonificacion_gratis": {
		"nombre": "Bonificación Gratis",
		"categoria": "bonificacion",
		"nivel": 0,
		"incremento": 0.01,
		"coste_base": 30,
		"max_nivel": 25,
		"descripcion": "Probabilidad de mejora de bonificación gratuita"
	},
	
	# ========== COMMANDER (bloqueado) ==========
	"blindaje": {
		"nombre": "Blindaje",
		"categoria": "commander",
		"nivel": 0,
		"incremento": -0.01,
		"coste_base": 50,
		"max_nivel": 50,
		"min_valor": 0.5,
		"bloqueado": true,
		"descripcion": "Reduce el daño de enemigos invocados por Commander"
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
		"descripcion": "Probabilidad de disparo extra contra Commander"
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
		"descripcion": "Reduce enemigos necesarios para disparo especial"
	},
	"lock_on": {
		"nombre": "Lock-On",
		"categoria": "commander",
		"nivel": 0,
		"incremento": 0.2,
		"coste_base": 45,
		"max_nivel": 20,
		"bloqueado": true,
		"descripcion": "Aumenta tiempo de retención del objetivo"
	}
}

# ═══════════════════════════════════════════════════
func _ready() -> void:
	Economia.energia_cambiada.connect(_on_energia_cambiada)
	call_deferred("test_costos")

# ═══════════════════════════════════════════════════
# GETTERS
# ═══════════════════════════════════════════════════
func get_nivel(mejora_id: String) -> int:
	if mejoras.has(mejora_id):
		return mejoras[mejora_id]["nivel"]
	return 0

func get_valor(mejora_id: String) -> float:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return 0.0
	
	var nivel = data["nivel"]
	var valor = nivel * data.get("incremento", 0.0)
	
	# Casos especiales
	if mejora_id == "disparo_critico":
		var prob = nivel * data.get("incremento_prob", 0.0)
		var danio = nivel * data.get("incremento_danio", 0.0)
		return prob  # Para mostrar, pero se maneja aparte
	if mejora_id == "poder_pulso":
		return nivel * data.get("incremento_lentitud", 0.0)
	
	if data.has("min_valor"):
		valor = max(valor, data["min_valor"])
	if data.has("max_valor"):
		valor = min(valor, data["max_valor"])
	
	return valor

func get_valor_secundario(mejora_id: String) -> float:
	var data = mejoras.get(mejora_id, {})
	if mejora_id == "disparo_critico":
		return data.get("nivel", 0) * data.get("incremento_danio", 0.0)
	if mejora_id == "poder_pulso":
		return data.get("nivel", 0) * data.get("incremento_empuje", 0.0)
	return 0.0

func get_coste(mejora_id: String) -> int:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return 0
	
	var coste_base: int = data["coste_base"]
	var nivel: int = data["nivel"]
	
	# Factor exponencial por categoría (9% base por nivel)
	var factor: float = 1.09
	match data.get("categoria", ""):
		"ataque":      factor = 1.09
		"defensa":     factor = 1.08  # Ligeramente más barata
		"bonificacion": factor = 1.11 # Ligeramente más cara
		"commander":   factor = 1.12  # La más cara
		"interes":     factor = 1.10  # Para cuando lo añadamos
	
	return int(coste_base * pow(factor, nivel))
	
func get_max_nivel(mejora_id: String) -> int:
	var data = mejoras.get(mejora_id, {})
	return data.get("max_nivel", 0)

func esta_bloqueada(mejora_id: String) -> bool:
	var data = mejoras.get(mejora_id, {})
	return data.get("bloqueado", false)

func puede_comprar(mejora_id: String) -> bool:
	var data = mejoras.get(mejora_id, {})
	if data.is_empty():
		return false
	if data["nivel"] >= data["max_nivel"]:
		return false
	if data.get("bloqueado", false):
		return false
	return Economia.energia >= get_coste(mejora_id)

# ═══════════════════════════════════════════════════
# COMPRAR MEJORAS
# ═══════════════════════════════════════════════════
func comprar_mejora(mejora_id: String, cantidad: int = 1) -> int:
	var compradas = 0
	for i in range(cantidad):
		if not puede_comprar(mejora_id):
			break
		
		var coste = get_coste(mejora_id)
		if not Economia.gastar_energia(coste):
			break
		
		var data = mejoras[mejora_id]
		data["nivel"] += 1
		compradas += 1
		
		print("✅ Mejora: ", data["nombre"], " → Nivel ", data["nivel"])
		
		# Aplicar efectos inmediatos
		_aplicar_mejora(mejora_id)
		
		mejora_comprada.emit(mejora_id, data["nivel"])
	
	if compradas > 0:
		mejoras_actualizadas.emit()
	
	return compradas

func _aplicar_mejora(mejora_id: String) -> void:
	match mejora_id:
		"danio":
			var extra = get_valor(mejora_id)
			NexusStats.set_mejora_danio(extra)
		"velocidad_ataque":
			var valor = get_valor(mejora_id)
			NexusStats.set_mejora_cadencia(valor)
		"disparo_critico":
			var prob = get_valor(mejora_id)
			var factor = get_valor_secundario(mejora_id) + 1.5
			NexusStats.set_mejora_critico(prob, factor)
		"salud":
			var extra = get_valor(mejora_id)
			NexusStats.set_mejora_salud(extra, NexusStats.mejora_regeneracion)
		"recuperacion":
			var extra = get_valor(mejora_id)
			NexusStats.set_mejora_salud(NexusStats.mejora_salud_extra, extra)
		"dureza_escudo":
			var valor = get_valor(mejora_id)
			NexusStats.set_mejora_defensa(valor)

func reiniciar_mejoras() -> void:
	for mejora_id in mejoras.keys():
		mejoras[mejora_id]["nivel"] = 0
	print("🔄 Mejoras reiniciadas")
	mejoras_actualizadas.emit()

# ═══════════════════════════════════════════════════
func _on_energia_cambiada(nueva_energia: float) -> void:
	mejoras_actualizadas.emit()
	
