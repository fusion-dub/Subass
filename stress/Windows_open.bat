@echo off
chcp 65001 >nul
cls

echo ================================================
echo   🇺🇦 Ukrainian Stress Tool
echo ================================================
echo.

REM Get the directory where this batch file is located
cd /d "%~dp0"

REM Try to find Python
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    python ukrainian_stress_tool.py
) else (
    where python3 >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        python3 ukrainian_stress_tool.py
    ) else (
        echo ❌ Помилка: Python не знайдено!
        echo.
        echo Будь ласка, встановіть Python 3.9 або новіше:
        echo https://www.python.org/downloads/
        echo.
        echo Або встановіть через winget:
        echo winget install -e --id Python.Python.3.11
        echo.
        pause
        exit /b 1
    )
)

echo.
echo Сервер зупинено.
pause
