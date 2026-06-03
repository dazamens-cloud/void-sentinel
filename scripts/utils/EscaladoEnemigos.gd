class_name EscaladoEnemigos
extends RefCounted
# ═══════════════════════════════════════════════════
# ESCALADO ENEMIGOS (Tier 1) — fuente ÚNICA de la dificultad.
#
# Antes las fórmulas estaban duplicadas en AscensionManager y en
# EspectroComander, y se desincronizaron (el Commander seguía usando el
# viejo exponencial 1.38 → invocados de millones de HP). Centralizado aquí
# para que TODO el que genere enemigos use exactamente la misma curva.
#
# Modelo POLINÓMICO (permite techo de miles de ascensiones; el exponencial
# se rompía sobre la asc 40):
#   vida       = base × (1+asc)^EXP_VIDA
#   ataque     = base × (1+asc)^EXP_ATAQUE
#   recompensa = base × (1+asc)^EXP_RECOMPENSA
#
# 👉 Tunea SOLO aquí. Sube EXP_VIDA para endurecer, bájalo para suavizar.
# ═══════════════════════════════════════════════════

const EXP_VIDA: float = 2.0
const EXP_ATAQUE: float = 1.25
const EXP_RECOMPENSA: float = 1.15

# Stats base por tipo (a ascensión 0).
const BASE := {
	"basico":    {"hp": 15.0,  "atk": 3.0, "spd": 100.0, "recompensa": 5},
	"tanque":    {"hp": 75.0,  "atk": 3.0, "spd": 60.0,  "recompensa": 15},
	"kamikaze":  {"hp": 10.0,  "atk": 6.0, "spd": 200.0, "recompensa": 8},
	"sniper":    {"hp": 12.0,  "atk": 4.5, "spd": 80.0,  "recompensa": 8},
	"jefe":      {"hp": 150.0, "atk": 6.0, "spd": 50.0,  "recompensa": 50},
	"commander": {"hp": 30.0,  "atk": 0.0, "spd": 100.0, "recompensa": 40},
}


static func vida(tipo: String, asc: int) -> float:
	var b: Dictionary = BASE.get(tipo, BASE["basico"])
	return b["hp"] * pow(asc + 1, EXP_VIDA)


static func ataque(tipo: String, asc: int) -> float:
	var b: Dictionary = BASE.get(tipo, BASE["basico"])
	return b["atk"] * pow(asc + 1, EXP_ATAQUE)


static func recompensa(tipo: String, asc: int) -> int:
	var b: Dictionary = BASE.get(tipo, BASE["basico"])
	return int(b["recompensa"] * pow(asc + 1, EXP_RECOMPENSA))


# Diccionario de stats listo para Espectro.configurar().
static func stats(tipo: String, asc: int) -> Dictionary:
	var b: Dictionary = BASE.get(tipo, BASE["basico"])
	return {
		"hp": b["hp"] * pow(asc + 1, EXP_VIDA),
		"atk": b["atk"] * pow(asc + 1, EXP_ATAQUE),
		"spd_px": b["spd"],
		"recompensa": int(b["recompensa"] * pow(asc + 1, EXP_RECOMPENSA)),
		"tipo": tipo,
	}
