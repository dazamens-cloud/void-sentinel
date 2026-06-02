extends CanvasLayer
# ═══════════════════════════════════════════════════
# INTERFAZ — UI principal de Void Sentinel
# FASE 1: Bugfixes críticos
# ═══════════════════════════════════════════════════

var barra_dron: ProgressBar
var barra_ascension: ProgressBar
var raiz: Control
var label_dron: Label

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

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label   = $PanelSuperior/LblDinero
@onready var lbl_salud: Label     = $PanelSuperior/LblVida

func _ready() -> void:
	print("🖥️ Interfaz: _ready() iniciado")
	# ✅ #10: la Interfaz procesa durante el juego (PAUSABLE) para que la barra
	# de ascensión avance. El overlay de Game Over usa su propio contenedor
	# PROCESS_MODE_ALWAYS para seguir respondiendo con el árbol en pausa.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_construir_interfaz()

	Economia.recursos_actualizados.connect(_actualizar_energia)
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
	
	await get_tree().process_frame
	
	var dron = get_tree().current_scene.find_child("Dron", true, false)
	if dron and dron.has_signal("fragmentos_actualizados"):
		dron.fragmentos_actualizados.connect(actualizar_barra_dron)
		print("🖥️ Interfaz: Conectada señal del Dron")
	
	var asc = get_tree().current_scene.find_child("AscensionManager", true, false)
	if asc:
		if asc.has_signal("ascension_iniciada"):
			asc.ascension_iniciada.connect(_on_ascension_iniciada)
		if asc.has_signal("pausa_entre_ascensiones"):
			asc.pausa_entre_ascensiones.connect(_on_pausa_iniciada)
		print("🖥️ Interfaz: Conectadas señales de AscensionManager")

func _process(_delta: float) -> void:
	if barra_ascension and barra_ascension.visible:
		var asc = get_tree().current_scene.find_child("AscensionManager", true, false)
		if asc and asc.has_method("get_tiempo_restante"):
			var tiempo_restante = asc.get_tiempo_restante()
			var progreso = (tiempo_restante / 35.0) * 100
			barra_ascension.value = clamp(progreso, 0, 100)

func _construir_interfaz() -> void:
	print("🖥️ Interfaz: Construyendo UI...")
	
	# Contenedor base — ignora input para no bloquear nada
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	
	# Barra del dron
	barra_dron = ProgressBar.new()
	barra_dron.position = Vector2(20, 1220)
	barra_dron.size = Vector2(200, 20)
	barra_dron.max_value = 50
	barra_dron.value = 0
	barra_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_dron.add_theme_color_override("font_color", Color.CYAN)
	raiz.add_child(barra_dron)
	
	# Label texto barra dron
	label_dron = Label.new()
	label_dron.position = Vector2(20, 1215)
	label_dron.add_theme_font_size_override("font_size", 10)
	label_dron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_dron.text = "🔋 0/50"
	raiz.add_child(label_dron)
	
	# Barra de ascensión
	barra_ascension = ProgressBar.new()
	barra_ascension.position = Vector2(400, 20)
	barra_ascension.size = Vector2(300, 20)
	barra_ascension.max_value = 100
	barra_ascension.value = 100
	barra_ascension.visible = false
	barra_ascension.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(barra_ascension)
	
	print("🖥️ Interfaz: Barras creadas")

	# ── UI del Commander ────────────────────────────────
	lbl_commander_disparos = Label.new()
	lbl_commander_disparos.position = Vector2(20, 70)
	lbl_commander_disparos.add_theme_font_size_override("font_size", 24)
	lbl_commander_disparos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_disparos.visible = false
	raiz.add_child(lbl_commander_disparos)

	lbl_commander_timer = Label.new()
	lbl_commander_timer.position = Vector2(250, 70)
	lbl_commander_timer.add_theme_font_size_override("font_size", 26)
	lbl_commander_timer.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	lbl_commander_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_commander_timer.visible = false
	raiz.add_child(lbl_commander_timer)

	lbl_commander_alerta = Label.new()
	lbl_commander_alerta.position = Vector2(140, 220)
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
func actualizar_barra_dron(actual: int, maximo: int) -> void:
	if barra_dron:
		barra_dron.max_value = maximo
		barra_dron.value = actual
		if label_dron:
			label_dron.text = "🔋 %d/%d" % [actual, maximo]

func _actualizar_energia() -> void:
	lbl_energia.text = "⚡ %d" % int(Economia.energia)

func _actualizar_ascension(numero: int) -> void:
	lbl_ascension.text = "Ascensión: %d" % numero

func _actualizar_salud(actual: float, maxima: float) -> void:
	lbl_salud.text = "❤️ %d / %d" % [int(actual), int(maxima)]

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
		"commander": return "El Commander ha enviado demasiados refuerzos"
		"basico":    return "Los Espectros básicos te han superado"
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
