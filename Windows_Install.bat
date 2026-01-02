@echo off
setlocal
cd /d "%~dp0"

echo Requesting Administrator privileges...
powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0install\_w.ps1""' -Verb RunAs"

echo.
echo If the installer window closed immediately, there might be an error.
echo Make sure you are connected to the internet.
pause
