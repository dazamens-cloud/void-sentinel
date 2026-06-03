class_name Formato
extends RefCounted
# ═══════════════════════════════════════════════════
# FORMATO — Abreviación de números grandes (idle-style).
# Con el poder multiplicativo (fase 2) los stats llegan a millones,
# billones, etc. Las comas se vuelven ilegibles, así que abreviamos:
#   1500 → 1.5K   2_300_000 → 2.3M   ...
# ═══════════════════════════════════════════════════

const SUFIJOS: Array = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
]


# Abrevia un número con sufijo (1.23M). Por debajo de 1000 muestra el
# entero tal cual. Más allá de los sufijos, usa notación científica.
static func abreviar(n: float) -> String:
	var signo := "-" if n < 0 else ""
	n = absf(n)
	if n < 1000.0:
		return signo + str(int(round(n)))

	var idx := 0
	while n >= 1000.0 and idx < SUFIJOS.size() - 1:
		n /= 1000.0
		idx += 1

	if n >= 1000.0:
		# Por encima del último sufijo: notación científica compacta.
		return signo + ("%.2e" % (n * pow(1000.0, SUFIJOS.size() - 1)))

	var s := ("%.2f" % n).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	return signo + s + SUFIJOS[idx]
