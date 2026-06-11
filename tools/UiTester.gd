extends Node
# ═══════════════════════════════════════════════════
# UI TESTER — recorre las pantallas del juego y guarda capturas PNG.
# Herramienta de desarrollo, NO se incluye en el export.
#
# Uso:  godot --path . res://tools/UiTester.tscn
# Salida: tools/caps/*.png (en el directorio del proyecto)
# ═══════════════════════════════════════════════════

const DIR_CAPS := "res://tools/caps"

var _menu: Control = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_CAPS))
	await _run()
	get_tree().quit()


func _run() -> void:
	# ── 1. Menú principal y todas sus pantallas ──
	var menu_scene: PackedScene = load("res://escenas/ui/MainMenu.tscn")
	if menu_scene == null:
		# Busca el .tscn del menú por si tiene otro nombre/ruta.
		push_error("UiTester: no se encontró MainMenu.tscn; ajustar ruta")
	else:
		_menu = menu_scene.instantiate()
		add_child(_menu)
		await _esperar(0.6)

		for pantalla in ["home", "nexo", "forja", "perfil", "tienda", "lab", "misiones"]:
			if _menu.has_method("navigate"):
				_menu.navigate(pantalla)
			await _esperar(0.5)
			await _capturar("menu_" + pantalla)

		_menu.queue_free()
		await _esperar(0.3)

	# ── 2. Partida (mundo) ──
	# Marca el tutorial como visto para que no tape las capturas
	# (si no existía, se restaura al final para no quitárselo al jugador).
	var habia_tutorial := FileAccess.file_exists("user://tutorial.save")
	if not habia_tutorial:
		var ft := FileAccess.open("user://tutorial.save", FileAccess.WRITE)
		if ft:
			ft.store_var({"visto": true})
			ft.close()
	var eco := get_node_or_null("/root/Economia")
	if eco and eco.has_method("iniciar_partida"):
		eco.iniciar_partida()
	var mundo_scene: PackedScene = load("res://escenas/mundo.tscn")
	var mundo := mundo_scene.instantiate()
	add_child(mundo)
	await _esperar(1.5)
	await _capturar("mundo_inicio")

	# Panel de mejoras: estado por defecto ya capturado; ahora expandido.
	var panel := mundo.get_node_or_null("CapaUI/PanelMejoras")
	if panel and panel.has_method("abrir"):
		panel.abrir()
		await _esperar(0.8)
		await _capturar("mundo_panel_abierto")
		# Probar el cambio de pestañas.
		if panel.has_method("cambiar_categoria"):
			panel.cambiar_categoria("defensa")
			await _esperar(0.5)
			await _capturar("mundo_panel_defensa")
			panel.cambiar_categoria("bonificacion")
			await _esperar(0.5)
			await _capturar("mundo_panel_bonus")
			# Multiplicador MAX y modal de info (valor → siguiente + coste).
			panel.cambiar_categoria("ataque")
			if panel.has_method("_set_multiplicador"):
				panel._set_multiplicador(-1)
			await _esperar(0.5)
			await _capturar("mundo_panel_max")
			if panel.has_method("_mostrar_modal"):
				panel._mostrar_modal("danio", Color(0.06, 0.35, 0.54))
				await _esperar(0.5)
				await _capturar("mundo_panel_modal")
				panel._cerrar_modal()
	else:
		print("UiTester: PanelMejoras no encontrado en mundo")

	await _esperar(2.0)
	await _capturar("mundo_combate")

	mundo.queue_free()
	await _esperar(0.2)
	# Restaura el estado del tutorial (lo marcamos visto solo para capturar).
	if not habia_tutorial:
		var d := DirAccess.open("user://")
		if d and d.file_exists("tutorial.save"):
			d.remove("tutorial.save")
	print("UiTester: capturas listas en ", ProjectSettings.globalize_path(DIR_CAPS))


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout
	await get_tree().process_frame


func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var ruta := ProjectSettings.globalize_path(DIR_CAPS + "/" + nombre + ".png")
	var err := img.save_png(ruta)
	print("📸 ", nombre, " -> ", "OK" if err == OK else ("ERROR %d" % err))
