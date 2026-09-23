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
		await _test_panel_mejoras()
		_test_habilidades_y_dron()
		# Antes que el game over: con el game over mostrado la pausa ya no abre.
		await _test_menu_pausa()
		await _test_game_over()

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


# Lo que se vio mal en el móvil: la fila de pestañas se movía al cambiar de
# categoría, las cards medían distinto según su texto y el coste llevaba "⚡".
func _test_panel_mejoras() -> void:
	print("── Panel de mejoras")
	var panel: Control = _hud.get("panel_mejoras")
	if not is_instance_valid(panel):
		return
	panel.abrir()
	await get_tree().create_timer(0.4).timeout
	var top_ataque: float = panel.offset_top
	panel.cambiar_categoria("bonificacion")
	await get_tree().create_timer(0.4).timeout
	_ok(is_equal_approx(panel.offset_top, top_ataque),
		"la barra no se mueve al pasar de Ataque a Bonus (%.0f → %.0f)" % [top_ataque, panel.offset_top])

	var anchos := {}
	var altos := {}
	for card in panel.bonificacion_container.get_children():
		anchos[roundi(card.size.x)] = true
		altos[roundi(card.size.y)] = true
	_ok(anchos.size() == 1, "las cards de Bonus miden igual de ancho %s" % [anchos.keys()])
	_ok(altos.size() == 1, "las cards de Bonus miden igual de alto %s" % [altos.keys()])

	var manager := get_node("/root/MejoraManager")
	var valores_malos := ""
	for id in manager.mejoras:
		for nivel in [0, 1, manager.get_max_nivel(id)]:
			var texto: String = manager.formatear_valor(id, nivel)
			if not _simbolos_problematicos(texto).is_empty():
				valores_malos += "%s=\"%s\" " % [id, texto]
	_ok(valores_malos.is_empty(), "los valores de las mejoras se pintan en Android%s"
		% ("" if valores_malos.is_empty() else " (%s)" % valores_malos.strip_edges()))

	# El texto flotante de recompensas también se pinta en el móvil.
	var flotante: Label = load("res://escenas/Objetos/TextoFlotante.tscn").instantiate()
	add_child(flotante)
	flotante.set_energia(1234)
	var malo_energia := _simbolos_problematicos(flotante.text)
	flotante.set_ecos(5)
	var malo_ecos := _simbolos_problematicos(flotante.text)
	_ok(malo_energia.is_empty() and malo_ecos.is_empty(),
		"el texto flotante se pinta en Android (%s / %s)" % [malo_energia, malo_ecos])
	flotante.queue_free()

	var textos_malos := ""
	for grid in [panel.ataque_container, panel.defensa_container,
			panel.bonificacion_container, panel.commander_container]:
		for card in grid.get_children():
			if card.has_method("refrescar"):
				card.refrescar()
			for lbl in card.find_children("*", "Label", true, false):
				if not _simbolos_problematicos(lbl.text).is_empty():
					textos_malos += "%s=\"%s\" " % [card.name, lbl.text]
	_ok(textos_malos.is_empty(), "los textos de las cards se pintan en Android%s"
		% ("" if textos_malos.is_empty() else " (%s)" % textos_malos.strip_edges()))
	panel.cerrar()


# El cooldown se leía como texto ("17s") casi ilegible en el móvil; ahora es un
# anillo alrededor del icono. El dron era una ProgressBar gris suelta.
func _test_habilidades_y_dron() -> void:
	print("── Habilidades y dron")
	_hud.actualizar_barra_dron(12, 50)
	var pildora: Control = _hud.raiz.find_child("PildoraDron", true, false)
	_ok(pildora != null, "monta la píldora del dron")
	_ok(_hud.label_dron.text == "12 / 50",
		"el contador del dron muestra el valor (\"%s\")" % _hud.label_dron.text)
	_ok(_simbolos_problematicos(_hud.label_dron.text).is_empty(),
		"el contador del dron se pinta en Android")

	var activas: Array = HabilidadManager.get_activas()
	if activas.is_empty():
		print("   · sin habilidades activas en este guardado: nada que comprobar")
		return
	var fila: Control = _hud.raiz.find_child("BarraHabilidades", true, false)
	_ok(fila != null, "monta la fila de habilidades")

	var id: String = activas[0]
	var anillo = _hud._hab_anillos.get(id)
	var lbl: Label = _hud._hab_cd_lbls.get(id)
	var ejecutor := get_node("/root/HabilidadEjecutor")
	# Enfriándose: el anillo arranca casi vacío y la etiqueta da los segundos.
	ejecutor._cooldowns[id] = HabilidadManager.get_cooldown(id)
	_hud._refrescar_habilidades()
	_ok(anillo != null and anillo.progreso < 0.05, "el anillo se vacía al lanzarla")
	_ok(lbl != null and lbl.text.ends_with("s"), "la etiqueta muestra los segundos (\"%s\")" % lbl.text)
	# Lista otra vez: anillo lleno y el nombre de vuelta.
	ejecutor._cooldowns[id] = 0.0
	_hud._refrescar_habilidades()
	_ok(anillo.progreso >= 0.99, "el anillo se llena cuando está lista")
	_ok(lbl.text == ejecutor.nombre_corto(id), "vuelve el nombre corto (\"%s\")" % lbl.text)


# El menú de pausa comparte tarjeta con el game over; sus botones tienen que
# responder con el árbol en pausa y cerrar tiene que reanudar la partida.
func _test_menu_pausa() -> void:
	print("── Menú de pausa")
	_hud._abrir_menu_pausa()
	await get_tree().create_timer(0.3).timeout
	var menu: Control = _hud.get("_menu_pausa")
	_ok(is_instance_valid(menu) and get_tree().paused, "abre el menú y pausa la partida")
	if not is_instance_valid(menu):
		return
	var tarjeta: Control = menu.find_child("Tarjeta", true, false)
	_ok(tarjeta != null and get_viewport().get_visible_rect().encloses(tarjeta.get_global_rect()),
		"la tarjeta cabe en pantalla")
	var titulo: Label = menu.find_child("Titulo", true, false)
	_ok(titulo != null and titulo.get_minimum_size().x <= titulo.size.x + 0.5,
		"\"PAUSA\" cabe entero")
	var botones_ok := true
	for nombre in ["BtnVolver", "BtnSalir", "BtnAbandonar"]:
		var b: Button = menu.find_child(nombre, true, false)
		botones_ok = botones_ok and b != null and b.can_process()
	_ok(botones_ok, "los tres botones responden con el juego en pausa")
	# El panel está en otra CanvasLayer que se pinta encima: si sigue visible,
	# tapa los botones del menú.
	var panel: Control = _hud.get("panel_mejoras")
	_ok(is_instance_valid(panel) and not panel.visible, "el panel de mejoras no tapa el menú")

	_hud._cerrar_menu_pausa()
	await get_tree().process_frame
	_ok(not get_tree().paused and not is_instance_valid(menu), "cerrar reanuda la partida")
	_ok(is_instance_valid(panel) and panel.visible, "al cerrar vuelve el panel de mejoras")


# En el móvil "GAME OVER" salía cortado y los textos descolocados: estaban en
# posiciones fijas pensadas para 440 px de ancho.
func _test_game_over() -> void:
	print("── Game over")
	_hud.mostrar_game_over("tanque")
	await get_tree().create_timer(1.0).timeout
	var capa: Control = _hud.get_node_or_null("GameOver")
	_ok(capa != null, "monta la pantalla de game over")
	if capa == null:
		return
	var tarjeta: Control = capa.find_child("Tarjeta", true, false)
	var pantalla := get_viewport().get_visible_rect()
	_ok(tarjeta != null and pantalla.encloses(tarjeta.get_global_rect()),
		"la tarjeta cabe en pantalla")
	var titulo: Label = capa.find_child("Titulo", true, false)
	_ok(titulo != null and titulo.get_minimum_size().x <= titulo.size.x + 0.5,
		"\"GAME OVER\" cabe entero")

	var valores := capa.find_children("Valor", "Label", true, false)
	var esperado := [Economia.numero_ascension, Economia.espectros_eliminados,
		int(Economia.energia_total_partida)]
	var cuadran := valores.size() == 3
	for i in mini(valores.size(), 3):
		cuadran = cuadran and valores[i].text == Formato.abreviar(esperado[i])
	_ok(cuadran, "las cifras terminan en su valor real %s" % [valores.map(func(l): return l.text)])

	# Con el árbol en pausa (lo hace mundo.gd), los botones deben seguir vivos.
	var botones_ok := true
	for nombre in ["BtnReintentar", "BtnMenu"]:
		var b: Button = capa.find_child(nombre, true, false)
		botones_ok = botones_ok and b != null and b.can_process()
	_ok(botones_ok, "los botones responden con el juego en pausa")

	var malos := ""
	for lbl in capa.find_children("*", "Label", true, false):
		malos += _simbolos_problematicos(lbl.text)
	_ok(malos.is_empty(), "los textos del game over se pintan en Android%s"
		% ("" if malos.is_empty() else " (%s)" % malos))


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
