# ═══════════════════════════════════════════════════
# Lanza las baterías de pruebas headless de Void Sentinel.
#
#   powershell -File tools\tests\ejecutar-pruebas.ps1
#
# Respalda user:// ANTES y lo restaura DESPUÉS, desde fuera de Godot: los
# autoloads (MisionesManager, Economia) guardan al cerrarse, después de que
# cualquier restauración interna haya corrido, así que hacerlo desde dentro
# del propio test no basta para dejar la partida del jugador intacta.
# ═══════════════════════════════════════════════════

$ErrorActionPreference = 'Stop'

$godot = if ($env:GODOT) { $env:GODOT } else { "$env:USERPROFILE\bin\godot.exe" }
if (-not (Test-Path $godot)) {
    Write-Host "No encuentro Godot en $godot. Define la variable GODOT con la ruta." -ForegroundColor Red
    exit 1
}

$proyecto = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$userDir  = "$env:APPDATA\Godot\app_userdata\Void Sentinel"
$backup   = Join-Path $env:TEMP "void-sentinel-save-backup"

# ── Respaldo ────────────────────────────────────────
if (Test-Path $userDir) {
    if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Get-ChildItem "$userDir\*.save" -ErrorAction SilentlyContinue |
        Copy-Item -Destination $backup
    $n = (Get-ChildItem "$backup\*.save" -ErrorAction SilentlyContinue).Count
    Write-Host "Guardado respaldado ($n ficheros) en $backup"
}

# ── Pruebas ─────────────────────────────────────────
$suites = @('TestSistemas', 'TestPantallas', 'TestCombate', 'TestProgresion')
$fallos = 0

foreach ($s in $suites) {
    Write-Host ""
    Write-Host "--- $s ---" -ForegroundColor Cyan
    # Start-Process con -RedirectStandardOutput: capturar por tubería deja la
    # salida vacía y "2>&1" la envolvería en ErrorRecords en PowerShell 5.1.
    $log = Join-Path $env:TEMP "vs-test-$s.log"
    # La ruta del proyecto lleva espacios ("proyectos godot"): Start-Process no
    # entrecomilla los argumentos, así que hay que hacerlo a mano o Godot recibe
    # la ruta cortada por el primer espacio y aborta.
    $p = Start-Process -FilePath $godot -Wait -NoNewWindow -PassThru `
        -RedirectStandardOutput $log `
        -ArgumentList @('--path', "`"$proyecto`"", '--headless', "tools/tests/$s.tscn")
    $lineas = if (Test-Path $log) { Get-Content $log -Encoding UTF8 } else { @() }
    # -CaseSensitive y con los dos puntos: sin ello, "0 fallos" del resumen
    # casaba con el patrón y toda batería en verde se contaba como fallida.
    $malas = $lineas | Select-String 'FALLO:' -CaseSensitive
    foreach ($m in $malas) { Write-Host $m.Line -ForegroundColor Red }
    $resumen = $lineas | Select-String 'RESULTADO' | Select-Object -Last 1
    if ($resumen) {
        Write-Host $resumen.Line.Trim()
    } else {
        # Sin línea de resultado la batería no llegó al final: es un fallo,
        # no un silencio que se pueda dar por bueno.
        Write-Host "SIN RESULTADO: la bateria no termino (ver $log)" -ForegroundColor Red
        $fallos++
    }
    if ($malas.Count -gt 0) { $fallos++ }
}

# ── Restauración ────────────────────────────────────
if (Test-Path $backup) {
    Get-ChildItem "$backup\*.save" -ErrorAction SilentlyContinue |
        Copy-Item -Destination $userDir -Force
    # Los ficheros que el test creó y no existían antes se retiran.
    foreach ($f in Get-ChildItem "$userDir\*.save" -ErrorAction SilentlyContinue) {
        if (-not (Test-Path (Join-Path $backup $f.Name))) { Remove-Item $f.FullName -Force }
    }
    Write-Host ""
    Write-Host "Guardado del jugador restaurado." -ForegroundColor Green
}

Write-Host ""
if ($fallos -eq 0) {
    Write-Host "TODAS LAS BATERIAS EN VERDE" -ForegroundColor Green
} else {
    Write-Host "$fallos baterias con fallos" -ForegroundColor Red
}
exit $fallos
