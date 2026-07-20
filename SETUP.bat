@echo off
:: ════════════════════════════════════════════════════
::   Ricoh Aficio 1515 PCL - Printer Setup Launcher
::   Run this as Administrator to install the printer
:: ════════════════════════════════════════════════════

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo  [!!] This script requires Administrator privileges.
    echo  [!!] Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo  Launching Ricoh Printer Setup...
echo.

:: Run the PowerShell script with bypass execution policy
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-RicohPrinter.ps1"

if %errorLevel% NEQ 0 (
    echo.
    echo  [ERR] Setup encountered an error. Check the output above.
    pause
)
