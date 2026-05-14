extends CPUParticles2D
# ═══════════════════════════════════════════════════
# EXPLOSIÓN — Efecto visual de partículas
# (antes "explosion.gd")
# ═══════════════════════════════════════════════════

func _ready() -> void:
	emitting = true
	await finished
	queue_free()
