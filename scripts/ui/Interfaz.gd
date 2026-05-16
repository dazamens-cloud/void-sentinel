extends CanvasLayer
# ═══════════════════════════════════════════════════
# INTERFAZ — UI principal de Void Sentinel
# ═══════════════════════════════════════════════════

@onready var lbl_ascension: Label = $PanelSuperior/LblOleada
@onready var lbl_energia: Label = $PanelSuperior/LblDinero
@onready var lbl_salud: Label = $PanelSuperior/LblVida

func _ready() -> void:
	Economia.recursos_actualizados.connect(_actualizar_energia)
	Economia.ascension_cambiada.connect(_actualizar_ascension)
	NexusStats.salud_cambiada.connect(_actualizar_salud)
	
	_actualizar_energia()
	_actualizar_ascension(0)
	_actualizar_salud(NexusStats.salud_actual, NexusStats.get_salud())

func _actualizar_energia() -> void:
	lbl_energia.text = "⚡ %d" % int(Economia.energia)
	print("💰 Energía actualizada: ", Economia.energia)

func _actualizar_ascension(numero: int) -> void:
	lbl_ascension.text = "Ascensión: %d" % numero

func _actualizar_salud(actual: float, maxima: float) -> void:
	lbl_salud.text = "❤️ %d / %d" % [int(actual), int(maxima)]
	print("❤️ Salud actualizada: ", actual, "/", maxima)
	
