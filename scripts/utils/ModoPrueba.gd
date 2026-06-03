extends Node
# ═══════════════════════════════════════════════════
# MODO PRUEBA — Void Sentinel  (solo para testing)
#
# Permite arrancar una partida simulando un estado avanzado (~Ascensión
# alta) con recursos y mejoras inyectados, para probar el endgame y el
# Commander sin tener que grindear desde cero.
#
# Flujo:
#   - HomeScreen pone `activo = true` y lanza la partida normal.
#   - mundo.gd, tras sus resets, llama aplicar() si `activo`.
#   - aplicar() inyecta energía/ecos/fragmentos, sube mejoras clave y
#     coloca numero_ascension en ASCENSION_INICIAL.
#   - Los ecos/fragmentos reales se RESTAURAN al terminar la partida
#     (juego_terminado) para no corromper el guardado del jugador.
#   - Durante una partida de prueba, la tecla C invoca al Commander
#     (gestionado en mundo.gd, validado con `partida_es_prueba`).
#
# ⚠ Ajusta las constantes a tu gusto. El escalado de enemigos vive en
#   AscensionManager (constantes EXP_*). Bajar ASCENSION_INICIAL hace la
#   prueba más fácil.
# ═══════════════════════════════════════════════════

const ASCENSION_INICIAL := 45
const ENERGIA_PRUEBA := 50000.0
const ECOS_PRUEBA := 5000
const FRAG_PRUEBA := 2000

# Niveles in-run que se inyectan a las mejoras clave (se recortan al
# max_nivel de cada una). No tocan el nivel permanente del Nexo.
const NIVELES_PRUEBA := {
	"danio": 220,
	"salud": 200,
	"velocidad_ataque": 60,
	"multidisparo": 9,
	"disparo_critico": 50,
	"escudo": 500,
	"dureza_escudo": 150,
	"recuperacion": 300,
	"rebote": 5,
	"alcance_rebote": 10,
	"energia_espectro": 80,
	"ecos_ascension": 30,
}

# Marca que la PRÓXIMA partida debe arrancar en modo prueba.
var activo: bool = false
# True mientras se juega una partida de prueba (gate para la tecla C).
var partida_es_prueba: bool = false

var _ecos_backup: int = 0
var _frag_backup: int = 0
var _restaurar: bool = false


# Lo llama mundo.gd tras los resets de partida.
func aplicar() -> void:
	activo = false
	partida_es_prueba = true

	# Recursos de partida.
	Economia.energia = ENERGIA_PRUEBA
	Economia.numero_ascension = ASCENSION_INICIAL

	# Inflar ecos/fragmentos para la prueba, guardando los reales para
	# restaurarlos al terminar.
	_ecos_backup = Economia.ecos
	_frag_backup = Economia.fragmentos
	Economia.ecos = max(Economia.ecos, ECOS_PRUEBA)
	Economia.fragmentos = max(Economia.fragmentos, FRAG_PRUEBA)
	_restaurar = true
	if not Economia.juego_terminado.is_connected(_on_juego_terminado):
		Economia.juego_terminado.connect(_on_juego_terminado)

	_subir_mejoras()

	# Refrescar HUD y stats.
	Economia.recursos_actualizados.emit()
	Economia.ecos_actualizados.emit()
	Economia.fragmentos_actualizados.emit()
	Economia.ascension_cambiada.emit(ASCENSION_INICIAL)
	NexusStats.stats_actualizadas.emit()
	print("🧪 MODO PRUEBA aplicado — Asc inicial ", ASCENSION_INICIAL)


func _subir_mejoras() -> void:
	for id in NIVELES_PRUEBA.keys():
		if not MejoraManager.mejoras.has(id):
			continue
		var maxn: int = MejoraManager.mejoras[id].get("max_nivel", 0)
		MejoraManager.mejoras[id]["nivel"] = min(NIVELES_PRUEBA[id], maxn)
		MejoraManager._aplicar_mejora(id)
	MejoraManager.mejoras_actualizadas.emit()


func _on_juego_terminado(_causa: String) -> void:
	partida_es_prueba = false
	if _restaurar:
		# Restaurar ecos/fragmentos reales (descartamos lo de la prueba).
		Economia.ecos = _ecos_backup
		Economia.fragmentos = _frag_backup
		Economia.guardar_datos()
		_restaurar = false
		print("🧪 MODO PRUEBA: ecos/fragmentos reales restaurados")
