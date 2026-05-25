extends CharacterBody2D
# ═══════════════════════════════════════════════════
# ESPECTRO TANQUE — Enemigo resistente
# ═══════════════════════════════════════════════════

signal espectro_destruido(posicion: Vector2, recompensa: int)

var salud_maxima: float = 100.0
var salud_actual: float = 100.0
var velocidad: float = 48.0
var danio_ataque: float = 5.0
var recompensa_energia: int = 12
var tipo_espectro: String = "tanque"

const DISTANCIA_ATAQUE: float = 85.0
const INTERVALO_ATAQUE: float = 1.2
var temporizador_ataque: float = 0.0
var esta_destruido: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var nexus: Node2D = null

func _ready() -> void:
	add_to_group("espectros")
	await get_tree().process_frame
	nexus = get_tree().get_first_node_in_group("nexus")
	salud_actual = salud_maxima
	# ✅ Scale fijo AQUÍ — sprite ya existe después del await
	scale = Vector2.ONE * 1.2
	print("👾 Espectro creado. Tipo: tanque | Salud: ", salud_maxima)

func configurar(datos: Dictionary) -> void:
	salud_maxima = datos.get("hp", 100.0)
	salud_actual = salud_maxima
	velocidad = datos.get("spd_px", 48.0)
	danio_ataque = datos.get("atk", 5.0)
	recompensa_energia = datos.get("recompensa", 12)
	tipo_espectro = datos.get("tipo", "tanque")
	# ✅ Scale eliminado de aquí — sprite es null en este momento
	
