extends PanelContainer

@export var mejora_id: String = ""
var mejora_manager = null

@onready var lbl_nombre: Label = $HBoxMain/InfoArea/LblNombre
@onready var lbl_nivel: Label = $HBoxMain/InfoArea/LblNivel
@onready var lbl_valor: Label = $HBoxMain/CompraArea/HBoxCompra/LblValor
@onready var btn_comprar: Button = $HBoxMain/CompraArea/HBoxCompra/BtnComprar
@onready var btn_x2: Button = $HBoxMain/CompraArea/HBoxBotones/BtnX2
@onready var btn_x5: Button = $HBoxMain/CompraArea/HBoxBotones/BtnX5
@onready var btn_max: Button = $HBoxMain/CompraArea/HBoxBotones/BtnMax
@onready var lbl_bloqueada: Label = $HBoxMain/CompraArea/LblBloqueada

func inicializar(manager) -> void:
	mejora_manager = manager
	refrescar()

func refrescar() -> void:
	if not mejora_manager or mejora_id.is_empty():
		return

	var data = mejora_manager.mejoras[mejora_id]
	var nivel = mejora_manager.get_nivel(mejora_id)
	var max_nivel = mejora_manager.get_max_nivel(mejora_id)
	var coste = mejora_manager.get_coste(mejora_id)
	var puede = mejora_manager.puede_comprar(mejora_id)
	var esta_bloq = mejora_manager.esta_bloqueada(mejora_id)

	lbl_nombre.text = data["nombre"]
	lbl_valor.text = _formatear_valor()
	btn_comprar.text = str(coste) + "⚡"
	lbl_nivel.text = "Nivel %d / %d" % [nivel, max_nivel]

	lbl_bloqueada.visible = esta_bloq
	btn_x2.visible = not esta_bloq
	btn_x5.visible = not esta_bloq
	btn_max.visible = not esta_bloq

	btn_comprar.disabled = not puede or esta_bloq
	btn_x2.disabled = not puede
	btn_x5.disabled = not puede
	btn_max.disabled = not puede

	if not btn_comprar.pressed.is_connected(_on_comprar_x1):
		btn_comprar.pressed.connect(_on_comprar_x1)
		btn_x2.pressed.connect(_on_comprar_x2)
		btn_x5.pressed.connect(_on_comprar_x5)
		btn_max.pressed.connect(_on_comprar_max)

func _on_comprar_x1() -> void: _comprar(1)
func _on_comprar_x2() -> void: _comprar(2)
func _on_comprar_x5() -> void: _comprar(5)

func _on_comprar_max() -> void:
	var cantidad = mejora_manager.get_max_nivel(mejora_id) - mejora_manager.get_nivel(mejora_id)
	if cantidad > 0:
		_comprar(cantidad)

func _comprar(cantidad: int) -> void:
	var compradas = mejora_manager.comprar_mejora(mejora_id, cantidad)
	if compradas > 0:
		refrescar()

func _formatear_valor() -> String:
	var valor = mejora_manager.get_valor(mejora_id)
	match mejora_id:
		"danio": return "+" + str(int(valor))
		"velocidad_ataque": return str(abs(valor)) + "s"
		"disparo_critico":
			var prob = valor * 100
			var danio = mejora_manager.get_valor_secundario(mejora_id) + 1.5
			return str(int(prob)) + "% / " + str(danio) + "x"
		"multidisparo": return "+" + str(int(valor))
		"rebote": return str(int(valor)) + " rebotes"
		"alcance_rebote": return "+" + str(int(valor)) + "px"
		"salud": return "+" + str(int(valor))
		"recuperacion": return "+" + str(valor) + "/s"
		"escudo": return "+" + str(int(valor))
		"dureza_escudo": return "-" + str(int(abs(valor) * 100)) + "%"
		"pulso_quartz": return str(int(valor)) + "px"
		"poder_pulso":
			var lentitud = valor
			var empuje = mejora_manager.get_valor_secundario(mejora_id) * 100
			return str(lentitud) + "s / +" + str(int(empuje)) + "%"
		_: return "+" + str(valor)
