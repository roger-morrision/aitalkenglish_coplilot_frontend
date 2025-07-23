#!/bin/bash

# Update package list
sudo apt-get update

# Install required dependencies
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev

# Download and install Flutter
cd /home/vscode
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz | tar -xJ
sudo chown -R vscode:vscode /home/vscode/flutter

# Add Flutter to PATH
echo 'export PATH="/home/vscode/flutter/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="/home/vscode/flutter/bin:$PATH"' >> ~/.zshrc
export PATH="/home/vscode/flutter/bin:$PATH"

# Configure git (required for Flutter)
git config --global --add safe.directory /home/vscode/flutter

# Run flutter doctor and accept licenses
flutter doctor
echo "y" | flutter doctor --android-licenses || true

# Navigate to project directory and get dependencies
cd /workspaces/aitalk_copilot
flutter pub get

echo "Flutter development environment setup complete!"
