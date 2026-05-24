extends Control

@onready var btn_toggle: Button = $BarraTitulo/BtnToggle
@onready var btn_ataque: Button = $Contenido/Tabs/BtnAtaque
@onready var btn_defensa: Button = $Contenido/Tabs/BtnDefensa
@onready var btn_bonificacion: Button = $Contenido/Tabs/BtnBonificacion
@onready var btn_commander: Button = $Contenido/Tabs/BtnCommander
@onready var contenido: Control = $Contenido

@onready var ataque_container: GridContainer = $Contenido/ScrollContainer/MejorasContainer/AtaqueContainer
@onready var defensa_container: GridContainer = $Contenido/ScrollContainer/MejorasContainer/DefensaContainer
@onready var bonificacion_container: GridContainer = $Contenido/ScrollContainer/MejorasContainer/BonificacionContainer
@onready var commander_container: GridContainer = $Contenido/ScrollContainer/MejorasContainer/CommanderContainer

var mejora_manager = null
var categoria_actual: String = "ataque"
var expandido: bool = true

func _ready() -> void:
	mejora_manager = get_node("/root/MejoraManager")
	if not mejora_manager:
		print("ERROR: MejoraManager no encontrado")
		return

	for container in [ataque_container, defensa_container, bonificacion_container, commander_container]:
		for card in container.get_children():
			card.inicializar(mejora_manager)

	btn_toggle.pressed.connect(_toggle_panel)
	btn_ataque.pressed.connect(func(): cambiar_categoria("ataque"))
	btn_defensa.pressed.connect(func(): cambiar_categoria("defensa"))
	btn_bonificacion.pressed.connect(func(): cambiar_categoria("bonificacion"))
	btn_commander.pressed.connect(func(): cambiar_categoria("commander"))

	mejora_manager.mejoras_actualizadas.connect(_actualizar_ui)
	if Economia.has_signal("energia_cambiada"):
		Economia.energia_cambiada.connect(_actualizar_ui)

	cambiar_categoria("ataque")
	_expandir(true)

func _toggle_panel() -> void:
	expandido = not expandido
	_expandir(expandido)

func _expandir(estado: bool) -> void:
	expandido = estado
	contenido.visible = estado
	btn_toggle.text = "▲" if estado else "▼"
	custom_minimum_size = Vector2(620, 550) if estado else Vector2(620, 50)

func cambiar_categoria(categoria: String) -> void:
	categoria_actual = categoria
	_actualizar_botones()
	ataque_container.visible = (categoria == "ataque")
	defensa_container.visible = (categoria == "defensa")
	bonificacion_container.visible = (categoria == "bonificacion")
	commander_container.visible = (categoria == "commander")

func _actualizar_botones() -> void:
	btn_ataque.modulate = Color(1, 1, 1) if categoria_actual == "ataque" else Color(0.6, 0.6, 0.6)
	btn_defensa.modulate = Color(1, 1, 1) if categoria_actual == "defensa" else Color(0.6, 0.6, 0.6)
	btn_bonificacion.modulate = Color(1, 1, 1) if categoria_actual == "bonificacion" else Color(0.6, 0.6, 0.6)
	btn_commander.modulate = Color(1, 1, 1) if categoria_actual == "commander" else Color(0.6, 0.6, 0.6)

func _actualizar_ui(_valor: float = 0.0) -> void:
	for container in [ataque_container, defensa_container, bonificacion_container, commander_container]:
		for card in container.get_children():
			card.refrescar()

func abrir() -> void:
	visible = true
	_expandir(true)
	_actualizar_ui()

func cerrar() -> void:
	_expandir(false)
