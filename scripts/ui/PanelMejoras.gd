extends Control
# ═══════════════════════════════════════════════════
# PANEL MEJORAS — Retráctil (siempre visible en la parte inferior)
# ═══════════════════════════════════════════════════

@onready var btn_toggle: Button = $BarraTitulo/BtnToggle
@onready var btn_ataque: Button = $Contenido/Tabs/BtnAtaque
@onready var btn_defensa: Button = $Contenido/Tabs/BtnDefensa
@onready var btn_bonificacion: Button = $Contenido/Tabs/BtnBonificacion
@onready var btn_commander: Button = $Contenido/Tabs/BtnCommander
@onready var mejoras_container: VBoxContainer = $Contenido/ScrollContainer/MejorasContainer
@onready var contenido: Control = $Contenido

var mejora_manager = null
var categoria_actual: String = "ataque"
var expandido: bool = true

const MEJORAS_ATAQUE = ["danio", "velocidad_ataque", "disparo_critico", "multidisparo", "rebote", "alcance_rebote"]
const MEJORAS_DEFENSA = ["salud", "recuperacion", "escudo", "dureza_escudo", "pulso_quartz", "poder_pulso"]
const MEJORAS_BONIFICACION = ["energia_ascension", "energia_espectro", "ecos_ascension", "ecos_rapido", "mejora_ataque_gratis", "mejora_defensa_gratis", "mejora_bonificacion_gratis"]
const MEJORAS_COMMANDER = ["blindaje", "disparos_iniciales", "recarga_rapida", "lock_on"]

# ═══════════════════════════════════════════════════
func _ready() -> void:
	mejora_manager = get_node("/root/MejoraManager")
	if not mejora_manager:
		print("ERROR: MejoraManager no encontrado")
		return
	
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

func _expandir(abrir: bool) -> void:
	expandido = abrir
	contenido.visible = abrir
	btn_toggle.text = "▲" if abrir else "▼"
	
	if abrir:
		custom_minimum_size = Vector2(620, 550)
		offset_bottom = 1150
	else:
		custom_minimum_size = Vector2(620, 50)
		offset_bottom = 1150

func cambiar_categoria(categoria: String) -> void:
	categoria_actual = categoria
	_actualizar_botones()
	
	for child in mejoras_container.get_children():
		child.queue_free()
	
	var mejoras_ids = _get_mejoras_por_categoria(categoria)
	for mejora_id in mejoras_ids:
		var card = _crear_card_mejora(mejora_id)
		mejoras_container.add_child(card)

func _actualizar_botones() -> void:
	btn_ataque.modulate = Color(1, 1, 1) if categoria_actual == "ataque" else Color(0.6, 0.6, 0.6)
	btn_defensa.modulate = Color(1, 1, 1) if categoria_actual == "defensa" else Color(0.6, 0.6, 0.6)
	btn_bonificacion.modulate = Color(1, 1, 1) if categoria_actual == "bonificacion" else Color(0.6, 0.6, 0.6)
	btn_commander.modulate = Color(1, 1, 1) if categoria_actual == "commander" else Color(0.6, 0.6, 0.6)

func _get_mejoras_por_categoria(categoria: String) -> Array:
	match categoria:
		"ataque": return MEJORAS_ATAQUE
		"defensa": return MEJORAS_DEFENSA
		"bonificacion": return MEJORAS_BONIFICACION
		"commander": return MEJORAS_COMMANDER
	return []

func _crear_card_mejora(mejora_id: String) -> PanelContainer:
	var data = mejora_manager.mejoras[mejora_id]
	var nivel = mejora_manager.get_nivel(mejora_id)
	var max_nivel = mejora_manager.get_max_nivel(mejora_id)
	var coste = mejora_manager.get_coste(mejora_id)
	var puede = mejora_manager.puede_comprar(mejora_id)
	var esta_bloq = mejora_manager.esta_bloqueada(mejora_id)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var lbl_nombre = Label.new()
	lbl_nombre.text = data["nombre"]
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl_nombre)
	
	var lbl_valor = Label.new()
	lbl_valor.text = _formatear_valor(mejora_id, mejora_manager.get_valor(mejora_id))
	lbl_valor.add_theme_font_size_override("font_size", 16)
	lbl_valor.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	hbox.add_child(lbl_valor)
	
	var btn_comprar = Button.new()
	btn_comprar.text = str(coste, "⚡")
	btn_comprar.disabled = not puede or esta_bloq
	btn_comprar.pressed.connect(func(): _comprar_mejora(mejora_id, 1))
	hbox.add_child(btn_comprar)
	
	var hbox2 = HBoxContainer.new()
	vbox.add_child(hbox2)
	
	var lbl_nivel = Label.new()
	lbl_nivel.text = "Nivel %d / %d" % [nivel, max_nivel]
	lbl_nivel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nivel.add_theme_font_size_override("font_size", 12)
	lbl_nivel.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox2.add_child(lbl_nivel)
	
	if not esta_bloq:
		var btn_x2 = Button.new()
		btn_x2.text = "x2"
		btn_x2.disabled = not puede
		btn_x2.pressed.connect(func(): _comprar_mejora(mejora_id, 2))
		hbox2.add_child(btn_x2)
		
		var btn_x5 = Button.new()
		btn_x5.text = "x5"
		btn_x5.disabled = not puede
		btn_x5.pressed.connect(func(): _comprar_mejora(mejora_id, 5))
		hbox2.add_child(btn_x5)
		
		var btn_max = Button.new()
		btn_max.text = "MAX"
		btn_max.disabled = not puede
		btn_max.pressed.connect(func(): _comprar_max(mejora_id))
		hbox2.add_child(btn_max)
	else:
		var lbl_bloq = Label.new()
		lbl_bloq.text = "🔒 DESBLOQUEAR EN ASCENSIÓN 45"
		lbl_bloq.add_theme_font_size_override("font_size", 10)
		lbl_bloq.add_theme_color_override("font_color", Color.RED)
		hbox2.add_child(lbl_bloq)
	
	return card

func _comprar_mejora(mejora_id: String, cantidad: int) -> void:
	if not mejora_manager:
		return
	var compradas = mejora_manager.comprar_mejora(mejora_id, cantidad)
	if compradas > 0:
		print("✅ Compradas ", compradas, " mejoras de ", mejora_id)

func _comprar_max(mejora_id: String) -> void:
	if not mejora_manager:
		return
	var nivel_actual = mejora_manager.get_nivel(mejora_id)
	var max_nivel = mejora_manager.get_max_nivel(mejora_id)
	var cantidad = max_nivel - nivel_actual
	if cantidad > 0:
		_comprar_mejora(mejora_id, cantidad)

func _actualizar_ui() -> void:
	cambiar_categoria(categoria_actual)

func _formatear_valor(mejora_id: String, valor: float) -> String:
	match mejora_id:
		"danio":
			return "+" + str(int(valor))
		"velocidad_ataque":
			return str(abs(valor)) + "s"
		"disparo_critico":
			var prob = mejora_manager.get_valor(mejora_id) * 100
			var danio = mejora_manager.get_valor_secundario(mejora_id) + 1.5
			return str(int(prob)) + "% / " + str(danio) + "x"
		"multidisparo":
			return "+" + str(int(valor))
		"rebote":
			return str(int(valor)) + " rebotes"
		"alcance_rebote":
			return "+" + str(int(valor)) + "px"
		"salud":
			return "+" + str(int(valor))
		"recuperacion":
			return "+" + str(valor) + "/s"
		"escudo":
			return "+" + str(int(valor))
		"dureza_escudo":
			return "-" + str(int(abs(valor) * 100)) + "%"
		"pulso_quartz":
			return str(int(valor)) + "px"
		"poder_pulso":
			var lentitud = mejora_manager.get_valor(mejora_id)
			var empuje = mejora_manager.get_valor_secundario(mejora_id) * 100
			return str(lentitud) + "s / +" + str(int(empuje)) + "%"
		_:
			return "+" + str(valor)

func abrir() -> void:
	visible = true
	_expandir(true)
	_actualizar_ui()

func cerrar() -> void:
	_expandir(false)
