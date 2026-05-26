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

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label   = $PanelSuperior/LblDinero
@onready var lbl_salud: Label     = $PanelSuperior/LblVida

func _ready() -> void:
	print("🖥️ Interfaz: _ready() iniciado")
	_construir_interfaz()
	
	Economia.recursos_actualizados.connect(_actualizar_energia)
	Economia.ascension_cambiada.connect(_actualizar_ascension)
	NexusStats.salud_cambiada.connect(_actualizar_salud)
	Economia.juego_terminado.connect(_on_juego_terminado)
	
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
# GAME OVER
# ═══════════════════════════════════════════════════
func _on_juego_terminado(causa: String) -> void:
	mostrar_game_over(causa)

func mostrar_game_over(causa: String) -> void:
	print("🖥️ Interfaz: GAME OVER - ", causa)
	
	# ✅ FIX: Ocultar el PanelMejoras para que no bloquee el input
	if is_instance_valid(panel_mejoras):
		panel_mejoras.visible = false
	
	# ── Fondo oscuro ──────────────────────────────────────────
	var fondo = ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.75)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# ✅ FIX: IGNORE para que no bloquee el botón
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.z_index = 200
	add_child(fondo)
	
	# ── "GAME OVER" ───────────────────────────────────────────
	var lbl_go = Label.new()
	lbl_go.text = "GAME OVER"
	lbl_go.add_theme_font_size_override("font_size", 52)
	lbl_go.add_theme_color_override("font_color", Color.RED)
	lbl_go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# ✅ FIX: tamaño justo, no cubre toda la pantalla
	lbl_go.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl_go.size = Vector2(440, 80)
	lbl_go.position = Vector2(0, 480)
	# ✅ FIX: IGNORE para que no bloquee el botón
	lbl_go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_go.z_index = 201
	add_child(lbl_go)
	
	# ── Causa de muerte ───────────────────────────────────────
	var lbl_causa = Label.new()
	lbl_causa.text = "Has muerto por: " + causa
	lbl_causa.add_theme_font_size_override("font_size", 22)
	lbl_causa.add_theme_color_override("font_color", Color.WHITE)
	lbl_causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_causa.size = Vector2(440, 60)
	lbl_causa.position = Vector2(0, 570)
	lbl_causa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_causa.z_index = 201
	add_child(lbl_causa)
	
	# ── Ascensión alcanzada ───────────────────────────────────
	var lbl_asc = Label.new()
	lbl_asc.text = "Ascensión alcanzada: %d" % Economia.numero_ascension
	lbl_asc.add_theme_font_size_override("font_size", 20)
	lbl_asc.add_theme_color_override("font_color", Color.YELLOW)
	lbl_asc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_asc.size = Vector2(440, 60)
	lbl_asc.position = Vector2(0, 635)
	lbl_asc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_asc.z_index = 201
	add_child(lbl_asc)
	
	# ── Botón REINICIAR ───────────────────────────────────────
	# ✅ FIX: centrado relativo al ancho de pantalla (720/2 - 100 = 260)
	var btn_reiniciar = Button.new()
	btn_reiniciar.text = "REINICIAR"
	btn_reiniciar.size = Vector2(220, 60)
	btn_reiniciar.position = Vector2(250, 730)
	# ✅ FIX: z_index MUY alto para estar por encima de todo
	btn_reiniciar.z_index = 210
	btn_reiniciar.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	add_child(btn_reiniciar)
	
	# ── Botón MENÚ PRINCIPAL ──────────────────────────────────
	var btn_menu = Button.new()
	btn_menu.text = "MENÚ PRINCIPAL"
	btn_menu.size = Vector2(220, 60)
	btn_menu.position = Vector2(250, 810)
	btn_menu.z_index = 210
	btn_menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://escenas/ui/MainMenu.tscn")
	)
	add_child(btn_menu)
