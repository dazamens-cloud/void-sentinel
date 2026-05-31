extends Control
# ═══════════════════════════════════════════════════
# LOADING SCREEN — Pantalla de carga simulada
# ═══════════════════════════════════════════════════

@onready var barra: ProgressBar = $Fondo/Centro/Barra
@onready var lbl_tip: Label = $Fondo/Centro/LblTip

const TIPS = [
	"Recuerda mejorar también tu salud.\nNo todo es ataque.",
	"Los Ecos son tu futuro.\nNo los desperdicies.",
	"El Commander es peligroso.\nMátalo antes de que llame a más.",
	"¿Llevas rato sin mejorar defensa?\nMal asunto.",
	"El Dron recoge por ti.\nDéjalo trabajar.",
	"No estás preparado para esto.\nRíndete. (Es broma. O no.)",
	"Los Kamikaze son rápidos.\nTú eres más lento de lo que crees.",
	"Cada 5 kills ganas un Eco.\nCuéntalos.",
	"El interés compuesto es tu amigo.\nAhorra energía.",
	"El Sniper dispara desde lejos.\nÉl sí tiene puntería.",
]

func _ready() -> void:
	lbl_tip.text = TIPS[randi() % TIPS.size()]
	barra.value = 0

	var tween = create_tween()
	tween.tween_property(barra, "value", 100.0, 1.8)
	tween.tween_interval(0.2)
	tween.tween_callback(_entrar_al_juego)

func _entrar_al_juego() -> void:
	get_tree().change_scene_to_file("res://escenas/mundo.tscn")
