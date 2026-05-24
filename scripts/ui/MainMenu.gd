extends CanvasLayer

# ============================================================================
# MAIN MENU - Controlador principal de navegación del hub
# ============================================================================

enum Tab { HOME, NEXUS, FORJA, PERFIL, TIENDA }

var current_tab: Tab = Tab.HOME

@onready var screens = {
	Tab.HOME:   $Layout/ScreenContainer/HomeScreen,
	Tab.NEXUS:  $Layout/ScreenContainer/NexusScreen,
	Tab.FORJA:  $Layout/ScreenContainer/ForjaScreen,
	Tab.PERFIL: $Layout/ScreenContainer/PerfilScreen,
	Tab.TIENDA: $Layout/ScreenContainer/TiendaScreen,
}

@onready var navbar = $Layout/NavBar

func _ready():
	# Conectar señal de la NavBar
	navbar.tab_pressed.connect(_on_tab_pressed)
	
	# Mostrar Home por defecto
	switch_to(Tab.HOME)

func switch_to(tab: Tab) -> void:
	# Ocultar todas las pantallas
	for t in screens:
		screens[t].visible = false
	
	# Mostrar la pantalla seleccionada
	screens[tab].visible = true
	current_tab = tab
	
	# Notificar a la NavBar para actualizar iconos
	navbar.set_active_tab(tab)
	
	# Notificar a la pantalla que se acaba de mostrar
	if screens[tab].has_method("on_enter"):
		screens[tab].on_enter()

func _on_tab_pressed(tab: Tab) -> void:
	if tab == current_tab:
		return
	switch_to(tab)
