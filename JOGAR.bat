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
echo  O jogo e o arquivo KikoWildFuryMatajava.exe nesta pasta.
echo  Clique duas vezes nele. Este .bat nao e necessario.
echo.
pause
