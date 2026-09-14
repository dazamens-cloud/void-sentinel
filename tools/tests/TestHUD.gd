extends Node
# ═══════════════════════════════════════════════════
# PRUEBAS DEL HUD DE PARTIDA — Void Sentinel
#
# Red de seguridad antes de rediseñar Interfaz.gd: comprueba que el HUD se
# monta dentro de mundo.tscn y que refleja los cambios de Economia y
# NexusStats. También vigila que sus textos no lleven símbolos de la zona de
# emoji, que en Android salen como huecos (verificado en un Xiaomi).
#
#   powershell -File tools\tests\ejecutar-pruebas.ps1
#
# ⚠ Monta una partida real y toca user://: lánzala siempre con el runner, que
#   respalda y restaura el guardado del jugador.
# ═══════════════════════════════════════════════════

var _fallos: int = 0
var _pasados: int = 0
var _hud: CanvasLayer = null


func _ready() -> void:
	print("═══ PRUEBAS DEL HUD ═══\n")

	# Marcar el tutorial como visto para que no se interponga.
	var ft := FileAccess.open("user://tutorial.save", FileAccess.WRITE)
	if ft:
		ft.store_var({"visto": true})
		ft.close()

	Economia.iniciar_partida()
	var mundo: Node = load("res://escenas/mundo.tscn").instantiate()
	add_child(mundo)
	for i in 10:
		await get_tree().process_frame

	_test_montaje(mundo)
	if _hud != null:
		await _test_senales()
		_test_simbolos()

	print("\n═══ RESULTADO: %d pasados, %d fallos ═══" % [_pasados, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


func _test_montaje(mundo: Node) -> void:
	print("── Montaje")
	_hud = mundo.get_node_or_null("Interfaz") as CanvasLayer
	_ok(_hud != null, "el HUD (Interfaz) existe dentro de mundo")
	if _hud == null:
		return
	for campo in ["lbl_ascension", "lbl_energia", "lbl_salud", "lbl_ecos", "lbl_fragmentos"]:
		_ok(is_instance_valid(_hud.get(campo)), "tiene la etiqueta %s" % campo)
	_ok(is_instance_valid(_hud.get("panel_mejoras")), "encuentra el panel de mejoras")
	_ok(is_instance_valid(_hud.get("barra_dron")), "construye la barra del dron")


func _test_senales() -> void:
	print("── Refleja los cambios de estado")

	Economia.energia = 0.0
	Economia.añadir_energia(1234.0)
	await get_tree().process_frame
	_ok(_contiene_cifra(_hud.lbl_energia.text, Economia.energia),
		"la energía se actualiza (\"%s\")" % _hud.lbl_energia.text)

	var ecos_antes: int = Economia.ecos
	Economia.añadir_ecos(7)
	await get_tree().process_frame
	_ok(_contiene_cifra(_hud.lbl_ecos.text, ecos_antes + 7),
		"los ecos se actualizan (\"%s\")" % _hud.lbl_ecos.text)

	var frag_antes: int = Economia.fragmentos
	Economia.añadir_fragmentos(3)
	await get_tree().process_frame
	_ok(_contiene_cifra(_hud.lbl_fragmentos.text, frag_antes + 3),
		"los fragmentos se actualizan (\"%s\")" % _hud.lbl_fragmentos.text)

	Economia.ascension_cambiada.emit(42)
	await get_tree().process_frame
	_ok(_hud.lbl_ascension.text.contains("42"),
		"la ascensión se actualiza (\"%s\")" % _hud.lbl_ascension.text)

	NexusStats.salud_actual = NexusStats.get_salud()
	NexusStats.escudo_actual = 0.0
	NexusStats.recibir_ataque(10.0)
	await get_tree().process_frame
	_ok(_contiene_cifra(_hud.lbl_salud.text, NexusStats.salud_actual),
		"la vida se actualiza tras un golpe (\"%s\")" % _hud.lbl_salud.text)


# Lo que demostró fallar en el móvil: emoji fuera del BMP, símbolos varios con
# presentación emoji (U+2600-26FF, p. ej. ⚡) y el selector de emoji U+FE0F
# (el de "❤️"). Los geométricos (◈ ◆) y los Dingbats (✕ ✓) sí se ven.
func _test_simbolos() -> void:
	print("── Textos que Android puede pintar")
	for campo in ["lbl_ascension", "lbl_energia", "lbl_salud", "lbl_ecos", "lbl_fragmentos"]:
		var lbl: Label = _hud.get(campo)
		if not is_instance_valid(lbl):
			continue
		var malos := _simbolos_problematicos(lbl.text)
		_ok(malos.is_empty(), "%s sin símbolos que fallan en Android%s"
			% [campo, "" if malos.is_empty() else " (encontrados: %s)" % malos])


func _simbolos_problematicos(texto: String) -> String:
	var malos := ""
	for i in texto.length():
		var cp := texto.unicode_at(i)
		if cp > 0xFFFF or (cp >= 0x2600 and cp <= 0x26FF) or cp == 0xFE0F:
			malos += "U+%04X " % cp
	return malos.strip_edges()


# El HUD abrevia cifras grandes (1.2K...), así que se compara la parte entera
# de la cifra abreviada con la que aparece en el texto.
func _contiene_cifra(texto: String, valor: float) -> bool:
	return texto.contains(Formato.abreviar(valor))


func _ok(cond: bool, desc: String) -> void:
	if cond:
		_pasados += 1
		print("   ✓ ", desc)
	else:
		_fallos += 1
		print("   ✗ FALLO: ", desc)
