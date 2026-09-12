@echo off
cd /d "%~dp0"
setlocal
if exist "%~dp0godot\Godot_engine.exe" (
  start "" "%~dp0godot\Godot_engine.exe" --path "%~dp0"
  exit /b 0
)
for %%G in ("%~dp0godot\Godot*.exe") do (
  start "" "%%~G" --path "%~dp0"
  exit /b 0
)
where godot >nul 2>&1
if %errorlevel%==0 (
  start "" godot --path "%~dp0"
  exit /b 0
)
echo.
echo  Kiko: Wild Fury - Matajava
echo  Abra esta pasta no Godot 4.4+: Import ^> project.godot
echo.
pause
