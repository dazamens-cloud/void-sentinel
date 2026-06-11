extends Control
# ============================================================
# MainMenu.gd
# Orquestador principal del menu de Void Sentinel.
#
# ESCENA REQUERIDA (crear en Godot):
#   - Nodo raiz: Control  (nombre: MainMenu)
#   - Adjuntar este script
#   - En el Inspector del Control raiz:
#       Layout > Anchors Preset > Full Rect
#   - Guardar como res://scenes/ui/MainMenu.tscn
#
# Este script construye TODA la UI por codigo en _ready().
# No necesita hijos en la escena: los crea el.
#
# Las 5 pantallas (Home, Nexo, Forja, Perfil, Tienda) son
# scripts independientes que devuelven un Control ya montado.
# MainMenu las anade como hijas y muestra/oculta segun navegacion.
# ============================================================

# Referencias a las pantallas instanciadas.
var screens: Dictionary = {}
var current_screen: String = "home"

# Contenedor donde viven todas las pantallas (apiladas).
var screen_container: Control

# La NavBar inferior.
var navbar: Control


func _ready() -> void:
	# Asegurar que ocupamos toda la pantalla.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_background()
	_build_screens()
	_build_navbar()

	# Mostrar Home por defecto.
	navigate("home")


# ------------------------------------------------------------
# FONDO: color base + (opcional) campo de estrellas simple.
# ------------------------------------------------------------
func _build_background() -> void:
	# Fondo solido oscuro.
	var bg := ColorRect.new()
	bg.color = MenuTheme.BG_DEEP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Campo de estrellas por codigo (puntos sutiles).
	# Es un Control que dibuja estrellas en _draw().
	var stars := StarField.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars)


# ------------------------------------------------------------
# PANTALLAS: instancia las 5 y las apila en un contenedor.
# ------------------------------------------------------------
func _build_screens() -> void:
	screen_container = Control.new()
	screen_container.name = "ScreenContainer"
	screen_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Dejar hueco abajo para la NavBar (80px aprox).
	screen_container.offset_bottom = -86
	screen_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(screen_container)

	# Crear cada pantalla. Cada *Screen.gd expone build() -> Control.
	screens["home"]   = HomeScreenUI.new()
	screens["nexo"]   = NexoScreen.new()
	screens["forja"]  = ForjaScreenUI.new()
	screens["perfil"] = PerfilScreenUI.new()
	screens["tienda"] = TiendaScreenUI.new()
	screens["lab"]      = LabScreenUI.new()
	screens["misiones"] = MisionesScreenUI.new()

	# El Home puede pedir navegar a pantallas sin botón en la NavBar
	# (Laboratorio, Misiones...).
	screens["home"].nav_requested.connect(navigate)

	for key in screens.keys():
		var scr: Control = screens[key]
		scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scr.visible = false
		screen_container.add_child(scr)


# ------------------------------------------------------------
# NAVBAR: barra inferior. Orden Nexo - Forja - Home - Perfil - Tienda.
# ------------------------------------------------------------
func _build_navbar() -> void:
	navbar = NavBarUI.new()
	navbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	navbar.offset_top = -86
	# Conectar la senal de navegacion de la NavBar a este orquestador.
	navbar.screen_requested.connect(navigate)
	add_child(navbar)


# ------------------------------------------------------------
# NAVEGACION: muestra una pantalla y oculta las demas.
# ------------------------------------------------------------
func navigate(screen_name: String) -> void:
	if not screens.has(screen_name):
		push_warning("MainMenu: pantalla desconocida '%s'" % screen_name)
		return

	# Ocultar todas.
	for key in screens.keys():
		screens[key].visible = false

	# Mostrar la pedida con un fade simple.
	var target: Control = screens[screen_name]
	target.visible = true
	target.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 1.0, 0.20)

	current_screen = screen_name

	# Avisar a la NavBar para que marque el boton activo.
	if navbar and navbar.has_method("set_active"):
		navbar.set_active(screen_name)

	# Si la pantalla quiere refrescar datos al mostrarse, lo hace.
	if target.has_method("on_show"):
		target.on_show()


# ============================================================
# StarField: pequena clase interna para el fondo de estrellas.
# Dibuja puntos estaticos de distintos colores y tamanos.
# ============================================================
class StarField extends Control:
	var _stars: Array = []

	func _ready() -> void:
		_generate_stars()

	func _generate_stars() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 12345  # semilla fija = mismo patron siempre
		var colors := [
			Color(1, 1, 1, 0.8),
			Color(0, 0.898, 1, 0.6),
			Color(0.70, 0.53, 1, 0.6),
			Color(1, 0.84, 0.25, 0.5),
		]
		for i in range(60):
			_stars.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"r": rng.randf_range(0.5, 1.8),
				"c": colors[rng.randi() % colors.size()]
			})

	func _draw() -> void:
		var sz := size
		for s in _stars:
			var pos := Vector2(s["x"] * sz.x, s["y"] * sz.y)
			draw_circle(pos, s["r"], s["c"])

	# Redibujar si cambia el tamano (rotacion / resize).
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
