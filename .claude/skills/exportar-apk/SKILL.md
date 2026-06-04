---
name: exportar-apk
description: Regenerar el APK de Android de Void Sentinel. Úsala cuando el usuario quiera exportar, compilar, generar el APK o hacer una build para probar en el móvil.
---

# Exportar el APK de Android

El preset de export ya está configurado en `export_presets.cfg`:
- **Nombre del preset:** `voidsentinel`
- **Plataforma:** Android, arquitectura `arm64-v8a` (solo).
- **Salida:** `export_path="../..//void-sentinelv0.3.apk"` (relativo al proyecto;
  sube dos carpetas — confírmalo con el usuario y actualiza la versión del nombre).
- **Firmado:** `package/signed=true` → necesita keystore configurado en el editor.

## Requisitos previos (verificar con el usuario)
1. **Godot** instalado y accesible. Pregunta la ruta del ejecutable si no se conoce
   (no asumas que `godot` está en el PATH en Windows).
2. **Android Build Template** instalado en el editor (Project → Install Android Build
   Template) y el **Android SDK / keystore de debug** configurados en
   Editor Settings → Export → Android. Sin esto el export falla.
3. Subir la **versión** en el nombre del APK y en `version/code` / `version/name`
   si es una build nueva para distribuir.

## Exportar por línea de comandos
Desde la carpeta del proyecto (la que tiene `project.godot`):
```powershell
& "C:\ruta\a\Godot.exe" --headless --path . --export-release "voidsentinel" "..\..\void-sentinelv0.4.apk"
```
- `--export-release` para build firmada de release; `--export-debug` para pruebas.
- El nombre del preset entre comillas debe ser **exactamente** `voidsentinel`.
- Revisa la salida: errores de keystore o de template son lo más común.

## Alternativa (recomendada si hay dudas)
Sugerir al usuario exportar **desde el editor**: Project → Export → seleccionar
`voidsentinel` → "Export Project". Es más fiable que el CLI cuando el keystore o el
template no están bien configurados, y muestra los errores de forma clara.

## Después de exportar
- Verifica que el `.apk` se generó en la ruta esperada y comenta su tamaño.
- Recuérdale al usuario probar en un dispositivo real (vertical 720×1280) antes de
  considerar la build válida (Bloque A5 del ROADMAP).

## Avisos
- No subas el keystore ni contraseñas al repo.
- Esto es una acción de build hacia fuera: confirma con el usuario antes de
  sobrescribir un APK existente o cambiar la versión.
