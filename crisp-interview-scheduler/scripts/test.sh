#!/bin/bash

set -e

echo "🧪 Testing CRISP Platform..."

# Build first if needed
if [ ! -f "build/crisp_platform" ]; then
    echo "Building platform first..."
    ./scripts/build.sh
fi

cd build

# Test 1: Basic functionality
echo "Test 1: Basic application startup..."
timeout 5s ./crisp_platform --help > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Application help works"
else
    echo "❌ Application help failed"
fi

# Test 2: API endpoint test
echo "Test 2: Starting server and testing API..."
./crisp_platform --port 8081 &
SERVER_PID=$!
sleep 3

# Test API endpoint
curl -s http://localhost:8081/api > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ API endpoint responds"
else
    echo "❌ API endpoint failed"
fi

# Test schedule generation
echo "Test 3: Testing schedule generation..."
curl -s -X POST http://localhost:8081/api/schedule/generate \
  -H "Content-Type: application/json" \
  -d '{
    "companies": [
      {"name": "TestCorp", "durationPerRound": 30, "numRounds": 2, "numPanels": 2}
    ],
    "students": [
      {"id": "TEST001", "shortlistedCompanies": ["TestCorp"]}
    ]
  }' > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Schedule generation works"
else
    echo "❌ Schedule generation failed"
fi

# Cleanup
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null

echo "🎉 Testing completed!"
