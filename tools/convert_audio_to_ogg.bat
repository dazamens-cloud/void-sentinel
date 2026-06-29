@echo off
REM ═══════════════════════════════════════════════════
REM CONVERSOR DE AUDIO WAV → OGG para Windows
REM Void Sentinel
REM ═══════════════════════════════════════════════════

echo.
echo 🎵 Convertidor de Audio WAV a OGG
echo.

REM Verificar si Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python no está instalado o no está en PATH
    echo.
    echo Para instalar Python:
    echo   https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

REM Verificar si ffmpeg está instalado
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  ffmpeg no está instalado o no está en PATH
    echo.
    echo Para instalar ffmpeg:
    echo   - Windows: Descargar desde https://ffmpeg.org/download.html
    echo   - O usar: choco install ffmpeg (si tienes Chocolatey)
    echo.
    pause
    exit /b 1
)

echo ✅ Python y ffmpeg detectados
echo.

REM Ejecutar script Python
python "%~dp0convert_audio_to_ogg.py"

if errorlevel 1 (
    echo.
    echo ❌ Conversión falló
    pause
    exit /b 1
) else (
    echo.
    echo ✅ Conversión completada
    echo 📝 Actualiza Godot (Assets → Reimport) para que detecte los OGG
    pause
)
