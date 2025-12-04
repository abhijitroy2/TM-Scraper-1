@echo off
setlocal enabledelayedexpansion
REM Scraper Workflow Batch File
REM Runs scraper and moves files to analyser input directory
REM Note: Analysis and email are handled by a separate batch file in the analyser directory

REM Set the working directory to the script's directory
cd /d "%~dp0"

REM Set log file with timestamp (use absolute path to avoid issues with directory changes)
REM Get fully qualified path using %CD% after changing to script directory
set "LOGFILE=%CD%\logs\workflow_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log"
set LOGFILE=%LOGFILE: =0%

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Set paths
set INPUT_DIR=C:\Users\OEM\NZ Property Analyser\input

REM Log start time
echo ======================================== >> "%LOGFILE%"
echo Full Workflow started at %date% %time% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

REM Step 1: Clean output directory (delete existing Excel files to ensure fresh scrape)
echo [%date% %time%] Step 1a: Cleaning output directory... >> "%LOGFILE%"
del /Q /F "output\*.xlsx" 2>nul
set DEL_OUTPUT_ERROR=%ERRORLEVEL%
if %DEL_OUTPUT_ERROR% EQU 0 (
    echo [%date% %time%] Step 1a: Output directory cleaned successfully >> "%LOGFILE%"
)
if %DEL_OUTPUT_ERROR% EQU 2 (
    echo [%date% %time%] Step 1a: Output directory is empty (no files to delete) >> "%LOGFILE%"
)
if %DEL_OUTPUT_ERROR% NEQ 0 if %DEL_OUTPUT_ERROR% NEQ 2 (
    echo [%date% %time%] WARNING: Some files may not have been deleted from output (Error: %DEL_OUTPUT_ERROR%) >> "%LOGFILE%"
)

REM Step 1: Run the scraper
echo [%date% %time%] Step 1b: Running scraper... >> "%LOGFILE%"
call run_scraper.bat >> "%LOGFILE%" 2>&1
set SCRAPER_ERROR=%ERRORLEVEL%
REM Ensure log file is still accessible after scraper call
echo. >> "%LOGFILE%"
if %SCRAPER_ERROR% NEQ 0 (
    echo [%date% %time%] ERROR: Scraper failed with error code %SCRAPER_ERROR% >> "%LOGFILE%"
    echo ERROR: Scraper failed. Aborting workflow.
    exit /b %SCRAPER_ERROR%
)
echo [%date% %time%] Step 1b: Scraper completed successfully >> "%LOGFILE%"
echo. >> "%LOGFILE%"

REM Step 2: Clean input directory (delete existing files)
echo [%date% %time%] Step 2: Cleaning input directory... >> "%LOGFILE%"
set STEP2_STATUS=SUCCESS
REM Ensure directory exists (create if it doesn't, ignore error if it does)
if not exist "%INPUT_DIR%" (
    echo [%date% %time%] Creating input directory: %INPUT_DIR% >> "%LOGFILE%"
    mkdir "%INPUT_DIR%" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        set STEP2_STATUS=ERROR
        echo [%date% %time%] ERROR: Failed to create input directory >> "%LOGFILE%"
        echo ERROR: Failed to create input directory. Aborting workflow.
        exit /b 1
    )
)
REM Delete all files in the directory
echo [%date% %time%] Deleting files from: %INPUT_DIR% >> "%LOGFILE%"
del /Q /F "%INPUT_DIR%\*.*" 2>nul
set DEL_ERROR=%ERRORLEVEL%
if %DEL_ERROR% EQU 0 (
    echo [%date% %time%] Step 2: Input directory cleaned successfully >> "%LOGFILE%"
)
if %DEL_ERROR% EQU 2 (
    echo [%date% %time%] Step 2: Input directory is empty (no files to delete) >> "%LOGFILE%"
)
if %DEL_ERROR% NEQ 0 if %DEL_ERROR% NEQ 2 (
    set STEP2_STATUS=WARNING
    echo [%date% %time%] WARNING: Some files may not have been deleted (Error: %DEL_ERROR%) >> "%LOGFILE%"
)

REM Step 3: Move Excel files from output to input directory
echo [%date% %time%] Step 3: Moving Excel files to input directory... >> "%LOGFILE%"
set FILES_MOVED=0
for %%f in (output\*.xlsx) do (
    if exist "%%f" (
        move /Y "%%f" "%INPUT_DIR%\" >> "%LOGFILE%" 2>&1
        set /a FILES_MOVED+=1
    )
)
echo [%date% %time%] Step 3: Moved %FILES_MOVED% file(s) to input directory >> "%LOGFILE%"

if %FILES_MOVED% EQU 0 (
    echo [%date% %time%] WARNING: No Excel files found to move >> "%LOGFILE%"
)

REM Step 4: Workflow complete - files moved to analyser input directory
echo [%date% %time%] Step 4: Files ready for analysis in analyser input directory >> "%LOGFILE%"
echo [%date% %time%] Next: Run analyser batch file to process files and send email >> "%LOGFILE%"

REM Log completion with summary
echo. >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo Full Workflow completed at %date% %time% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"
echo Execution Summary: >> "%LOGFILE%"
echo   Step 1 (Scraper): SUCCESS >> "%LOGFILE%"
echo   Step 2 (Clean Input): !STEP2_STATUS! >> "%LOGFILE%"
echo   Step 3 (Move Files): !FILES_MOVED! file(s) moved >> "%LOGFILE%"
echo   Step 4 (Ready for Analysis): Files in %INPUT_DIR% >> "%LOGFILE%"
echo ======================================== >> "%LOGFILE%"

exit /b 0

