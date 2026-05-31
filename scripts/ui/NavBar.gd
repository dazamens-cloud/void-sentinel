extends PanelContainer

# ============================================================================
# NAVBAR - Barra de navegación inferior
# ============================================================================

signal tab_pressed(tab)

# Colores activo / inactivo por pestaña
const COLOR_ACTIVE = {
	0: Color(0.0, 0.898, 1.0),    # Home    → Cian
	1: Color(0.961, 0.651, 0.137), # Nexus   → Gold
	2: Color(1.0, 0.42, 0.0),     # Forja   → Naranja
	3: Color(0.482, 0.188, 1.0),  # Perfil  → Morado
	4: Color(1.0, 0.42, 0.0),     # Tienda  → Naranja
}
const COLOR_INACTIVE = Color(0.165, 0.165, 0.251)

var forja_unlocked: bool = false

@onready var buttons = [
	$HBox/BtnHome,
	$HBox/BtnNexus,
	$HBox/BtnForja,
	$HBox/BtnPerfil,
	$HBox/BtnTienda,
]

@onready var lock_icon = $HBox/BtnForja/VBox/LockIcon

func _ready():
	# Fondo de la navbar
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.043, 0.043, 0.094)
	style.border_color = Color(0.078, 0.078, 0.157)
	style.border_width_top = 1
	add_theme_stylebox_override("panel", style)
	
	# Conectar botones
	$HBox/BtnHome.pressed.connect(func(): _emit_tab(0))
	$HBox/BtnNexus.pressed.connect(func(): _emit_tab(1))
	$HBox/BtnForja.pressed.connect(func(): _emit_tab(2))
	$HBox/BtnPerfil.pressed.connect(func(): _emit_tab(3))
	$HBox/BtnTienda.pressed.connect(func(): _emit_tab(4))
	
	# Comprobar si la Forja está desbloqueada
	_check_forja_unlock()

func _emit_tab(index: int) -> void:
	tab_pressed.emit(index)

func set_active_tab(tab: int) -> void:
	for i in buttons.size():
		var label = buttons[i].get_node("VBox/Label")
		var color = COLOR_ACTIVE[i] if i == tab else COLOR_INACTIVE
		label.add_theme_color_override("font_color", color)
		# Aquí se cambiaría también el color del icono cuando tengamos assets

func _check_forja_unlock() -> void:
	var max_asc = Economia.numero_ascension
	forja_unlocked = max_asc >= 2000
	lock_icon.visible = not forja_unlocked

func unlock_forja() -> void:
	forja_unlocked = true
	lock_icon.visible = false
	# Animación de desbloqueo (pulso)
	var tween = create_tween()
	tween.tween_property(
		$HBox/BtnForja, "modulate",
		Color(1.0, 0.42, 0.0), 0.3
	)
