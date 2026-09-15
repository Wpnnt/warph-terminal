@echo off
setlocal
echo ======================================================
echo  Warph Terminal - Launching Setup
echo ======================================================
where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
) else (
    echo [ERROR] PowerShell 7 (pwsh.exe) is required but was not found.
    echo Please install PowerShell 7 using:
    echo   winget install Microsoft.PowerShell
    echo.
    pause
)
