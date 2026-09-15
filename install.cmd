@echo off
setlocal
echo ======================================================
echo  Warph Terminal - Launching Setup
echo ======================================================

:: 1. Check PowerShell 7 (REQUIRED)
where pwsh >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] PowerShell 7 (pwsh.exe) is REQUIRED but was not found.
    echo.
    set /p INSTALL_PWSH="Install PowerShell 7 now via winget? [Y/n]: "
    if /i not "%INSTALL_PWSH%"=="n" (
        echo Installing PowerShell 7 via winget...
        winget install --id Microsoft.PowerShell -e --source winget --accept-package-agreements --accept-source-agreements
        echo.
        echo Please restart this installer or open a new terminal window once installation finishes.
        pause
        exit /b 0
    ) else (
        echo [ERROR] Cannot proceed without PowerShell 7.
        pause
        exit /b 1
    )
)

:: 2. Check Windows Terminal (REQUIRED)
where wt >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] Windows Terminal is REQUIRED (legacy console cannot render glyphs, true-color or SVG icons).
    echo.
    set /p INSTALL_WT="Install Windows Terminal now via winget? [Y/n]: "
    if /i not "%INSTALL_WT%"=="n" (
        echo Installing Windows Terminal via winget...
        winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements
    )
)

:: 3. Launch Setup
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

