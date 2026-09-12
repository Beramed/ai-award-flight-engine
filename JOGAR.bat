@echo off
cd /d "%~dp0"
if exist "%~dp0KikoWildFuryMatajava.exe" (
  start "" "%~dp0KikoWildFuryMatajava.exe"
  exit /b 0
)
if exist "%~dp0dist\pc\KikoWildFuryMatajava.exe" (
  start "" "%~dp0dist\pc\KikoWildFuryMatajava.exe"
  exit /b 0
)
echo.
echo  Baixe o executavel:
echo  dist\pc\KikoWildFuryMatajava.exe
echo.
pause
