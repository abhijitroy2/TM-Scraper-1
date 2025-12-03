@echo off
REM Simple batch file for Trade Me Scraper
REM Navigate to script directory and run Python script

cd /d "%~dp0"

REM Try to find Python executable
set PYTHON_EXE=
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set PYTHON_EXE=python
) else (
    where py >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set PYTHON_EXE=py
    ) else (
        if exist "C:\Users\OEM\AppData\Local\Python\pythoncore-3.14-64\python.exe" (
            set PYTHON_EXE=C:\Users\OEM\AppData\Local\Python\pythoncore-3.14-64\python.exe
        ) else (
            echo ERROR: Python not found. Please ensure Python is installed and in PATH.
            pause
            exit /b 1
        )
    )
)

"%PYTHON_EXE%" main.py

pause

