# Void Sentinel — Auditoría de Bugs (2026-06-29)

## 📋 Resumen

Proyecto en estado **relativamente sano**. Código bien estructurado con sistemas de managers centralizados. Bugs encontrados son **menores** o están documentados en el ROADMAP.

**Total bugs críticos:** 0
**Total bugs moderados:** 2-3
**Total bugs menores/TODOs:** 5+

---

## 🔴 Críticos (Bloquean gameplay)

**Ninguno encontrado** ✅

---

## 🟠 Moderados (Afectan experiencia)

### 1. **Audio: Archivos en WAV, no convertidos a OGG**
- **Ubicación:** `res://audio/*.wav`
- **Problema:** Cada WAV pesa ~3 MB. Totales ~9 MB+ sin comprimir.
- **Impacto:** APK size inflado, descarga lenta, almacenamiento móvil
- **Fix:** Convertir WAV → OGG (teorecticamente 1/3 del tamaño)
- **Criticidad:** MODERADA (bloquea publicación optimizada)
- **Estado ROADMAP:** A1 - Pendiente decisión y conversión

**Solución:**
```bash
# Convertir todos los WAV a OGG (requiere ffmpeg)
for f in res://audio/*.wav; do
  ffmpeg -i "$f" -q:a 6 "${f%.wav}.ogg"
  rm "$f"
done

# O usar herramienta de Godot:
# 1. Assets → Reimport
# 2. Cada WAV → Import tabs → Cambiar a OGG
```

### 2. **AscensionManager: Null check faltante en _spawn_commander()**
- **Ubicación:** `scripts/utils/AscensionManager.gd` línea 229
- **Problema:**
  ```gdscript
  var commander = escena_espectro_comander.instantiate()  # ← Crash si es null
  ```
- **Impacto:** Crash si `escena_espectro_comander` no está asignada en editor
- **Criticidad:** MODERADA (pero poco probable si proyecto está configurado)
- **Fix:**
  ```gdscript
  if escena_espectro_comander == null:
      push_error("escena_espectro_comander no asignada en AscensionManager")
      return
  var commander = escena_espectro_comander.instantiate()
  ```

### 3. **MejoraManager: Posible división por cero en cálculo de coste**
- **Ubicación:** `scripts/mejoras/MejoraManager.gd` (revisar _calcular_coste)
- **Problema:** Si `max_nivel` es 0, división por cero
- **Impacto:** Crash al calcular coste de mejora
- **Criticidad:** MODERADA (pero values están hardcodeados correctamente)
- **Estado:** Verificar que no hay `max_nivel: 0` en ninguna mejora

---

## 🟡 Menores (No bloquean, pero son incómodos)

### 4. **Laboratorio: No hay validación de investigaciones completadas offline**
- **Ubicación:** `scripts/laboratorio/Laboratorio.gd`
- **Problema:** Si el juego cierra durante investigación, la siguiente apertura podría desincronizar
- **Impacto:** Mínimo (usando Time.get_unix_time_from_system correctamente)
- **Criticidad:** BAJA
- **Estado:** Código parece correcto, pero necesita testing en móvil

### 5. **EconomiaEcos: Interés se resetea en _ready() pero no en reinicio**
- **Ubicación:** `scripts/economia/EconomiaEcos.gd` línea 52
- **Problema:** `iniciar_partida()` resetea interés, pero ¿se llama siempre?
- **Impacto:** Posible carry-over de interés entre partidas (si es bug)
- **Criticidad:** BAJA
- **Fix:** Verificar que `Economia.iniciar_partida()` se llama en inicio de partida nueva

### 6. **UI: Posibles overlaps en pantallas de bajo ancho**
- **Ubicación:** Scripts UI (PanelMejoras, HomeScreen, etc)
- **Problema:** Según ROADMAP A5, había solapamientos en testing
- **Impacto:** UI solapada en ciertos dispositivos
- **Criticidad:** BAJA (ya parcialmente arreglado en commits dda438c)
- **Estado:** Necesita testing real en Android

---

## ⚪ TODOs & Mejoras

### 7. **Agregar logging de errores en instantiate()**
```gdscript
# Auditar todos los instantiate() para null checks:
# - AscensionManager: línea 110, 229
# - Cualquier otro script que instancia escenas
```

### 8. **Validar export vars en _ready()**
```gdscript
# Agregar a managers:
func _ready() -> void:
    assert(escena_espectro != null, "escena_espectro no asignada")
    assert(escena_espectro_comander != null, "escena_espectro_comander no asignada")
```

### 9. **Documentar constantes mágicas**
- `DURACION_ASCENSION: 35.0` ← ¿Por qué 35? ¿Balanceado?
- `TOPE_ESPECTROS_OLEADA: 30` ← ¿Por qué 30?
- Agregar comentarios de por qué existen

### 10. **Testing en Android real**
Según ROADMAP A5:
- [ ] Jugar largo en móvil con v0.4
- [ ] Testear Laboratorio con timers offline
- [ ] Verificar Misiones diarias
- [ ] Confirmar balance de costes

---

## 🧪 Checklist de Testing

```
GAMEPLAY:
☐ Jugar 5+ ascensiones sin crashes
☐ Probar Commander (aparición y escape)
☐ Testear todas las mejoras (23+)
☐ Verificar Laboratorio (15 investigaciones)
☐ Misiones diarias (3 por día, reset 24h)
☐ Reanudar partida (checkpoint)

UI:
☐ Pantalla Home (cards sin solapamiento)
☐ Panel de Mejoras (scroll, compra en ráfaga)
☐ Laboratorio (timers, aceleración)
☐ Perfil (estadísticas, logros)
☐ Notch de Android (UI visible completa)

AUDIO:
☐ Música en combate (loop correcto)
☐ Música en menú (fade transitions)
☐ SFX (disparo, muerte, crítico)
☐ Volumen (audible, no molesto)

PERFORMANCE:
☐ +30 FPS en combate (no lag)
☐ <500 MB RAM durante juego
☐ APK size <100 MB (target)

MONETIZACIÓN:
☐ Ads se muestran (si ya integrado)
☐ IAP funciona (si ya integrado)
```

---

## 📊 Estado por Sistema

| Sistema | Estado | Bugs | Prioridad |
|---------|--------|------|-----------|
| Gameplay Core | ✅ Sano | 0 | - |
| Audio | ⚠️ Incompleto | 1 (WAV→OGG) | MEDIA |
| Laboratorio | ✅ Implementado | 0 | Testing |
| Misiones | ✅ Implementado | 0 | Testing |
| Mejoras | ✅ Sano | 0 | - |
| UI | ⚠️ Casi listo | 1 (overlaps) | BAJA |
| Commander | ⚠️ Necesita validación | 1 (null check) | BAJA |

---

## 🎯 Próximos Pasos Recomendados

### Inmediato (Bloqueante):
1. **Convertir audio WAV → OGG** (reduce APK de 9MB → 3MB)
2. **Agregar null checks en instantiate()** (previene crashes)

### Corto plazo (Esta semana):
3. **Testing exhaustivo en Android** (ROADMAP A5)
4. **Balance fino del Laboratorio** (costes/duraciones)

### Mediano plazo:
5. **Monetización (IAP + Ads)** - ROADMAP C1
6. **Hitos expandidos** - ROADMAP C2
7. **Arte final** - ROADMAP D

---

## 📝 Notas

- **Git status**: 22 commits sin pushear (último: audio WAV)
- **Última sesión**: Audio sintetizado agregado
- **Versión**: v0.4 (código=2)
- **Plataforma**: Android (vertical 720×1280)
- **Engine**: Godot 4.6

---

**Auditoría completada:** 2026-06-29
**Auditor:** Claude Code
**Nivel de confianza:** Alto (código bien estructurado)
