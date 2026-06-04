extends CanvasLayer
# ═══════════════════════════════════════════════════
# INTERFAZ — UI principal de Void Sentinel
# FASE 1: Bugfixes críticos
# ═══════════════════════════════════════════════════

# ── Escala móvil ────────────────────────────────────
# Margen superior para no chocar con el notch/cámara del móvil, y tamaños
# de fuente del HUD (se veían muy pequeños en pantalla real). Ajustables.
const MARGEN_SUPERIOR: float = 100.0
const HUD_FONT_PRINCIPAL: int = 30   # oleada, vida
const HUD_FONT_RECURSOS: int = 34    # energía, ecos, fragmentos

# Márgenes seguros calculados del dispositivo (notch arriba, barra de
# navegación abajo). En PC valen el mínimo/0; en móvil, el área segura real.
var _margen_top: float = MARGEN_SUPERIOR
var _margen_bottom: float = 0.0

var barra_dron: ProgressBar
var barra_ascension: ProgressBar
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

# Overlay del menú de pausa (null cuando está cerrado)
var _menu_pausa: Control = null

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label   = $PanelSuperior/VBoxContainer/LblDinero
@onready var lbl_salud: Label     = $PanelSuperior/LblVida
@onready var lbl_ecos: Label      = $PanelSuperior/VBoxContainer/LblEcos
@onready var lbl_fragmentos: Label = $PanelSuperior/VBoxContainer/LblFragmentos

func _ready() -> void:
	print("🖥️ Interfaz: _ready() iniciado")
	# ✅ #10: la Interfaz procesa durante el juego (PAUSABLE) para que la barra
	# de ascensión avance. El overlay de Game Over usa su propio contenedor
	# PROCESS_MODE_ALWAYS para seguir respondiendo con el árbol en pausa.
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
	
	await get_tree().process_frame
	
	var dron = get_tree().current_scene.find_child("Dron", true, false)
	if dron and dron.has_signal("fragmentos_actualizados"):
		dron.fragmentos_actualizados.connect(actualizar_barra_dron)
		print("🖥️ Interfaz: Conectada señal del Dron")
	
	_asc_manager = get_tree().current_scene.find_child("AscensionManager", true, false)
	if _asc_manager:
		if _asc_manager.has_signal("ascension_iniciada"):
			_asc_manager.ascension_iniciada.connect(_on_ascension_iniciada)
		if _asc_manager.has_signal("pausa_entre_ascensiones"):
			_asc_manager.pausa_entre_ascensiones.connect(_on_pausa_iniciada)
		print("🖥️ Interfaz: Conectadas señales de AscensionManager")

func _process(_delta: float) -> void:
	if barra_ascension and barra_ascension.visible:
		if is_instance_valid(_asc_manager) and _asc_manager.has_method("get_tiempo_restante"):
			var tiempo_restante = _asc_manager.get_tiempo_restante()
			var duracion = _asc_manager.get_duracion_ascension() if _asc_manager.has_method("get_duracion_ascension") else 35.0
			var progreso = (tiempo_restante / duracion) * 100
			barra_ascension.value = clamp(progreso, 0, 100)

func _construir_interfaz() -> void:
	print("🖥️ Interfaz: Construyendo UI...")
	
	# Contenedor base — ignora input para no bloquear nada
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	
	# Barra del dron (subida por encima de la barra de navegación del sistema)
	barra_dron = ProgressBar.new()
	barra_dron.position = Vector2(20, 1220 - _margen_bottom)
	barra_dron.size = Vector2(200, 20)
	barra_dron.max_value = 50
	barra_dron.value = 0
	barra_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_dron.add_theme_color_override("font_color", Color.CYAN)
	raiz.add_child(barra_dron)
	
	# Label texto barra dron
	label_dron = Label.new()
	label_dron.position = Vector2(20, 1215 - _margen_bottom)
	label_dron.add_theme_font_size_override("font_size", 10)
	label_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_dron.text = "🔋 0/50"
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
	
	print("🖥️ Interfaz: Barras creadas")

	# ── UI del Commander ────────────────────────────────
	lbl_commander_disparos = Label.new()
	lbl_commander_disparos.position = Vector2(20, _margen_top + 30)
	lbl_commander_disparos.add_theme_font_size_override("font_size", 24)
	lbl_commander_disparos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_disparos.visible = false
	raiz.add_child(lbl_commander_disparos)

	lbl_commander_timer = Label.new()
	lbl_commander_timer.position = Vector2(250, _margen_top + 30)
	lbl_commander_timer.add_theme_font_size_override("font_size", 26)
	lbl_commander_timer.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	lbl_commander_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_timer.visible = false
	raiz.add_child(lbl_commander_timer)

	lbl_commander_alerta = Label.new()
	lbl_commander_alerta.position = Vector2(140, _margen_top + 120)
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

	# ✅ Guardar referencia al PanelMejoras y reordenarlo al final
	# para que reciba inputs por encima de raiz
	var panel = get_node_or_null("PanelMejoras")
	if panel:
		panel_mejoras = panel
		remove_child(panel)
		add_child(panel)
		print("🖥️ Interfaz: PanelMejoras reordenado ✅")
	else:
		print("⚠️ Interfaz: PanelMejoras no encontrado")

	_crear_boton_pausa()

# Lee el área segura real del dispositivo. En PC mantiene el margen mínimo
# (MARGEN_SUPERIOR) arriba y 0 abajo; en móvil usa el notch y la barra del
# sistema reales.
func _calcular_safe_area() -> void:
	var vp := get_viewport().get_visible_rect().size
	var m := SafeArea.margenes(vp)
	_margen_top = max(MARGEN_SUPERIOR, m["top"])
	_margen_bottom = m["bottom"]

# Agranda las fuentes del HUD y baja el PanelSuperior para esquivar el notch.
func _ajustar_escala_movil() -> void:
	# Bajar la barra superior por debajo de la cámara/notch del móvil.
	var panel_sup := get_node_or_null("PanelSuperior") as Control
	if panel_sup:
		panel_sup.offset_top = _margen_top + 60
		panel_sup.offset_bottom = _margen_top + 60 + 145.0

	# Agrandar las etiquetas del HUD (override sobre los tamaños de la escena).
	for lbl in [lbl_ascension, lbl_salud]:
		if lbl:
			lbl.add_theme_font_size_override("font_size", HUD_FONT_PRINCIPAL)
	for lbl in [lbl_energia, lbl_ecos, lbl_fragmentos]:
		if lbl:
			lbl.add_theme_font_size_override("font_size", HUD_FONT_RECURSOS)

# ═══════════════════════════════════════════════════
# MENÚ DE PAUSA
# ═══════════════════════════════════════════════════
# Botón ⏸ arriba a la derecha. La pantalla mide 720×1280.
func _crear_boton_pausa() -> void:
	var btn = Button.new()
	btn.text = "⏸"
	btn.add_theme_font_size_override("font_size", 34)
	btn.size = Vector2(64, 64)
	# Esquina superior derecha, por debajo del notch (igual margen que el HUD).
	btn.position = Vector2(720 - 64 - 16, _margen_top + 60)
	btn.z_index = 150
	btn.pressed.connect(_abrir_menu_pausa)
	add_child(btn)

func _abrir_menu_pausa() -> void:
	# No abrir sobre el game over ni dos veces.
	if _game_over_mostrado or is_instance_valid(_menu_pausa):
		return
	get_tree().paused = true
	_menu_pausa = _construir_menu_pausa()
	add_child(_menu_pausa)

func _cerrar_menu_pausa() -> void:
	get_tree().paused = false
	if is_instance_valid(_menu_pausa):
		_menu_pausa.queue_free()
	_menu_pausa = null

func _construir_menu_pausa() -> Control:
	# Contenedor raíz: ALWAYS para responder con el árbol pausado; los hijos
	# heredan este process_mode.
	var cont = Control.new()
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.process_mode = Node.PROCESS_MODE_ALWAYS
	cont.z_index = 250

	# Fondo oscuro que captura el input para no tocar el juego de fondo.
	var fondo = ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.78)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	cont.add_child(fondo)

	# Título
	var titulo = Label.new()
	titulo.text = "PAUSA"
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size = Vector2(440, 70)
	titulo.position = Vector2(140, 430)
	cont.add_child(titulo)

	# Botones (centrados, 360 px de ancho)
	cont.add_child(_boton_pausa("VOLVER AL JUEGO", 560, Color(0.2, 0.7, 0.4), _cerrar_menu_pausa))
	cont.add_child(_boton_pausa("SALIR AL MENÚ", 650, Color(0.3, 0.5, 0.9), _salir_al_menu))
	cont.add_child(_boton_pausa("ABANDONAR PARTIDA", 740, Color(0.8, 0.25, 0.25), _abandonar_partida))
	return cont

func _boton_pausa(texto: String, y: float, color: Color, accion: Callable) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", color)
	btn.size = Vector2(360, 64)
	btn.position = Vector2((720 - 360) / 2.0, y)
	btn.pressed.connect(accion)
	return btn

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
		lbl_ecos.text = "🔷 %s" % Formato.abreviar(Economia.ecos)

func _actualizar_fragmentos() -> void:
	if lbl_fragmentos:
		lbl_fragmentos.text = "💎 %s" % Formato.abreviar(Economia.fragmentos)

func actualizar_barra_dron(actual: int, maximo: int) -> void:
	if barra_dron:
		barra_dron.max_value = maximo
		barra_dron.value = actual
		if label_dron:
			label_dron.text = "🔋 %d/%d" % [actual, maximo]

func _actualizar_energia() -> void:
	if lbl_energia:
		lbl_energia.text = "⚡ %s" % Formato.abreviar(Economia.energia)

func _actualizar_ascension(numero: int) -> void:
	lbl_ascension.text = "Ascensión: %d" % numero

func _actualizar_salud(actual: float, maxima: float) -> void:
	lbl_salud.text = "❤️ %s / %s" % [Formato.abreviar(actual), Formato.abreviar(maxima)]

# ═══════════════════════════════════════════════════
# UI DEL COMMANDER
# ═══════════════════════════════════════════════════
func _on_disparos_actualizados(disponibles: int) -> void:
	if not lbl_commander_disparos: return
	if disponibles > 0:
		lbl_commander_disparos.text = "⚡ %d" % disponibles
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
	print("🖥️ Interfaz: GAME OVER - ", causa)

	# Guardar progreso antes de mostrar pantalla
	Economia.guardar_datos()
	MejoraManager.guardar_mejoras_nexo()
	# La run terminó: descartar el checkpoint de reanudar.
	ReanudarPartida.borrar()

	if is_instance_valid(panel_mejoras):
		panel_mejoras.visible = false

	# ── Fondo oscuro ──────────────────────────────────────────
	var fondo = ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.75)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.z_index = 200
	add_child(fondo)

	# ── "GAME OVER" ───────────────────────────────────────────
	var lbl_go = Label.new()
	lbl_go.text = "GAME OVER"
	lbl_go.add_theme_font_size_override("font_size", 52)
	lbl_go.add_theme_color_override("font_color", Color.RED)
	lbl_go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_go.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl_go.size = Vector2(440, 80)
	lbl_go.position = Vector2(0, 420)
	lbl_go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_go.z_index = 201
	add_child(lbl_go)

	# ── Causa de muerte ───────────────────────────────────────
	var lbl_causa = Label.new()
	lbl_causa.text = _formatear_causa(causa)
	lbl_causa.add_theme_font_size_override("font_size", 20)
	lbl_causa.add_theme_color_override("font_color", Color.WHITE)
	lbl_causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_causa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_causa.size = Vector2(440, 70)
	lbl_causa.position = Vector2(0, 510)
	lbl_causa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_causa.z_index = 201
	add_child(lbl_causa)

	# ── Ascensión alcanzada ───────────────────────────────────
	var lbl_asc = Label.new()
	lbl_asc.text = "Ascensión alcanzada: %d" % Economia.numero_ascension
	lbl_asc.add_theme_font_size_override("font_size", 18)
	lbl_asc.add_theme_color_override("font_color", Color.YELLOW)
	lbl_asc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_asc.size = Vector2(440, 50)
	lbl_asc.position = Vector2(0, 590)
	lbl_asc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_asc.z_index = 201
	add_child(lbl_asc)

	# ── Espectros destruidos ──────────────────────────────────
	var lbl_espectros = Label.new()
	lbl_espectros.text = "Espectros destruidos: %d" % Economia.espectros_eliminados
	lbl_espectros.add_theme_font_size_override("font_size", 18)
	lbl_espectros.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	lbl_espectros.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_espectros.size = Vector2(440, 50)
	lbl_espectros.position = Vector2(0, 640)
	lbl_espectros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_espectros.z_index = 201
	add_child(lbl_espectros)

	# ── Energía total conseguida ──────────────────────────────
	var lbl_energia_total = Label.new()
	lbl_energia_total.text = "Energía conseguida: %d ⚡" % int(Economia.energia_total_partida)
	lbl_energia_total.add_theme_font_size_override("font_size", 16)
	lbl_energia_total.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	lbl_energia_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_energia_total.size = Vector2(440, 45)
	lbl_energia_total.position = Vector2(0, 690)
	lbl_energia_total.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_energia_total.z_index = 201
	add_child(lbl_energia_total)

	# ── Botón REINTENTAR ─────────────────────────────────────
	var btn_reiniciar = Button.new()
	btn_reiniciar.text = "REINTENTAR"
	btn_reiniciar.size = Vector2(220, 60)
	btn_reiniciar.position = Vector2(250, 760)
	btn_reiniciar.z_index = 210
	# ✅ #10: con el árbol en pausa, el botón debe seguir respondiendo
	btn_reiniciar.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_reiniciar.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")
	)
	add_child(btn_reiniciar)

	# ── Botón MENÚ ───────────────────────────────────────────
	var btn_menu = Button.new()
	btn_menu.text = "MENÚ"
	btn_menu.size = Vector2(220, 60)
	btn_menu.position = Vector2(250, 840)
	btn_menu.z_index = 210
	# ✅ #10: con el árbol en pausa, el botón debe seguir respondiendo
	btn_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://escenas/ui/MainMenu.tscn")
	)
	add_child(btn_menu)
