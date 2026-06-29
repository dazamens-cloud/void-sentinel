#!/usr/bin/env python3
# ═══════════════════════════════════════════════════
# CONVERSOR DE AUDIO WAV → OGG
# Void Sentinel — Reduce tamaño de audio
# ═══════════════════════════════════════════════════

import os
import sys
import subprocess
from pathlib import Path

AUDIO_DIR = Path(__file__).parent.parent / "res" / "audio"
QUALITY = 6  # OGG quality (0-9, higher = better but larger)

def convert_wav_to_ogg():
    """Convierte todos los WAV a OGG en res://audio/"""

    if not AUDIO_DIR.exists():
        print(f"❌ Carpeta {AUDIO_DIR} no existe")
        return False

    wav_files = list(AUDIO_DIR.glob("*.wav"))

    if not wav_files:
        print("✅ No hay archivos WAV para convertir")
        return True

    print(f"📁 Encontrados {len(wav_files)} archivos WAV en {AUDIO_DIR}")
    print(f"🔄 Convirtiendo a OGG (calidad {QUALITY})...\n")

    failed = []
    for wav_file in wav_files:
        ogg_file = wav_file.with_suffix(".ogg")

        print(f"  {wav_file.name} → {ogg_file.name}...", end=" ", flush=True)

        try:
            # Usar ffmpeg para convertir
            result = subprocess.run(
                ["ffmpeg", "-i", str(wav_file), "-q:a", str(QUALITY),
                 "-y", str(ogg_file)],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                # Obtener tamaños
                wav_size = wav_file.stat().st_size / (1024 * 1024)  # MB
                ogg_size = ogg_file.stat().st_size / (1024 * 1024)  # MB
                reduction = ((wav_size - ogg_size) / wav_size) * 100

                print(f"✅ ({wav_size:.1f}MB → {ogg_size:.1f}MB, -{reduction:.0f}%)")

                # Eliminar WAV original
                wav_file.unlink()
                print(f"    🗑️  Eliminado {wav_file.name}")
            else:
                print(f"❌ Error en conversión")
                failed.append(str(wav_file))

        except FileNotFoundError:
            print(f"❌ ffmpeg no instalado")
            failed.append(str(wav_file))
        except subprocess.TimeoutExpired:
            print(f"❌ Timeout (archivo muy grande)")
            failed.append(str(wav_file))
        except Exception as e:
            print(f"❌ {str(e)}")
            failed.append(str(wav_file))

    print()
    if failed:
        print(f"⚠️  {len(failed)} archivo(s) fallaron:")
        for f in failed:
            print(f"  - {f}")
        return False
    else:
        print(f"✅ Conversión completada exitosamente")
        print(f"🎉 Todos los archivos convertidos a OGG")
        return True

if __name__ == "__main__":
    success = convert_wav_to_ogg()
    sys.exit(0 if success else 1)
