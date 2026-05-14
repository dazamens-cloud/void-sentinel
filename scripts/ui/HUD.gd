# res://scripts/ui/hud.gd
# Actualiza UI basada en señales de los autoloads.

extends CanvasLayer

@onready var lbl_oleada: Label = $PanelSuperior/LblOleada
@onready var lbl_dinero: Label = $PanelSuperior/LblDinero
@onready var lbl_vida: Label = $PanelSuperior/LblVida

func _ready() -> void:
	print("HUD: _ready() llamado")
	
	# Conectar señales
	Economia.recursos_actualizados.connect(_actualizar_dinero)
	Economia.oleada_cambiada.connect(_actualizar_oleada)
	TorreStats.vida_cambiada.connect(_actualizar_vida)
	
	# Actualizar valores iniciales
	_actualizar_dinero()
	_actualizar_oleada(0)
	_actualizar_vida(TorreStats.vida_actual, TorreStats.get_salud())
	
	print("HUD: Conexiones realizadas. Vida inicial: ", TorreStats.vida_actual)

func _actualizar_dinero() -> void:
	var nuevo_texto = "$ %d" % int(Economia.efectivo)
	lbl_dinero.text = nuevo_texto
	print("HUD: Dinero actualizado a ", nuevo_texto)

func _actualizar_oleada(numero: int) -> void:
	var nuevo_texto = "Oleada: %d" % numero
	lbl_oleada.text = nuevo_texto
	print("HUD: Oleada actualizada a ", nuevo_texto)

func _actualizar_vida(actual: float, maxima: float) -> void:
	var nuevo_texto = "HP: %d / %d" % [int(actual), int(maxima)]
	lbl_vida.text = nuevo_texto
	print("HUD: Vida actualizada a ", nuevo_texto)
