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

# ---------- FLUTTER CHECK ----------
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found."
  echo "Please install Flutter SDK first: https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo "Flutter found"

# ---------- PYTHON CHECK ----------
if command -v python3 &> /dev/null; then
  PYTHON=python3
elif command -v python &> /dev/null; then
  PYTHON=python
else
  echo "Python not found."
  echo "Please install Python at: https://www.python.org/downloads/"
  exit 1
fi

echo "Python found: $($PYTHON --version)"

# ---------- BACKEND SETUP ----------
echo "Setting up backend..."

cd backend

# Detect venv or conda
if [[ -d "venv" ]]; then
  echo "Using existing venv"
elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
  echo "Using Conda environment: $CONDA_DEFAULT_ENV"
else
  echo "Creating Python venv..."
  $PYTHON -m venv venv
fi

# Activate venv if exists
if [[ -d "venv" ]]; then
  source venv/bin/activate
fi

pip install --upgrade pip
pip install -r requirements.txt

echo "Starting FastAPI backend..."
uvicorn app:app --reload &

BACKEND_PID=$!
sleep 2

cd ..

# ---------- FRONTEND SETUP ----------
echo "Setting up Flutter frontend..."

cd frontend

flutter clean
flutter pub get

# Detect flutter device
DEVICE=""
if [[ "$HOST_OS" == "linux" ]]; then
  DEVICE="linux"
elif [[ "$HOST_OS" == "macos" ]]; then
  DEVICE="macos"
fi

echo "sing Flutter device: $DEVICE"

flutter build $DEVICE
flutter run -d $DEVICE

# ---------- CLEANUP ----------
trap "echo 'Stopping backend'; kill $BACKEND_PID" EXIT
