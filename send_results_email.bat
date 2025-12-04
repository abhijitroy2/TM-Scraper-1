@echo off
REM Email Results Batch File
REM Wrapper to call PowerShell email script

REM Set the working directory to the script's directory
cd /d "%~dp0"

REM Get workflow log file path if provided
set WORKFLOW_LOG=%~1

REM Run PowerShell script to send email and capture both stdout and stderr
powershell.exe -ExecutionPolicy Bypass -File "%~dp0send_email.ps1" "%WORKFLOW_LOG%" 2>&1
set PS_EXIT_CODE=%ERRORLEVEL%

REM PowerShell exit codes: 0 = success, non-zero = failure
if %PS_EXIT_CODE% NEQ 0 (
    exit /b %PS_EXIT_CODE%
)

exit /b 0

