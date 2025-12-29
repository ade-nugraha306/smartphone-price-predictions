@echo off
setlocal EnableDelayedExpansion
title Smartphone Prediction - Windows Runner

echo =====================================
echo Checking system requirements...
echo =====================================

REM ===============================
REM OS (Windows assumed)
REM ===============================
echo Detected OS: windows

REM ===============================
REM FLUTTER CHECK
REM ===============================
where flutter >nul 2>nul
if errorlevel 1 (
    echo Flutter not found.
    echo Please install Flutter SDK:
    echo https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo Flutter found

REM ===============================
REM PYTHON CHECK
REM ===============================
where python >nul 2>nul
if errorlevel 1 (
    echo Python not found.
    echo Please install Python:
    echo https://www.python.org/downloads/
    pause
    exit /b 1
)

for /f "delims=" %%i in ('python --version') do set PYVER=%%i
echo Python found: %PYVER%

REM ===============================
REM BACKEND SETUP
REM ===============================
echo.
echo Setting up backend...
cd backend || exit /b 1

REM ---- Detect Conda ----
where conda >nul 2>nul
if not errorlevel 1 (
    echo Using Conda environment
    call conda activate smartphone-prediction
    goto BACKEND_READY
)

REM ---- Detect venv ----
if exist "venv\Scripts\activate.bat" (
    echo Using existing venv
    call venv\Scripts\activate.bat
    goto BACKEND_READY
)

REM ---- Create venv ----
echo Creating Python venv...
python -m venv venv
if errorlevel 1 (
    echo Failed to create venv
    pause
    exit /b 1
)

call venv\Scripts\activate.bat

:BACKEND_READY
echo Upgrading pip...
pip install --upgrade pip

echo Installing backend requirements...
pip install -r requirements.txt
if errorlevel 1 (
    echo Failed to install backend dependencies
    pause
    exit /b 1
)

echo Starting FastAPI backend...
start "FastAPI Backend" cmd /k "uvicorn app:app --reload"

timeout /t 2 >nul
cd ..

REM ===============================
REM FRONTEND SETUP
REM ===============================
echo.
echo Setting up Flutter frontend...
cd frontend || exit /b 1

flutter clean
flutter pub get

echo Using Flutter device: windows

flutter build windows
flutter run -d windows

cd ..

echo =====================================
echo Application started successfully!
echo =====================================
pause
