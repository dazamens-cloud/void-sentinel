extends CanvasLayer
# ═══════════════════════════════════════════════════
# INTERFAZ — UI principal de Void Sentinel
# ═══════════════════════════════════════════════════

var barra_dron: ProgressBar
var barra_ascension: ProgressBar
var raiz: Control
var label_dron: Label

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label = $PanelSuperior/LblDinero
@onready var lbl_salud: Label = $PanelSuperior/LblVida

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
	# Actualizar barra de ascensión con tiempo real
	if barra_ascension and barra_ascension.visible:
		var asc = get_tree().current_scene.find_child("AscensionManager", true, false)
		if asc and asc.has_method("get_tiempo_restante"):
			var tiempo_restante = asc.get_tiempo_restante()
			var progreso = (tiempo_restante / 35.0) * 100
			barra_ascension.value = clamp(progreso, 0, 100)

func _construir_interfaz() -> void:
	print("🖥️ Interfaz: Construyendo UI...")
	
	# ── Contenedor base (ignora input para no bloquear botones) ──
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
	
	# ✅ CLAVE: mover PanelMejoras al final del árbol para que
	# quede POR ENCIMA de raiz y reciba el input correctamente
	var panel = get_node_or_null("PanelMejoras")
	if panel:
		remove_child(panel)
		add_child(panel)
		print("🖥️ Interfaz: PanelMejoras reordenado ✅")
	else:
		print("⚠️ Interfaz: PanelMejoras no encontrado")

func _on_ascension_iniciada(_n: int) -> void:
	print("🖥️ Interfaz: Ascensión iniciada, mostrando barra")
	barra_ascension.visible = true
	barra_ascension.value = 100

func _on_pausa_iniciada(segundos: float) -> void:
	print("🖥️ Interfaz: Pausa iniciada, ", segundos, " segundos restantes")
	barra_ascension.visible = true

func actualizar_barra_dron(actual: int, maximo: int) -> void:
	if barra_dron:
		barra_dron.max_value = maximo
		barra_dron.value = actual
		if label_dron:
			label_dron.text = "🔋 %d/%d" % [actual, maximo]
		print("🖥️ Interfaz: Barra dron actualizada: ", actual, "/", maximo)

func _actualizar_energia() -> void:
	lbl_energia.text = "⚡ %d" % int(Economia.energia)
	print("💰 Energía actualizada: ", Economia.energia)

func _actualizar_ascension(numero: int) -> void:
	lbl_ascension.text = "Ascensión: %d" % numero
	print("📊 Ascensión actualizada: ", numero)

func _actualizar_salud(actual: float, maxima: float) -> void:
	lbl_salud.text = "❤️ %d / %d" % [int(actual), int(maxima)]
	print("❤️ Salud actualizada: ", actual, "/", maxima)

func _on_juego_terminado(causa: String) -> void:
	mostrar_game_over(causa)

func mostrar_game_over(causa: String) -> void:
	print("🖥️ Interfaz: GAME OVER - ", causa)
	
	var panel = ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.7)
	panel.size = Vector2(720, 1280)
	panel.position = Vector2(0, 0)
	panel.z_index = 200
	add_child(panel)
	
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.size = Vector2(720, 1280)
	game_over_label.position = Vector2(0, 0)
	game_over_label.z_index = 201
	add_child(game_over_label)
	
	var causa_label = Label.new()
	causa_label.text = causa
	causa_label.add_theme_font_size_override("font_size", 24)
	causa_label.add_theme_color_override("font_color", Color.WHITE)
	causa_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	causa_label.size = Vector2(720, 100)
	causa_label.position = Vector2(0, 600)
	causa_label.z_index = 201
	add_child(causa_label)
	
	var boton = Button.new()
	boton.text = "REINICIAR"
	boton.size = Vector2(200, 50)
	boton.position = Vector2(260, 700)
	boton.z_index = 201
	boton.pressed.connect(func(): get_tree().reload_current_scene())
	add_child(boton)
	
