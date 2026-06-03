extends Node
# ═══════════════════════════════════════════════════
# REANUDAR PARTIDA — checkpoint de la run en curso (autoload).
#
# Al "Salir al menú" se guarda el estado de la partida (ascensión, energía,
# salud del Nexo, niveles in-run de las mejoras y stats acumuladas). El menú
# detecta el guardado y ofrece "REANUDAR"; al reanudar, mundo.gd restaura ese
# estado tras sus resets (mismo patrón que ModoPrueba).
#
# NO se restauran los espectros en pantalla: la oleada arranca de nuevo.
# El guardado se "consume" al reanudar y se borra al terminar la partida
# (game over) o al empezar una partida nueva.
# ═══════════════════════════════════════════════════

const RUTA: String = "user://run.save"

# El menú la pone a true al pulsar REANUDAR; mundo.gd la lee en _ready.
var debe_reanudar: bool = false


func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA)


# Vuelca el estado de la run actual a disco.
func guardar() -> void:
	var niveles := {}
	for id in MejoraManager.mejoras.keys():
		niveles[id] = MejoraManager.mejoras[id].get("nivel", 0)

	var datos := {
		"energia": Economia.energia,
		"ascension": Economia.numero_ascension,
		"energia_total": Economia.energia_total_partida,
		"espectros_elim": Economia.espectros_eliminados,
		"salud": NexusStats.salud_actual,
		"niveles": niveles,
	}
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_var(datos)
		f.close()
		print("💾 Run guardada (Asc ", Economia.numero_ascension, ")")


func borrar() -> void:
	debe_reanudar = false
	if FileAccess.file_exists(RUTA):
		var d := DirAccess.open("user://")
		if d:
			d.remove("run.save")


# Restaura el estado guardado SOBRE los resets que ya hizo mundo.gd.
func aplicar() -> void:
	debe_reanudar = false
	if not FileAccess.file_exists(RUTA):
		return
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if not f:
		return
	var datos = f.get_var()
	f.close()
	if not (datos is Dictionary):
		return

	Economia.energia = datos.get("energia", 50.0)
	Economia.numero_ascension = datos.get("ascension", 0)
	Economia.energia_total_partida = datos.get("energia_total", 0.0)
	Economia.espectros_eliminados = datos.get("espectros_elim", 0)

	# Reaplicar niveles in-run (fijan daño/vida/escudo... vía _aplicar_mejora).
	var niveles: Dictionary = datos.get("niveles", {})
	for id in niveles.keys():
		if MejoraManager.mejoras.has(id):
			MejoraManager.mejoras[id]["nivel"] = niveles[id]
			MejoraManager._aplicar_mejora(id)

	# La salud va DESPUÉS de aplicar mejoras (que fijan el máximo y curan).
	NexusStats.salud_actual = minf(datos.get("salud", NexusStats.get_salud()), NexusStats.get_salud())

	# Refrescar HUD y stats.
	Economia.recursos_actualizados.emit()
	Economia.ascension_cambiada.emit(Economia.numero_ascension)
	NexusStats.salud_cambiada.emit(NexusStats.salud_actual, NexusStats.get_salud())
	MejoraManager.mejoras_actualizadas.emit()
	NexusStats.stats_actualizadas.emit()
	print("▶️ Partida reanudada (Asc ", Economia.numero_ascension, ")")

	# Consumir el guardado: la run ya está activa de nuevo.
	borrar()
