@echo off
REM Trade Me Scraper Batch File
REM This file can be scheduled using Windows Task Scheduler

REM Set the working directory to the script's directory
cd /d "%~dp0"

REM Set log file with timestamp
set LOGFILE=logs\scraper_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set LOGFILE=%LOGFILE: =0%

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Log start time
echo ======================================== >> "%LOGFILE%"
echo Scraper started at %date% %time% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

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
            echo ERROR: Python not found. Please ensure Python is installed and in PATH. >> "%LOGFILE%"
            echo ERROR: Python not found. Please ensure Python is installed and in PATH.
            exit /b 1
        )
    )
)

REM Run the Python script and log output
"%PYTHON_EXE%" main.py >> "%LOGFILE%" 2>&1

REM Check if Python script executed successfully
if %ERRORLEVEL% EQU 0 (
    echo. >> "%LOGFILE%"
    echo ======================================== >> "%LOGFILE%"
    echo Scraper completed successfully at %date% %time% >> "%LOGFILE%"
    echo ======================================== >> "%LOGFILE%"
) else (
    echo. >> "%LOGFILE%"
    echo ======================================== >> "%LOGFILE%"
    echo ERROR: Scraper failed with error code %ERRORLEVEL% at %date% %time% >> "%LOGFILE%"
    echo ======================================== >> "%LOGFILE%"
    exit /b %ERRORLEVEL%
)

exit /b 0

