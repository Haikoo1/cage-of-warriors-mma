# Roda a suíte de testes headless. Uso: .\tests\run_tests.ps1 [-Godot caminho\para\godot.exe]
param([string]$Godot = $env:GODOT_EXE)
if (-not $Godot) { Write-Error "Informe -Godot ou defina a variável GODOT_EXE"; exit 2 }
$root = Split-Path -Parent $PSScriptRoot
& $Godot --headless --path $root --import | Out-Null
$out = & $Godot --headless --path $root --script res://tests/runner/run_tests.gd 2>&1 | Out-String
Write-Output $out
if ($LASTEXITCODE -ne 0 -or $out -match "SCRIPT ERROR|Parse Error") { exit 1 }
exit 0
