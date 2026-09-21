extends CanvasLayer
# ═══════════════════════════════════════════════════
# INTERFAZ — UI principal de Void Sentinel
# FASE 1: Bugfixes críticos
# ═══════════════════════════════════════════════════

# ── Escala móvil ────────────────────────────────────
# Margen superior para no chocar con el notch/cámara del móvil, y tamaños
# de fuente del HUD (se veían muy pequeños en pantalla real). Ajustables.
const MARGEN_SUPERIOR: float = 100.0

# Márgenes seguros calculados del dispositivo (notch arriba, barra de
# navegación abajo). En PC valen el mínimo/0; en móvil, el área segura real.
var _margen_top: float = MARGEN_SUPERIOR
var _margen_bottom: float = 0.0

var barra_dron: ProgressBar
var barra_ascension: ProgressBar
var barra_vida: ProgressBar
var _ic_vida: IconoVec = null
var _tramo_vida: int = -1          # 0 sana, 1 media, 2 critica
var _btn_pausa: Button = null
var raiz: Control
var label_dron: Label

# Referencia cacheada al AscensionManager (antes se buscaba con find_child
# recursivo CADA frame en _process — costoso en móvil).
var _asc_manager: Node = null

# Referencia al panel de mejoras para ocultarlo en game over
var panel_mejoras: Control = null

# ── UI del Commander ────────────────────────────────
var lbl_commander_timer: Label
var lbl_commander_disparos: Label
var lbl_commander_alerta: Label
# Timers con process_mode PAUSABLE (se actualizan durante el juego,
# independientes del process_mode de la Interfaz)
var _timer_commander_ui: Timer
var _timer_alerta: Timer

# Evita mostrar el overlay de Game Over más de una vez
var _game_over_mostrado: bool = false

# ── Barra de habilidades ────────────────────────────
var _hab_botones: Dictionary = {}   # id → Button
var _hab_cd_lbls: Dictionary = {}   # id → Label cooldown

# Overlay del menú de pausa (null cuando está cerrado)
var _menu_pausa: Control = null
var _panel_visible_antes_pausa: bool = true

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label   = $PanelSuperior/VBoxContainer/LblDinero
@onready var lbl_salud: Label     = $PanelSuperior/LblVida
@onready var lbl_ecos: Label      = $PanelSuperior/VBoxContainer/LblEcos
@onready var lbl_fragmentos: Label = $PanelSuperior/VBoxContainer/LblFragmentos

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_calcular_safe_area()
	_construir_interfaz()
	_ajustar_escala_movil()

	Economia.recursos_actualizados.connect(_actualizar_energia)
	Economia.ecos_actualizados.connect(_actualizar_ecos)
	Economia.fragmentos_actualizados.connect(_actualizar_fragmentos)
	# Red de seguridad: cualquier cambio de recursos refresca todo el HUD,
	# aunque la fuente no emita las señales específicas (p. ej. el Commander).
	Economia.recursos_actualizados.connect(_actualizar_ecos)
	Economia.recursos_actualizados.connect(_actualizar_fragmentos)
	Economia.ascension_cambiada.connect(_actualizar_ascension)
	NexusStats.salud_cambiada.connect(_actualizar_salud)
	# ✅ #5: el Game Over lo dispara mundo.gd (que además pausa el árbol).
	# La Interfaz ya NO se conecta a juego_terminado para evitar el doble overlay.

	# Señales del sistema de disparos / Commander
	Sistemadisparosespeciales.disparos_actualizados.connect(_on_disparos_actualizados)
	Sistemadisparosespeciales.commander_apareci.connect(_on_commander_apareci)
	Sistemadisparosespeciales.commander_finalizado.connect(_on_commander_finalizado)
	
	_actualizar_energia()
	_actualizar_ascension(0)
	_actualizar_salud(NexusStats.salud_actual, NexusStats.get_salud())
	_actualizar_ecos()
	_actualizar_fragmentos()
	
	HabilidadEjecutor.cooldown_tick.connect(_refrescar_habilidades)

	await get_tree().process_frame

	var dron = get_tree().current_scene.find_child("Dron", true, false)
	if dron and dron.has_signal("fragmentos_actualizados"):
		dron.fragmentos_actualizados.connect(actualizar_barra_dron)

	_asc_manager = get_tree().current_scene.find_child("AscensionManager", true, false)
	if _asc_manager:
		if _asc_manager.has_signal("ascension_iniciada"):
			_asc_manager.ascension_iniciada.connect(_on_ascension_iniciada)
		if _asc_manager.has_signal("pausa_entre_ascensiones"):
			_asc_manager.pausa_entre_ascensiones.connect(_on_pausa_iniciada)

func _process(_delta: float) -> void:
	if barra_ascension and barra_ascension.visible:
		if is_instance_valid(_asc_manager) and _asc_manager.has_method("get_tiempo_restante"):
			var tiempo_restante = _asc_manager.get_tiempo_restante()
			var duracion = _asc_manager.get_duracion_ascension() if _asc_manager.has_method("get_duracion_ascension") else 35.0
			var progreso = (tiempo_restante / duracion) * 100
			barra_ascension.value = clamp(progreso, 0, 100)

func _construir_interfaz() -> void:
	
	# Contenedor base — ignora input para no bloquear nada
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	
	# Barra del dron. Por encima de la barra colapsada del PanelMejoras
	# (CanvasLayer, top en ~1182 - safe_bottom): a 1220 quedaba tapada.
	barra_dron = ProgressBar.new()
	barra_dron.position = Vector2(20, 1140 - _margen_bottom)
	barra_dron.size = Vector2(200, 20)
	barra_dron.max_value = 50
	barra_dron.value = 0
	barra_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_dron.add_theme_color_override("font_color", Color.CYAN)
	raiz.add_child(barra_dron)

	# Label texto barra dron
	label_dron = Label.new()
	label_dron.position = Vector2(20, 1135 - _margen_bottom)
	label_dron.add_theme_font_size_override("font_size", 10)
	label_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_dron.text = "▮ 0/50"
	raiz.add_child(label_dron)
	
	# Barra de ascensión
	barra_ascension = ProgressBar.new()
	barra_ascension.position = Vector2(400, _margen_top)
	barra_ascension.size = Vector2(300, 20)
	barra_ascension.max_value = 100
	barra_ascension.value = 100
	barra_ascension.visible = false
	barra_ascension.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(barra_ascension)
	

	# ── UI del Commander ────────────────────────────────
	lbl_commander_disparos = Label.new()
	lbl_commander_disparos.position = Vector2(20, _margen_top + 170)
	lbl_commander_disparos.add_theme_font_size_override("font_size", 24)
	lbl_commander_disparos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_disparos.visible = false
	raiz.add_child(lbl_commander_disparos)

	lbl_commander_timer = Label.new()
	lbl_commander_timer.position = Vector2(250, _margen_top + 170)
	lbl_commander_timer.add_theme_font_size_override("font_size", 26)
	lbl_commander_timer.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	lbl_commander_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_timer.visible = false
	raiz.add_child(lbl_commander_timer)

	lbl_commander_alerta = Label.new()
	lbl_commander_alerta.position = Vector2(140, _margen_top + 260)
	lbl_commander_alerta.size = Vector2(440, 80)
	lbl_commander_alerta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_commander_alerta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_commander_alerta.add_theme_font_size_override("font_size", 30)
	lbl_commander_alerta.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lbl_commander_alerta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_alerta.visible = false
	raiz.add_child(lbl_commander_alerta)

	# Timer de refresco del contador (countdown del Commander)
	_timer_commander_ui = Timer.new()
	_timer_commander_ui.wait_time = 0.25
	_timer_commander_ui.one_shot = false
	_timer_commander_ui.autostart = true
	_timer_commander_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_timer_commander_ui)
	_timer_commander_ui.timeout.connect(_tick_commander_ui)

	# Timer one-shot para ocultar la alerta tras unos segundos
	_timer_alerta = Timer.new()
	_timer_alerta.one_shot = true
	_timer_alerta.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_timer_alerta)
	_timer_alerta.timeout.connect(_ocultar_alerta)

	# ✅ Referencia al PanelMejoras (vive en su propio CanvasLayer "CapaUI",
	# hermano de esta interfaz) para poder ocultarlo en el game over.
	panel_mejoras = get_parent().get_node_or_null("CapaUI/PanelMejoras")
	if panel_mejoras == null:
		push_warning("Interfaz: PanelMejoras no encontrado en CapaUI")

	_crear_boton_pausa()
	_construir_barra_habilidades()

# Lee el área segura real del dispositivo. En PC mantiene el margen mínimo
# (MARGEN_SUPERIOR) arriba y 0 abajo; en móvil usa el notch y la barra del
# sistema reales.
func _calcular_safe_area() -> void:
	var vp := get_viewport().get_visible_rect().size
	var m := SafeArea.margenes(vp)
	_margen_top = max(MARGEN_SUPERIOR, m["top"])
	_margen_bottom = m["bottom"]

# La barra superior se construye por codigo con el sistema visual del menu
# (MenuTheme, IconoVec) en lugar de las etiquetas sueltas de la escena: el HUD
# no compartia ni una linea de estilo con el menu y parecia otro juego.
func _ajustar_escala_movil() -> void:
	_construir_barra_superior()

func _construir_barra_superior() -> void:
	var viejo := get_node_or_null("PanelSuperior") as Control

	var marco := MarginContainer.new()
	marco.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	marco.offset_top = _margen_top - 40.0
	marco.add_theme_constant_override("margin_left", 16)
	marco.add_theme_constant_override("margin_right", 16)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marco)

	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", MenuTheme.make_card_style(MenuTheme.BORDER_GLOW, 0.72))
	tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(tarjeta)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tarjeta.add_child(v)

	# Fila 1: ascension a la izquierda, recursos y pausa a la derecha.
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fila)

	var bloque_asc := VBoxContainer.new()
	bloque_asc.add_theme_constant_override("separation", 0)
	bloque_asc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloque_asc.add_child(_etiqueta("ASCENSIÓN", MenuTheme.FS_SMALL, MenuTheme.TEXT_MUTED, true))
	lbl_ascension = _etiqueta("0", MenuTheme.FS_HEADER + 6, MenuTheme.TEXT_PRIMARY, false)
	bloque_asc.add_child(lbl_ascension)
	fila.add_child(bloque_asc)

	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)

	lbl_energia = _recurso(fila, IconoVec.Forma.RAYO, MenuTheme.GOLD)
	lbl_ecos = _recurso(fila, IconoVec.Forma.ROMBO_PUNTO, MenuTheme.CYAN)
	lbl_fragmentos = _recurso(fila, IconoVec.Forma.ROMBO, MenuTheme.VIOLET)

	if is_instance_valid(_btn_pausa):
		_btn_pausa.get_parent().remove_child(_btn_pausa)
		_btn_pausa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(_btn_pausa)

	# Fila 2: la barra de ascension pasa dentro de la tarjeta. Su visibilidad
	# la siguen gobernando _on_ascension_iniciada / _on_pausa_iniciada.
	if is_instance_valid(barra_ascension):
		barra_ascension.get_parent().remove_child(barra_ascension)
		barra_ascension.custom_minimum_size = Vector2(0, 6)
		barra_ascension.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra_ascension.show_percentage = false
		barra_ascension.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
		barra_ascension.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill_gradient(MenuTheme.CYAN))
		v.add_child(barra_ascension)

	# Fila 3: la vida como barra. Antes era solo un texto, siendo el dato mas
	# critico de la partida.
	var fila_vida := HBoxContainer.new()
	fila_vida.add_theme_constant_override("separation", 10)
	fila_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fila_vida)

	var centro_vida := CenterContainer.new()
	centro_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic_vida = IconoVec.crear(IconoVec.Forma.CORAZON, 28, MenuTheme.GREEN)
	centro_vida.add_child(_ic_vida)
	fila_vida.add_child(centro_vida)

	barra_vida = ProgressBar.new()
	barra_vida.custom_minimum_size = Vector2(0, 12)
	barra_vida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_vida.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra_vida.show_percentage = false
	barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_vida.add_theme_stylebox_override("background", MenuTheme.make_progress_track())
	fila_vida.add_child(barra_vida)

	lbl_salud = _etiqueta("", MenuTheme.FS_SMALL + 4, MenuTheme.GREEN, false)
	fila_vida.add_child(lbl_salud)

	# La escena de la barra antigua ya no se usa.
	if viejo:
		viejo.queue_free()

# Un recurso: icono vectorial + cifra en su color. Devuelve la etiqueta.
func _recurso(fila: HBoxContainer, forma: int, color: Color) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(IconoVec.crear(forma, 30, color))
	h.add_child(centro)
	var lbl := _etiqueta("0", MenuTheme.FS_BODY + 8, color, false)
	h.add_child(lbl)
	fila.add_child(h)
	return lbl

# Las cifras van en la fuente de cuerpo a proposito: el cero de Orbitron es un
# rectangulo con barra diagonal y, con contadores a 0, parece un glifo roto.
func _etiqueta(texto: String, tam: int, color: Color, fuente_hud: bool) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f: Font = MenuTheme.get_font_hud() if fuente_hud else MenuTheme.get_font_body()
	if f:
		l.add_theme_font_override("font", f)
	return l

# ═══════════════════════════════════════════════════
# BARRA DE HABILIDADES (Forja — activas en partida)
# ═══════════════════════════════════════════════════
func _construir_barra_habilidades() -> void:
	var activas := HabilidadManager.get_activas()
	if activas.is_empty(): return

	var n     := activas.size()
	var btn_w := 80
	var gap   := 6
	var total := n * btn_w + (n - 1) * gap
	# Situar encima de la barra colapsada del PanelMejoras:
	# MARGEN_INFERIOR(48) + ALTURA_BARRA(50) + gap(8) + btn_h(72) = 178
	var vp    := get_viewport().get_visible_rect().size
	# Centrar sobre el ancho real: con stretch expand el viewport no siempre
	# mide los 720 de diseño y la barra quedaba descentrada a la izquierda.
	var x0    := int((vp.x - total) / 2.0)
	var y0    := int(vp.y - _margen_bottom - 178.0)

	for i in range(n):
		var id: String = activas[i]
		var x := x0 + i * (btn_w + gap)

		var btn := Button.new()
		btn.size = Vector2(btn_w, 72)
		btn.position = Vector2(x, y0)
		btn.z_index = 120
		btn.process_mode = Node.PROCESS_MODE_PAUSABLE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.flat = true

		# Nombre abreviado
		var nombre_lbl := Label.new()
		nombre_lbl.text = HabilidadEjecutor.nombre_corto(id)
		nombre_lbl.add_theme_font_size_override("font_size", 11)
		nombre_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Sin preset de anchors: combinarlo con size hacía que Godot avisara de
		# "non-equal opposite anchors" y sobrescribiera el tamaño tras _ready().
		# Se posiciona a mano, igual que cd_lbl.
		nombre_lbl.size = Vector2(btn_w, 28)
		nombre_lbl.position = Vector2(0, 4)
		nombre_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(nombre_lbl)

		# Cooldown / listo
		var cd_lbl := Label.new()
		cd_lbl.text = "LISTA"
		cd_lbl.add_theme_font_size_override("font_size", 13)
		cd_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.size = Vector2(btn_w, 28)
		cd_lbl.position = Vector2(0, 38)
		cd_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(cd_lbl)

		var _id := id  # captura para la lambda
		btn.pressed.connect(func(): HabilidadEjecutor.activar(_id))

		_hab_botones[id] = btn
		_hab_cd_lbls[id] = cd_lbl
		raiz.add_child(btn)

func _refrescar_habilidades() -> void:
	for id in _hab_botones.keys():
		var btn: Button = _hab_botones[id]
		var cd_lbl: Label = _hab_cd_lbls[id]
		if not is_instance_valid(btn): continue
		var restante := HabilidadEjecutor.get_cooldown_restante(id)
		if restante > 0.0:
			btn.modulate = Color(0.4, 0.4, 0.4, 0.9)
			cd_lbl.text = "%ds" % ceili(restante)
			cd_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		else:
			btn.modulate = Color.WHITE
			cd_lbl.text = "LISTA"
			cd_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

# ═══════════════════════════════════════════════════
# MENÚ DE PAUSA
# ═══════════════════════════════════════════════════
# Botón ⏸ arriba a la derecha. La pantalla mide 720×1280.
func _crear_boton_pausa() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.10)
	sb.border_color = Color(MenuTheme.CYAN.r, MenuTheme.CYAN.g, MenuTheme.CYAN.b, 0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(32)
	for estado in ["normal", "hover", "pressed"]:
		btn.add_theme_stylebox_override(estado, sb)
	# Icono dibujado: el glifo de pausa (U+23F8) salia como un cuadro vacio en
	# Android.
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(IconoVec.crear(IconoVec.Forma.PAUSA, 26, MenuTheme.CYAN))
	btn.add_child(centro)
	btn.z_index = 150
	btn.pressed.connect(_abrir_menu_pausa)
	add_child(btn)
	_btn_pausa = btn

func _abrir_menu_pausa() -> void:
	# No abrir sobre el game over ni dos veces.
	if _game_over_mostrado or is_instance_valid(_menu_pausa):
		return
	get_tree().paused = true
	# El panel de mejoras vive en CapaUI, otra CanvasLayer en la misma capa pero
	# posterior en el árbol: se pinta encima de esta interfaz y tapaba los botones
	# del menú (el z_index no cruza CanvasLayers). Se oculta mientras dura la pausa.
	if is_instance_valid(panel_mejoras):
		_panel_visible_antes_pausa = panel_mejoras.visible
		panel_mejoras.visible = false
	_menu_pausa = _construir_menu_pausa()
	add_child(_menu_pausa)

func _cerrar_menu_pausa() -> void:
	get_tree().paused = false
	if is_instance_valid(panel_mejoras):
		panel_mejoras.visible = _panel_visible_antes_pausa
	if is_instance_valid(_menu_pausa):
		_menu_pausa.queue_free()
	_menu_pausa = null

func _construir_menu_pausa() -> Control:
	# Misma tarjeta que el game over. _capa_modal la deja en ALWAYS para que
	# responda con el árbol pausado; los hijos heredan ese process_mode.
	var cont := _capa_modal("MenuPausa", MenuTheme.CYAN)
	cont.z_index = 250
	var v: VBoxContainer = cont.get_node("Centro/Tarjeta/Contenido")

	var titulo := _etiqueta("PAUSA", MenuTheme.FS_TITLE + 12, MenuTheme.CYAN, true)
	titulo.name = "Titulo"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)

	var sub := _etiqueta("Ascensión %d" % Economia.numero_ascension, MenuTheme.FS_BODY,
		Color(MenuTheme.TEXT_PRIMARY, 0.7), false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 6)
	v.add_child(hueco)

	v.add_child(_boton_tarjeta("VOLVER AL JUEGO", MenuTheme.CYAN, true, MenuTheme.CYAN,
		"BtnVolver", _cerrar_menu_pausa))
	v.add_child(_boton_tarjeta("SALIR AL MENÚ", MenuTheme.TEXT_MUTED, false, MenuTheme.TEXT_PRIMARY,
		"BtnSalir", _salir_al_menu))
	# Rojo y sin relleno: termina la partida, que no parezca la opción normal.
	v.add_child(_boton_tarjeta("ABANDONAR PARTIDA", MenuTheme.RED, false, MenuTheme.RED,
		"BtnAbandonar", _abandonar_partida))
	return cont

func _salir_al_menu() -> void:
	# Guardar progreso permanente + checkpoint de la run para poder reanudar.
	Economia.guardar_datos()
	MejoraManager.guardar_mejoras_nexo()
	# No guardar checkpoint si es una partida de prueba.
	if not ModoPrueba.partida_es_prueba:
		ReanudarPartida.guardar()
	_cerrar_menu_pausa()
	get_tree().change_scene_to_file("res://escenas/ui/MainMenu.tscn")

func _abandonar_partida() -> void:
	# Game over voluntario: cierra el menú y dispara el flujo de fin de partida
	# (mundo.gd captará la señal y mostrará la pantalla de estadísticas).
	if is_instance_valid(_menu_pausa):
		_menu_pausa.queue_free()
	_menu_pausa = null
	Economia.juego_terminado.emit("abandono")

# ═══════════════════════════════════════════════════
# SEÑALES DE ASCENSIÓN
# ═══════════════════════════════════════════════════
func _on_ascension_iniciada(_n: int) -> void:
	barra_ascension.visible = true
	barra_ascension.value = 100

func _on_pausa_iniciada(_segundos: float) -> void:
	barra_ascension.visible = true

# ═══════════════════════════════════════════════════
# ACTUALIZAR HUD
# ═══════════════════════════════════════════════════
func _actualizar_ecos() -> void:
	if lbl_ecos:
		lbl_ecos.text = Formato.abreviar(Economia.ecos)

func _actualizar_fragmentos() -> void:
	if lbl_fragmentos:
		lbl_fragmentos.text = Formato.abreviar(Economia.fragmentos)

func actualizar_barra_dron(actual: int, maximo: int) -> void:
	if barra_dron:
		barra_dron.max_value = maximo
		barra_dron.value = actual
		if label_dron:
			label_dron.text = "▮ %d/%d" % [actual, maximo]

func _actualizar_energia() -> void:
	if lbl_energia:
		lbl_energia.text = Formato.abreviar(Economia.energia)

func _actualizar_ascension(numero: int) -> void:
	lbl_ascension.text = str(numero)

func _actualizar_salud(actual: float, maxima: float) -> void:
	lbl_salud.text = "%s / %s" % [Formato.abreviar(actual), Formato.abreviar(maxima)]
	if not is_instance_valid(barra_vida):
		return
	var tope := maxf(maxima, 1.0)
	barra_vida.max_value = tope
	barra_vida.value = actual
	# Color por tramos. Solo se regenera el estilo al cambiar de tramo, no en
	# cada golpe.
	var frac := actual / tope
	var tramo := 0 if frac >= 0.5 else (1 if frac >= 0.25 else 2)
	if tramo != _tramo_vida:
		_tramo_vida = tramo
		var col: Color = [MenuTheme.GREEN, MenuTheme.GOLD, MenuTheme.RED][tramo]
		barra_vida.add_theme_stylebox_override("fill", MenuTheme.make_progress_fill_gradient(col))
		lbl_salud.add_theme_color_override("font_color", col)
		if is_instance_valid(_ic_vida):
			_ic_vida.color = col
			_ic_vida.queue_redraw()

# ═══════════════════════════════════════════════════
# UI DEL COMMANDER
# ═══════════════════════════════════════════════════
func _on_disparos_actualizados(disponibles: int) -> void:
	if not lbl_commander_disparos: return
	if disponibles > 0:
		lbl_commander_disparos.text = "DISPAROS %d" % disponibles
		lbl_commander_disparos.visible = true
		# Amarillo si hay Commander activo; azul si está "en espera"
		var activo: bool = Sistemadisparosespeciales.get_commander_activo()
		lbl_commander_disparos.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.2) if activo else Color(0.3, 0.7, 1.0))
	else:
		lbl_commander_disparos.visible = false

func _on_commander_apareci() -> void:
	_mostrar_alerta("¡COMMANDER DETECTADO!", Color(1.0, 0.3, 0.3))
	if lbl_commander_timer:
		lbl_commander_timer.visible = true

func _on_commander_finalizado(escapo: bool) -> void:
	if escapo:
		_mostrar_alerta("¡COMMANDER ESCAPA! VOLVERA MAS FUERTE", Color(1.0, 0.6, 0.0))
	if lbl_commander_timer:
		lbl_commander_timer.visible = false

func _mostrar_alerta(texto: String, color: Color) -> void:
	if not lbl_commander_alerta: return
	lbl_commander_alerta.text = texto
	lbl_commander_alerta.add_theme_color_override("font_color", color)
	lbl_commander_alerta.visible = true
	if _timer_alerta:
		_timer_alerta.start(2.5)

func _ocultar_alerta() -> void:
	if is_instance_valid(lbl_commander_alerta):
		lbl_commander_alerta.visible = false

func _tick_commander_ui() -> void:
	if not lbl_commander_timer: return
	var commander = get_tree().get_first_node_in_group("commanders")
	if commander and is_instance_valid(commander) \
	and not commander.get("esta_destruido") and not commander.get("escapando"):
		var rv = commander.get("timer_escape")
		var restante: float = maxf(0.0, float(rv)) if rv != null else 0.0
		var mins: int = int(restante) / 60
		var secs: int = int(restante) % 60
		lbl_commander_timer.text = "COMMANDER %d:%02d" % [mins, secs]
		lbl_commander_timer.visible = true
		lbl_commander_timer.add_theme_color_override("font_color",
			Color(1.0, 0.2, 0.2) if restante < 30.0 else Color(1.0, 0.5, 0.0))
	else:
		lbl_commander_timer.visible = false

# ═══════════════════════════════════════════════════
# GAME OVER
# ═══════════════════════════════════════════════════
func _formatear_causa(causa: String) -> String:
	match causa:
		"kamikaze":  return "Has muerto aplastado por un Kamikaze"
		"tanque":    return "Un Tanque ha acabado contigo"
		"sniper":    return "Un Sniper te ha disparado desde la distancia"
		"jefe":      return "Un Jefe ha arrasado tu Nexus"
		"commander": return "El Commander ha enviado demasiados refuerzos"
		"basico":    return "Los Espectros básicos te han superado"
		"abandono":  return "Has abandonado la partida"
		_:           return "Has caído en combate"

func mostrar_game_over(causa: String) -> void:
	# ✅ #5: evita un segundo overlay si la señal llegara por más de una vía
	if _game_over_mostrado:
		return
	_game_over_mostrado = true

	# Guardar progreso antes de mostrar pantalla
	Economia.guardar_datos()
	MejoraManager.guardar_mejoras_nexo()
	# La run terminó: descartar el checkpoint de reanudar.
	ReanudarPartida.borrar()

	if is_instance_valid(panel_mejoras):
		panel_mejoras.visible = false

	# Maquetado con contenedores: antes eran posiciones fijas pensadas para 440 px
	# de ancho y "GAME OVER" salía cortado. mundo.gd pausa el árbol: la capa va en
	# PROCESS_MODE_ALWAYS (lo pone _capa_modal) para que botones y animaciones vivan.
	var capa := _capa_modal("GameOver", MenuTheme.RED)
	capa.z_index = 200
	add_child(capa)
	var v: VBoxContainer = capa.get_node("Centro/Tarjeta/Contenido")

	var titulo := _etiqueta("GAME OVER", MenuTheme.FS_TITLE + 12, MenuTheme.RED, true)
	titulo.name = "Titulo"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titulo)

	var lbl_causa := _etiqueta(_formatear_causa(causa), MenuTheme.FS_BODY,
		Color(MenuTheme.TEXT_PRIMARY, 0.8), false)
	lbl_causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_causa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lbl_causa)

	var filo := ColorRect.new()
	filo.color = MenuTheme.BORDER_GLOW
	filo.custom_minimum_size = Vector2(0, 1)
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(filo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	_stat_game_over(fila, IconoVec.Forma.TRIANGULO, MenuTheme.CYAN,
		Economia.numero_ascension, "ASCENSIÓN")
	_stat_game_over(fila, IconoVec.Forma.CRUZ, MenuTheme.RED,
		Economia.espectros_eliminados, "ESPECTROS")
	_stat_game_over(fila, IconoVec.Forma.RAYO, MenuTheme.GOLD,
		int(Economia.energia_total_partida), "ENERGÍA")

	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(0, 6)
	v.add_child(hueco)

	v.add_child(_boton_tarjeta("REINTENTAR", MenuTheme.CYAN, true, MenuTheme.CYAN,
		"BtnReintentar", _reintentar_partida))
	v.add_child(_boton_tarjeta("MENÚ", MenuTheme.TEXT_MUTED, false, MenuTheme.TEXT_PRIMARY,
		"BtnMenu", _volver_al_menu))

	# Entrada con fundido. TWEEN_PAUSE_PROCESS: el árbol está en pausa.
	capa.modulate.a = 0.0
	var tw := capa.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(capa, "modulate:a", 1.0, 0.3)

# Una casilla de estadística: icono, cifra que cuenta desde 0 y rótulo.
func _stat_game_over(fila: HBoxContainer, forma: int, color: Color, valor: int, texto: String) -> void:
	var casilla := PanelContainer.new()
	casilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := MenuTheme.make_card_style(Color(color, 0.25), 0.6)
	sb.set_corner_radius_all(16)
	sb.content_margin_left   = 8
	sb.content_margin_right  = 8
	sb.content_margin_top    = 14
	sb.content_margin_bottom = 14
	casilla.add_theme_stylebox_override("panel", sb)
	fila.add_child(casilla)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	casilla.add_child(v)
	var c := CenterContainer.new()
	c.add_child(IconoVec.crear(forma, 30, color))
	v.add_child(c)
	var lbl := _etiqueta("0", MenuTheme.FS_HEADER, MenuTheme.TEXT_PRIMARY, false)
	lbl.name = "Valor"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)
	var pie := _etiqueta(texto, MenuTheme.FS_TINY, MenuTheme.TEXT_MUTED, true)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pie)

	# La cifra sube desde 0: el resultado se lee mejor si se ve llegar.
	var tw := casilla.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_method(func(x: float): lbl.text = Formato.abreviar(int(x)),
		0.0, float(valor), 0.8)

func _reintentar_partida() -> void:
	get_tree().paused = false
	Economia.iniciar_partida()
	get_tree().change_scene_to_file("res://escenas/mundo.tscn")

func _volver_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/ui/MainMenu.tscn")

# ═══════════════════════════════════════════════════
# TARJETAS MODALES (pausa y game over)
# ═══════════════════════════════════════════════════
# Capa a pantalla completa con una tarjeta centrada del estilo del menú.
# PROCESS_MODE_ALWAYS porque las dos pantallas se usan con el árbol en pausa.
# El contenido se añade a "Centro/Tarjeta/Contenido".
func _capa_modal(nombre: String, borde: Color) -> Control:
	var capa := Control.new()
	capa.name = nombre
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.process_mode = Node.PROCESS_MODE_ALWAYS

	var fondo := ColorRect.new()
	fondo.color = Color(MenuTheme.BG_DEEP, 0.85)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# STOP: que ningún toque llegue a la partida de debajo.
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(fondo)

	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)

	var tarjeta := PanelContainer.new()
	tarjeta.name = "Tarjeta"
	tarjeta.custom_minimum_size = Vector2(600, 0)
	var estilo := MenuTheme.make_card_style(Color(borde, 0.45), 0.95)
	estilo.content_margin_top    = 36
	estilo.content_margin_bottom = 32
	tarjeta.add_theme_stylebox_override("panel", estilo)
	centro.add_child(tarjeta)

	var v := VBoxContainer.new()
	v.name = "Contenido"
	v.add_theme_constant_override("separation", 18)
	tarjeta.add_child(v)
	return capa

# Botón de las tarjetas modales. `relleno` marca la acción principal.
func _boton_tarjeta(texto: String, color: Color, relleno: bool, color_texto: Color,
		nombre: String, accion: Callable) -> Button:
	var b := Button.new()
	b.name = nombre
	b.text = texto
	b.custom_minimum_size = Vector2(0, 76)
	b.focus_mode = Control.FOCUS_NONE
	var sb := MenuTheme.make_button_style(color, relleno)
	if relleno:
		sb.bg_color     = Color(color, 0.20)
		sb.border_color = Color(color, 0.70)
	var sb_pulsado := sb.duplicate() as StyleBoxFlat
	sb_pulsado.bg_color = Color(color, 0.35)
	for estado in ["normal", "hover", "focus"]:
		b.add_theme_stylebox_override(estado, sb)
	b.add_theme_stylebox_override("pressed", sb_pulsado)
	var f := MenuTheme.get_font_hud()
	if f:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", MenuTheme.FS_BODY)
	for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(clave, color_texto)
	b.pressed.connect(accion)
	return b
