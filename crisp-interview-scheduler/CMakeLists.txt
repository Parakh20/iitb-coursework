cmake_minimum_required(VERSION 3.12)
project(CRISPPlatform VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(SQLite3 REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Threads REQUIRED)
find_package(PkgConfig REQUIRED)

# Try to find nlohmann_json
pkg_check_modules(NLOHMANN_JSON nlohmann_json)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Conditional include for nlohmann_json
if(NLOHMANN_JSON_FOUND)
    include_directories(${NLOHMANN_JSON_INCLUDE_DIRS})
    link_directories(${NLOHMANN_JSON_LIBRARY_DIRS})
else()
    message(STATUS "Using bundled nlohmann/json header")
endif()

# Source files
set(SOURCES
    src/main.cpp
    src/core/InterviewScheduler.cpp
    src/platform/web_server.cpp
    src/platform/database.cpp
)

# Create executable
add_executable(crisp_platform ${SOURCES})

# Link libraries
target_link_libraries(crisp_platform 
    SQLite::SQLite3
    OpenSSL::SSL
    OpenSSL::Crypto
    Threads::Threads
)

# Conditional linking for nlohmann_json
if(NLOHMANN_JSON_FOUND)
    target_link_libraries(crisp_platform ${NLOHMANN_JSON_LIBRARIES})
endif()

# Compiler flags
target_compile_options(crisp_platform PRIVATE
    -Wall -Wextra -O2 -std=c++17
)

# Copy web files to build directory
add_custom_target(copy_web_files ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/web ${CMAKE_BINARY_DIR}/web
    COMMENT "Copying web files"
)

add_dependencies(crisp_platform copy_web_files)

# Install target
install(TARGETS crisp_platform DESTINATION bin)
install(DIRECTORY web/ DESTINATION share/crisp-platform/web)
