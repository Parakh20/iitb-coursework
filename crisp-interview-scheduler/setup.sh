#!/bin/bash

set -e

echo "🎯 CRISP Platform - Complete Setup"
echo "=================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "🔧 Installing dependencies..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    pkg-config \
    libsqlite3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    nlohmann-json3-dev \
    libboost-all-dev \
    nodejs \
    npm

# Download required headers if not present
echo "📥 Downloading required headers..."
if [ ! -f "include/httplib.h" ]; then
    wget -O include/httplib.h https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
fi

# Build the platform
echo "🔨 Building platform..."
./scripts/build.sh

# Run tests
echo "🧪 Running tests..."
./scripts/test.sh

echo "✅ Setup completed successfully!"
echo
echo "🚀 To start the platform:"
echo "   cd build && ./crisp_platform"
echo
echo "🐳 To start with Docker:"
echo "   docker-compose up --build"
echo
echo "🌐 Access the platform at:"
echo "   http://localhost:8080"
