#!/bin/bash

set -e

echo "🚀 Building CRISP Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create necessary directories
print_status "Creating directories..."
mkdir -p build data logs

# Check for required tools
print_status "Checking prerequisites..."
for tool in cmake make g++; do
    if ! command -v $tool &> /dev/null; then
        print_error "$tool is not installed!"
        exit 1
    fi
done
print_success "All prerequisites found"

# Configure with CMake
print_status "Configuring build..."
cd build

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      ..

if [ $? -ne 0 ]; then
    print_error "CMake configuration failed!"
    exit 1
fi

print_success "Build configured successfully"

# Build the project
print_status "Compiling..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    print_error "Compilation failed!"
    exit 1
fi

print_success "Compilation completed successfully"

# Create systemd service file (optional)
print_status "Creating systemd service file..."
cat > ../scripts/crisp-platform.service << 'SERVICE_EOF'
[Unit]
Description=CRISP Platform - Campus Recruitment Interview Scheduling
After=network.target

[Service]
Type=simple
User=crisp
Group=crisp
WorkingDirectory=/opt/crisp-platform
ExecStart=/opt/crisp-platform/crisp_platform --port 8080 --db /opt/crisp-platform/data/crisp_platform.db
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

print_success "Build completed successfully!"
echo
echo "========================================="
echo "🎉 CRISP Platform Build Summary"
echo "========================================="
echo "Executable: build/crisp_platform"
echo "Web files: build/web/"
echo "Database: data/crisp_platform.db"
echo
echo "To run the platform:"
echo "  cd build && ./crisp_platform"
echo
echo "To install system-wide:"
echo "  sudo make install"
echo "========================================="
