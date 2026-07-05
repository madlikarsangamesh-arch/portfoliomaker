#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to the frontend directory if running from the project root
if [ ! -f "pubspec.yaml" ] && [ -d "frontend" ]; then
  echo "Moving to frontend directory..."
  cd frontend
fi


echo "=== System Diagnostics ==="
uname -a
echo "========================="

echo "=== Setting up Flutter SDK ==="
# Clone Flutter SDK stable branch if not cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK directory found. Pulling latest changes..."
  cd flutter
  git pull
  cd ..
fi

# Add Flutter bin directory to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Verifying Flutter installation ==="
flutter doctor -v

echo "=== Configuring Flutter for Web ==="
flutter config --enable-web

echo "=== Fetching Flutter packages ==="
flutter pub get

echo "=== Building Flutter Web app (Release Mode) ==="
flutter build web --release

echo "=== Flutter Web compilation finished successfully ==="
