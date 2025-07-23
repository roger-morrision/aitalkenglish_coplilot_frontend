FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
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
    libstdc++-12-dev \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK Command Line Tools
RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    cd /opt/android-sdk/cmdline-tools && \
    curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools.zip && \
    mv cmdline-tools latest && \
    rm commandlinetools.zip

# Set environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Install Flutter
RUN cd /home/vscode && \
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz | tar -xJ && \
    chown -R vscode:vscode /home/vscode/flutter

# Add Flutter to PATH
ENV PATH="/home/vscode/flutter/bin:$PATH"

# Switch to vscode user
USER vscode

# Accept Android licenses and configure Flutter
RUN yes | flutter doctor --android-licenses || true
RUN flutter config --android-sdk $ANDROID_SDK_ROOT

# Ensure proper permissions
USER root
RUN chown -R vscode:vscode /opt/android-sdk
USER vscode
