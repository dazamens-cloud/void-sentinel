extends CanvasLayer
# ═══════════════════════════════════════════════════
# TUTORIAL OVERLAY — Void Sentinel
# Tutorial de primera partida: 3 pantallas modales que explican las
# mecánicas básicas (Nexus, energía/mejoras/dron, ascensiones/Commander).
#
# Se construye 100% por código (igual que Interfaz.gd) para no depender
# del editor. Pausa el árbol mientras está visible y, al terminar, marca
# el flag persistente en user://tutorial.save para no volver a mostrarse.
#
# Uso:
#   if TutorialOverlay.debe_mostrar():
#       var t = preload("res://scripts/ui/TutorialOverlay.gd").new()
#       add_child(t)   # él solito se encarga de pausar/despausar y guardar
# ═══════════════════════════════════════════════════

const RUTA_SAVE := "user://tutorial.save"

# ── Contenido de las pantallas ───────────────────────
# Cada slide: título, icono grande y cuerpo de texto.
const SLIDES := [
	{
		"icono": "🛰️",
		"titulo": "Tu Nexus",
		"cuerpo": "El núcleo del centro es tu [b]Nexus[/b]. Dispara solo a los Espectros que se acercan.\n\nSi demasiados Espectros lo alcanzan, su vida ❤️ baja. Si llega a cero, [b]pierdes la partida[/b].",
	},
	{
		"icono": "⚡",
		"titulo": "Energía y Mejoras",
		"cuerpo": "Cada Espectro destruido te da [b]energía[/b] ⚡. Gástala en el panel de [b]Mejoras[/b] para reforzar tu Nexus: más daño, cadencia, vida...\n\nEl [b]Dron[/b] 🤖 recoge fragmentos 💎 automáticamente y los lleva al Nexus.",
	},
	{
		"icono": "🌌",
		"titulo": "Asciende y resiste",
		"cuerpo": "Sobrevive a las oleadas para [b]ascender[/b]: cada ascensión te hace más fuerte y sube el nivel de la amenaza.\n\nCuando aparezca un [b]COMMANDER[/b], arrástralo con el dedo para lanzarle disparos especiales.\n\n¡Buena suerte, Sentinel!",
	},
]

var _indice: int = 0

# ── Nodos reconstruidos en cada slide ────────────────
var _lbl_icono: Label
var _lbl_titulo: Label
var _lbl_cuerpo: RichTextLabel
var _lbl_paso: Label
var _btn_siguiente: Button

# ═══════════════════════════════════════════════════
# API estática de persistencia
# ═══════════════════════════════════════════════════
static func ya_visto() -> bool:
	return FileAccess.file_exists(RUTA_SAVE)

# Debe mostrarse solo si nunca se ha visto antes.
static func debe_mostrar() -> bool:
	return not ya_visto()

static func _marcar_visto() -> void:
	var file := FileAccess.open(RUTA_SAVE, FileAccess.WRITE)
	if file:
		file.store_var({"visto": true})
		file.close()

# ═══════════════════════════════════════════════════
func _ready() -> void:
	# Por encima de todo y respondiendo aunque el árbol esté en pausa.
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_construir()
	_mostrar_slide(0)

func _construir() -> void:
	# Fondo oscuro que bloquea el input del juego de fondo.
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.03, 0.08, 0.92)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	# Icono grande
	_lbl_icono = Label.new()
	_lbl_icono.add_theme_font_size_override("font_size", 90)
	_lbl_icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_icono.size = Vector2(640, 120)
	_lbl_icono.position = Vector2(40, 280)
	add_child(_lbl_icono)

	# Título
	_lbl_titulo = Label.new()
	_lbl_titulo.add_theme_font_size_override("font_size", 44)
	_lbl_titulo.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.size = Vector2(640, 60)
	_lbl_titulo.position = Vector2(40, 410)
	add_child(_lbl_titulo)

	# Cuerpo (RichText para usar negritas [b]...[/b])
	_lbl_cuerpo = RichTextLabel.new()
	_lbl_cuerpo.bbcode_enabled = true
	_lbl_cuerpo.fit_content = true
	_lbl_cuerpo.scroll_active = false
	_lbl_cuerpo.add_theme_font_size_override("normal_font_size", 26)
	_lbl_cuerpo.add_theme_font_size_override("bold_font_size", 26)
	_lbl_cuerpo.add_theme_color_override("default_color", Color(0.9, 0.92, 0.95))
	_lbl_cuerpo.size = Vector2(560, 360)
	_lbl_cuerpo.position = Vector2(80, 500)
	add_child(_lbl_cuerpo)

	# Indicador de paso ("1 / 3")
	_lbl_paso = Label.new()
	_lbl_paso.add_theme_font_size_override("font_size", 22)
	_lbl_paso.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	_lbl_paso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_paso.size = Vector2(640, 40)
	_lbl_paso.position = Vector2(40, 930)
	add_child(_lbl_paso)

	# Botón "Saltar" (esquina superior derecha)
	var btn_saltar := Button.new()
	btn_saltar.text = "Saltar ✕"
	btn_saltar.add_theme_font_size_override("font_size", 22)
	btn_saltar.size = Vector2(140, 56)
	btn_saltar.position = Vector2(720 - 140 - 24, 60)
	btn_saltar.pressed.connect(_cerrar)
	add_child(btn_saltar)

	# Botón principal "Siguiente" / "Empezar"
	_btn_siguiente = Button.new()
	_btn_siguiente.add_theme_font_size_override("font_size", 30)
	_btn_siguiente.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	_btn_siguiente.size = Vector2(420, 80)
	_btn_siguiente.position = Vector2((720 - 420) / 2.0, 1000)
	_btn_siguiente.pressed.connect(_avanzar)
	add_child(_btn_siguiente)

func _mostrar_slide(idx: int) -> void:
	_indice = idx
	var slide: Dictionary = SLIDES[idx]
	_lbl_icono.text = slide["icono"]
	_lbl_titulo.text = slide["titulo"]
	_lbl_cuerpo.text = slide["cuerpo"]
	_lbl_paso.text = "%d / %d" % [idx + 1, SLIDES.size()]
	_btn_siguiente.text = "EMPEZAR ▶" if idx == SLIDES.size() - 1 else "SIGUIENTE →"

func _avanzar() -> void:
	if _indice >= SLIDES.size() - 1:
		_cerrar()
	else:
		_mostrar_slide(_indice + 1)

func _cerrar() -> void:
	_marcar_visto()
	get_tree().paused = false
	queue_free()
