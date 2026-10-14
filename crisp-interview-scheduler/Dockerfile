# Multi-stage build for optimal image size
FROM ubuntu:24.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    pkg-config \
    libsqlite3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    nlohmann-json3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build application
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc)

# Production stage
FROM ubuntu:24.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    libssl3 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -u 1000 crisp

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/build/crisp_platform /app/
COPY --from=builder /app/build/web /app/web

# Create data directory
RUN mkdir -p /app/data && chown crisp:crisp /app/data

# Switch to app user
USER crisp

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api || exit 1

# Run application
CMD ["./crisp_platform", "--port", "8080", "--db", "/app/data/crisp_platform.db"]
