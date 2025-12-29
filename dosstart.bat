@echo off
title Smartphone Prediction Launcher

echo =====================================
echo  Smartphone Prediction - DOS Launcher
echo =====================================

REM Pindah ke root project (lokasi dos.bat)
cd /d "%~dp0"

REM -------------------------------
REM Deteksi Git Bash
REM -------------------------------
where bash >nul 2>nul
if %ERRORLEVEL%==0 (
    echo [INFO] Git Bash detected.
    echo [INFO] Launching via Git Bash...

    REM Jalankan dosscript.bat via Git Bash
    bash -lc "./script/dosscript.bat"
    exit /b
)

REM -------------------------------
REM Fallback: CMD / PowerShell
REM -------------------------------
echo [INFO] Running in Windows CMD / PowerShell
call "%~dp0script\dosscript.bat"
