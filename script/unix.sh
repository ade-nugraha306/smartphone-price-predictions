#!/usr/bin/env bash
set -e

echo "Checking system requirements..."

# ---------- OS DETECTION ----------
OS="$(uname -s)"
case "$OS" in
  Linux*)   HOST_OS="linux" ;;
  Darwin*)  HOST_OS="macos" ;;
  *)        echo "Unsupported OS: $OS"; exit 1 ;;
esac
echo "Detected OS: $HOST_OS"
echo ""

# ---------- MENU ----------
echo "Select build target:"
echo "1) Native App (default)"
echo "2) Android"
echo ""
read -rp "Enter choice [1-2]: " BUILD_CHOICE
BUILD_CHOICE=${BUILD_CHOICE:-1}

if [[ "$BUILD_CHOICE" != "1" && "$BUILD_CHOICE" != "2" ]]; then
  echo "Invalid choice"
  exit 1
fi

# ---------- FLUTTER CHECK ----------
FLUTTER=flutter

if ! command -v $FLUTTER &> /dev/null; then
  echo "Flutter not found."
  exit 1
fi

echo "Flutter found: $($FLUTTER --version)"

# ---------- PYTHON CHECK ----------
if command -v python3 &> /dev/null; then
  PYTHON=python3
elif command -v python &> /dev/null; then
  PYTHON=python
else
  echo "Python not found."
  exit 1
fi
echo "Python found: $($PYTHON --version)"

# ---------- BACKEND SETUP ----------
echo ""
echo "Setting up backend..."

# Simpan direktori root
ROOT_DIR="$(pwd)"

cd "$ROOT_DIR/backend"

if [[ ! -d "venv" ]]; then
  echo "Creating Python venv..."
  $PYTHON -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Starting FastAPI backend..."
uvicorn app:app --reload &
BACKEND_PID=$!
sleep 2

# Kembali ke root directory
cd "$ROOT_DIR"

# ---------- FRONTEND SETUP ----------
echo ""
echo "Setting up Flutter frontend..."
cd "$ROOT_DIR/frontend"

flutter clean
flutter pub get

# ---------- BUILD LOGIC ----------
if [[ "$BUILD_CHOICE" == "1" ]]; then
  echo ""
  echo "▶ Building Native App..."
  
  if [[ "$HOST_OS" == "linux" ]]; then
    DEVICE="linux"
  else
    DEVICE="macos"
  fi
  
  flutter build "$DEVICE"
  flutter run -d "$DEVICE"

else
  echo ""
  echo "▶ Building Android App..."
  
  # ---------- ANDROID PRECHECK ----------
  if ! command -v emulator &> /dev/null; then
    echo "Android emulator not found."
    echo "Install Android SDK & emulator first."
    exit 1
  fi
  
  if ! command -v adb &> /dev/null; then
    echo "adb not found."
    exit 1
  fi
  
  # ---------- AVD DETECTION ----------
  echo "Detecting Android Virtual Devices..."
  mapfile -t AVD_LIST < <(emulator -list-avds)
  AVD_COUNT=${#AVD_LIST[@]}
  
  if [[ "$AVD_COUNT" -eq 0 ]]; then
    echo "❌ No Android Virtual Devices found."
    echo "Create one using Android Studio > Device Manager."
    exit 1
  elif [[ "$AVD_COUNT" -eq 1 ]]; then
    AVD_NAME="${AVD_LIST[0]}"
    echo "✅ Using only available AVD: $AVD_NAME"
  else
    echo "Multiple AVDs found:"
    for i in "${!AVD_LIST[@]}"; do
      echo "$((i+1))) ${AVD_LIST[$i]}"
    done
    read -rp "Select AVD [1-$AVD_COUNT]: " AVD_INDEX
    
    if ! [[ "$AVD_INDEX" =~ ^[0-9]+$ ]] || (( AVD_INDEX < 1 || AVD_INDEX > AVD_COUNT )); then
      echo "Invalid selection"
      exit 1
    fi
    
    AVD_NAME="${AVD_LIST[$((AVD_INDEX-1))]}"
  fi
  
  # ---------- START EMULATOR ----------
  if adb devices | grep -q "emulator-"; then
    echo "Android emulator already running."
  else
    echo "Starting emulator: $AVD_NAME"
    emulator -avd "$AVD_NAME" -netdelay none -netspeed full &
    EMULATOR_PID=$!
    
    echo "Waiting for emulator to boot..."
    adb wait-for-device
    
    # Tunggu sampai boot selesai
    while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do
      echo "Still booting..."
      sleep 2
    done
    
    echo "✅ Emulator ready!"
  fi
  
  # Build dan run
  flutter build apk
  flutter run -d emulator-5554
fi

# ---------- CLEANUP ----------
trap "echo 'Stopping backend'; kill $BACKEND_PID 2>/dev/null || true; kill $EMULATOR_PID 2>/dev/null || true" EXIT